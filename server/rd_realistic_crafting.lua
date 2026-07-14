--==============================================================
-- RD Realistic Crafting server
-- Validates materials with original VORP inventory exports, removes/creates items safely.
--==============================================================
local Core = exports.vorp_core:GetCore()
local CraftBusy = {}
local CraftPending = {}
local SessionXp = {}
local AvatarFetchBusy = {}
local getLevelFromXp
local buildData

local function notify(src, msg, ms)
    ms = ms or 3500
    if Core and Core.NotifyRightTip then
        Core.NotifyRightTip(src, tostring(msg), ms)
    else
        print(('[RD Craft][%s] %s'):format(src, tostring(msg)))
    end
end

local function getCharKey(src)
    local ok, user = pcall(function() return Core.getUser(src) end)
    if ok and user and user.getUsedCharacter then
        local c = user.getUsedCharacter
        local charId = c.charIdentifier or c.charidentifier or c.CharIdentifier or c.charid or c.id
        local identifier = c.identifier or c.Identifier or ''
        return tostring(identifier) .. ':' .. tostring(charId or src)
    end
    return tostring(src)
end

local function rdTrim(value)
    value = tostring(value or '')
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function getUsedCharacterSafe(src)
    local ok, user = pcall(function() return Core.getUser(src) end)
    if ok and user and user.getUsedCharacter then
        return user.getUsedCharacter
    end
    return nil
end

local function getCharacterName(src)
    local c = getUsedCharacterSafe(src)
    if c then
        local first = rdTrim(c.firstname or c.firstName or c.Firstname or c.FirstName or c.name or '')
        local last = rdTrim(c.lastname or c.lastName or c.Lastname or c.LastName or '')
        local full = rdTrim((first .. ' ' .. last))
        if full ~= '' then return full end
        local nickname = rdTrim(c.charName or c.characterName or c.displayName or c.nickname or '')
        if nickname ~= '' then return nickname end
    end
    return GetPlayerName(src) or ('Player ' .. tostring(src))
end

local function getIdentifierByPrefix(src, prefix)
    prefix = tostring(prefix or ''):lower()
    if prefix == '' then return nil end
    local ids = GetPlayerIdentifiers(src) or {}
    for _, identifier in ipairs(ids) do
        local value = tostring(identifier or '')
        if value:sub(1, #prefix):lower() == prefix then
            return value
        end
    end
    return nil
end

local function hexToDecString(hex)
    hex = tostring(hex or ''):gsub('^0x', ''):gsub('[^0-9a-fA-F]', '')
    if hex == '' then return nil end
    local dec = '0'
    for i = 1, #hex do
        local digit = tonumber(hex:sub(i, i), 16) or 0
        local carry = digit
        local out = {}
        for j = #dec, 1, -1 do
            local n = (tonumber(dec:sub(j, j)) or 0) * 16 + carry
            out[#out + 1] = tostring(n % 10)
            carry = math.floor(n / 10)
        end
        while carry > 0 do
            out[#out + 1] = tostring(carry % 10)
            carry = math.floor(carry / 10)
        end
        local rev = {}
        for j = #out, 1, -1 do rev[#rev + 1] = out[j] end
        dec = table.concat(rev):gsub('^0+', '')
        if dec == '' then dec = '0' end
    end
    return dec
end

local function getSteamId64(src)
    local steam = getIdentifierByPrefix(src, 'steam:')
    if not steam then return nil, nil end
    local hex = steam:gsub('steam:', '')
    return hexToDecString(hex), hex
end

local function decodeXmlText(value)
    value = tostring(value or '')
    value = value:gsub('&amp;', '&'):gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&#39;', "'")
    return value
end

local function performHttpGet(url, headers)
    if type(PerformHttpRequest) ~= 'function' then return nil end
    local p = promise.new()
    local ok = pcall(function()
        PerformHttpRequest(url, function(status, body)
            p:resolve({ status = tonumber(status) or 0, body = body or '' })
        end, 'GET', '', headers or {})
    end)
    if not ok then return nil end
    local okAwait, result = pcall(function() return Citizen.Await(p) end)
    if not okAwait or type(result) ~= 'table' then return nil end
    if (tonumber(result.status) or 0) < 200 or (tonumber(result.status) or 0) >= 300 then return nil end
    return tostring(result.body or '')
end

local function fetchSteamAvatar(steamId64)
    steamId64 = tostring(steamId64 or '')
    if steamId64 == '' then return '' end

    local cfg = (Config.RDRealisticCrafting or {}).Profile or {}
    local apiKey = rdTrim(cfg.SteamApiKey or '')
    if apiKey == '' and type(GetConvar) == 'function' then
        apiKey = rdTrim(GetConvar('steam_webApiKey', '') or '')
    end

    if apiKey ~= '' then
        local body = performHttpGet(('https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s'):format(apiKey, steamId64), { ['Accept'] = 'application/json' })
        if body and body ~= '' then
            local ok, decoded = pcall(function() return json.decode(body) end)
            local players = ok and decoded and decoded.response and decoded.response.players or nil
            local p1 = type(players) == 'table' and players[1] or nil
            local avatar = p1 and (p1.avatarfull or p1.avatarmedium or p1.avatar) or nil
            if avatar and avatar ~= '' then return tostring(avatar) end
        end
    end

    local xml = performHttpGet(('https://steamcommunity.com/profiles/%s?xml=1'):format(steamId64), { ['Accept'] = 'application/xml,text/xml,text/html' })
    if xml and xml ~= '' then
        local avatar = xml:match('<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>') or xml:match('<avatarFull>(.-)</avatarFull>')
        avatar = decodeXmlText(avatar or '')
        if avatar ~= '' then return avatar end
    end

    return ''
end

local function queueSteamAvatarFetch(src, steamId64, cacheKey)
    steamId64 = tostring(steamId64 or '')
    if steamId64 == '' or AvatarFetchBusy[steamId64] then return end
    AvatarFetchBusy[steamId64] = true

    CreateThread(function()
        local okFetch, avatar = pcall(function() return fetchSteamAvatar(steamId64) end)
        if not okFetch then avatar = '' end
        avatar = avatar or ''
        pcall(function() SetResourceKvp(cacheKey, json.encode({ avatar = avatar, time = os.time() })) end)
        AvatarFetchBusy[steamId64] = nil

        -- If the craft UI is open, refresh it after the avatar arrives.
        if avatar ~= '' and buildData and GetPlayerName(src) then
            local ok, data = pcall(function() return buildData(src) end)
            if ok and data then
                TriggerClientEvent('rd_inventory:realCraft:updateData', src, data)
            end
        end
    end)
end

local function getSteamAvatarCached(src)
    local cfg = (Config.RDRealisticCrafting or {}).Profile or {}
    if cfg.ShowSteamAvatar == false then return '', nil, nil end

    local steamId64, steamHex = getSteamId64(src)
    if not steamId64 or steamId64 == '' then return '', nil, steamHex end

    local ttl = tonumber(cfg.AvatarCacheSeconds) or 21600
    local cacheKey = ('rd_realcraft_steam_avatar:%s'):format(steamId64)
    local now = os.time()
    local raw = nil
    pcall(function() raw = GetResourceKvpString(cacheKey) end)
    if raw and raw ~= '' then
        local ok, decoded = pcall(function() return json.decode(raw) end)
        if ok and type(decoded) == 'table' then
            local cachedAt = tonumber(decoded.time) or 0
            local avatar = tostring(decoded.avatar or '')
            if cachedAt > 0 and (ttl <= 0 or (now - cachedAt) < ttl) then
                return avatar, steamId64, steamHex
            end
        end
    end

    queueSteamAvatarFetch(src, steamId64, cacheKey)
    return '', steamId64, steamHex
end

local function getPlayerProfile(src)
    local charName = getCharacterName(src)
    local steamName = GetPlayerName(src) or charName
    local avatar, steamId64, steamHex = getSteamAvatarCached(src)
    return {
        charName = charName,
        name = charName,
        steamName = steamName,
        avatar = avatar or '',
        steamAvatar = avatar or '',
        steamId64 = steamId64 or '',
        steamHex = steamHex or '',
    }
end

local function kvpKey(src)
    return ('rd_realcraft_xp:%s'):format(getCharKey(src))
end

local function getXp(src)
    local key = kvpKey(src)
    local val = nil
    local ok = pcall(function()
        val = GetResourceKvpString(key)
    end)
    if ok and val then
        return tonumber(val) or 0
    end
    return tonumber(SessionXp[key] or 0) or 0
end

local function getLeaderboard()
    local raw = nil
    pcall(function() raw = GetResourceKvpString('rd_realcraft_leaderboard') end)
    local board = {}
    if raw and raw ~= '' then
        local ok, decoded = pcall(function() return json.decode(raw) end)
        if ok and type(decoded) == 'table' then board = decoded end
    end
    local list = {}
    for _, entry in pairs(board) do
        if type(entry) == 'table' then
            local xp = tonumber(entry.xp) or 0
            local charName = tostring(entry.charName or entry.characterName or entry.name or 'Player')
            local steamName = tostring(entry.steamName or entry.steam or '')
            list[#list + 1] = {
                name = charName,
                charName = charName,
                characterName = charName,
                steamName = steamName,
                avatar = tostring(entry.avatar or entry.steamAvatar or ''),
                steamAvatar = tostring(entry.avatar or entry.steamAvatar or ''),
                xp = xp,
                level = getLevelFromXp(xp),
                last = tonumber(entry.last) or 0,
            }
        end
    end
    table.sort(list, function(a, b)
        if a.level == b.level then return a.xp > b.xp end
        return a.level > b.level
    end)
    local top = {}
    for i = 1, math.min(10, #list) do top[i] = list[i] end
    return top
end

local function updateLeaderboard(src, xp, profile)
    local raw = nil
    pcall(function() raw = GetResourceKvpString('rd_realcraft_leaderboard') end)
    local board = {}
    if raw and raw ~= '' then
        local ok, decoded = pcall(function() return json.decode(raw) end)
        if ok and type(decoded) == 'table' then board = decoded end
    end
    profile = profile or getPlayerProfile(src)
    local key = kvpKey(src)
    board[key] = {
        name = tostring(profile.charName or profile.name or GetPlayerName(src) or ('Player ' .. tostring(src))),
        charName = tostring(profile.charName or profile.name or GetPlayerName(src) or ('Player ' .. tostring(src))),
        steamName = tostring(profile.steamName or GetPlayerName(src) or ''),
        avatar = tostring(profile.avatar or profile.steamAvatar or ''),
        steamAvatar = tostring(profile.avatar or profile.steamAvatar or ''),
        steamId64 = tostring(profile.steamId64 or ''),
        steamHex = tostring(profile.steamHex or ''),
        xp = tonumber(xp) or 0,
        last = os.time(),
    }
    pcall(function() SetResourceKvp('rd_realcraft_leaderboard', json.encode(board)) end)
end

local function setXp(src, xp)
    xp = math.max(0, tonumber(xp) or 0)
    local key = kvpKey(src)
    SessionXp[key] = xp
    pcall(function()
        SetResourceKvp(key, tostring(xp))
    end)
    updateLeaderboard(src, xp)
end

local function xpNeededForLevel(level)
    local cfg = Config.RDRealisticCrafting or {}
    local base = tonumber(cfg.XpPerLevel) or 250
    local maxStep = tonumber(cfg.XpLevelMaxStep) or 3500
    level = math.max(1, tonumber(level) or 1)

    if cfg.ProgressiveLeveling == false then
        return base
    end

    local multiplier = tonumber(cfg.XpLevelMultiplier) or 1.10
    if multiplier < 1.0 then multiplier = 1.0 end

    local step = math.floor((base * (multiplier ^ (level - 1))) + 0.5)
    if step < base then step = base end
    if maxStep > 0 and step > maxStep then step = maxStep end
    return step
end

local function totalXpForLevel(level)
    local maxLevel = tonumber((Config.RDRealisticCrafting or {}).MaxLevel) or 1000
    level = math.max(1, math.min(maxLevel, tonumber(level) or 1))
    local total = 0
    for l = 1, level - 1 do
        total = total + xpNeededForLevel(l)
    end
    return total
end

function getLevelFromXp(xp)
    local cfg = Config.RDRealisticCrafting or {}
    local maxLevel = tonumber(cfg.MaxLevel) or 1000
    local remaining = math.max(0, tonumber(xp) or 0)
    local lvl = 1

    while lvl < maxLevel do
        local need = xpNeededForLevel(lvl)
        if remaining < need then break end
        remaining = remaining - need
        lvl = lvl + 1
    end

    return lvl
end

local function getXpProgress(xp)
    xp = math.max(0, tonumber(xp) or 0)
    local level = getLevelFromXp(xp)
    local currentStart = totalXpForLevel(level)
    local nextNeed = xpNeededForLevel(level)
    local nextLevelXp = currentStart + nextNeed
    return level, math.max(0, xp - currentStart), nextNeed, nextLevelXp
end

local function getInvExport()
    local res = GetCurrentResourceName()
    if exports and exports[res] then return exports[res] end
    return nil
end

local function getItemCount(src, item)
    item = tostring(item or '')
    if item == '' then return 0 end
    local inv = getInvExport()
    if inv and inv.getItemCount then
        local ok, count = pcall(function()
            return inv:getItemCount(src, nil, item, nil)
        end)
        if ok then return tonumber(count) or 0 end
    end

    local p = promise.new()
    TriggerEvent('vorpCore:getItemCount', src, function(count)
        p:resolve(tonumber(count) or 0)
    end, item, nil)
    local ok, result = pcall(function() return Citizen.Await(p) end)
    return ok and (tonumber(result) or 0) or 0
end

local function canCarryItem(src, item, amount)
    local inv = getInvExport()
    if inv and inv.canCarryItem then
        local ok, result = pcall(function()
            return inv:canCarryItem(src, tostring(item), tonumber(amount) or 1)
        end)
        if ok and result ~= nil then return result and true or false end
    end
    local p = promise.new()
    TriggerEvent('vorpCore:canCarryItem', src, tostring(item), tonumber(amount) or 1, function(res)
        p:resolve(res and true or false)
    end)
    local ok, result = pcall(function() return Citizen.Await(p) end)
    if not ok then return true end
    return result and true or false
end

local function addItem(src, item, amount)
    local inv = getInvExport()
    if inv and inv.addItem then
        local ok, result = pcall(function()
            return inv:addItem(src, tostring(item), tonumber(amount) or 1, nil)
        end)
        if ok then return result and true or false end
    end
    local p = promise.new()
    TriggerEvent('vorpCore:addItem', src, tostring(item), tonumber(amount) or 1, nil, function(res)
        p:resolve(res and true or false)
    end)
    local ok, result = pcall(function() return Citizen.Await(p) end)
    return ok and (result and true or false) or false
end

local function subItem(src, item, amount)
    local inv = getInvExport()
    if inv and inv.subItem then
        local ok, result = pcall(function()
            return inv:subItem(src, tostring(item), tonumber(amount) or 1, nil)
        end)
        if ok then return result and true or false end
    end
    local p = promise.new()
    TriggerEvent('vorpCore:subItem', src, tostring(item), tonumber(amount) or 1, nil, function(res)
        p:resolve(res and true or false)
    end)
    local ok, result = pcall(function() return Citizen.Await(p) end)
    return ok and (result and true or false) or false
end

local function refundRemovedItems(src, removed, reason)
    local refunded = false
    if type(removed) ~= 'table' then return false end
    for _, r in ipairs(removed) do
        if type(r) == 'table' and r.item and (tonumber(r.amount) or 0) > 0 then
            addItem(src, r.item, tonumber(r.amount) or 1)
            refunded = true
        end
    end
    if refunded and reason then
        notify(src, reason, 3000)
    end
    return refunded
end


local function isWeaponName(name)
    name = tostring(name or ''):upper()
    if name:sub(1, 7) == 'WEAPON_' then return true end
    return SharedData and SharedData.Weapons and SharedData.Weapons[name] ~= nil
end

local function canCarryWeapon(src, weaponName, amount)
    amount = tonumber(amount) or 1
    local inv = getInvExport()
    if inv and inv.canCarryWeapons then
        local p = promise.new()
        local ok = pcall(function()
            inv:canCarryWeapons(src, amount, function(res) p:resolve(res and true or false) end, tostring(weaponName):upper())
        end)
        if ok then
            local okAwait, result = pcall(function() return Citizen.Await(p) end)
            if okAwait and result ~= nil then return result and true or false end
        end
    end
    local p = promise.new()
    TriggerEvent('vorpCore:canCarryWeapons', src, amount, function(res)
        p:resolve(res and true or false)
    end, tostring(weaponName):upper())
    local ok, result = pcall(function() return Citizen.Await(p) end)
    if not ok then return true end
    return result and true or false
end

local function createWeaponReward(src, weaponName, amount, label)
    local inv = getInvExport()
    local name = tostring(weaponName or ''):upper()
    amount = tonumber(amount) or 1
    for _ = 1, amount do
        local ok = false
        if inv and inv.createWeapon then
            local okCall, result = pcall(function()
                return inv:createWeapon(src, name, {}, {}, {}, nil, label or nil, 'Crafted at gunsmith table')
            end)
            ok = okCall and result ~= false
        end
        if not ok then
            local p = promise.new()
            TriggerEvent('vorpCore:registerWeapon', src, name, {}, {}, {}, function(res)
                p:resolve(res and true or false)
            end, nil, nil, label or nil, 'Crafted at gunsmith table')
            local okAwait, result = pcall(function() return Citizen.Await(p) end)
            ok = okAwait and (result and true or false)
        end
        if not ok then return false end
    end
    return true
end

local function cloneTable(t)
    local out = {}
    if type(t) ~= 'table' then return out end
    for k, v in pairs(t) do
        if type(v) == 'table' then out[k] = cloneTable(v) else out[k] = v end
    end
    return out
end

local function getWeaponKind(weaponName)
    local n = tostring(weaponName or ''):upper()
    if n:find('PISTOL', 1, true) then return 'pistol' end
    if n:find('REVOLVER', 1, true) then return 'revolver' end
    if n:find('REPEATER', 1, true) then return 'repeater' end
    if n:find('SNIPER', 1, true) then return 'sniper' end
    if n:find('RIFLE', 1, true) then return 'rifle' end
    if n:find('SHOTGUN', 1, true) then return 'shotgun' end
    if n:find('BOW', 1, true) then return 'bow' end
    if n:find('THROWN', 1, true) or n:find('BOLAS', 1, true) then return 'thrown' end
    if n:find('KIT_', 1, true) or n:find('CAMERA', 1, true) or n:find('BINOCULAR', 1, true) then return 'kit' end
    if n:find('MELEE', 1, true) or n:find('LASSO', 1, true) or n:find('FISHINGROD', 1, true) then return 'melee' end
    return 'default'
end

local function shouldHideWeaponRecipe(weaponName)
    local wc = (Config.RDRealisticCrafting or {}).WeaponCraft or {}
    if wc.HideUnsafe == false then return false end
    local n = tostring(weaponName or ''):upper()
    return n:find('DYNAMITE', 1, true) or n:find('MOLOTOV', 1, true) or n:find('POISON', 1, true)
end

local function normalizeSubcategoryId(label, fallback)
    local id = tostring(label or fallback or 'default'):lower()
    id = id:gsub('&', 'and'):gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if id == '' then id = tostring(fallback or 'default') end
    if id == 'bow' then id = 'bows' end
    if id == 'rifle' then id = 'rifles' end
    if id == 'repeater' then id = 'repeaters' end
    if id == 'pistol' then id = 'pistols' end
    if id == 'revolver' then id = 'revolvers' end
    if id == 'shotgun' then id = 'shotguns' end
    if id == 'throwables' or id == 'throwable_weapons' then id = 'throwable' end
    return id
end

local function xpRequirementToLevel(expreq)
    return getLevelFromXp(tonumber(expreq) or 0)
end

local function getConfiguredCraftTime(data)
    local cfg = Config.RDRealisticCrafting or {}
    local minTime = tonumber(cfg.CraftDuration) or 30000
    local raw = tonumber(data and (data.craftTime or data.time or data.diff)) or minTime
    if raw < minTime then raw = minTime end
    return raw
end

local function xpAddFromData(data, defaultXp)
    local v = tonumber(data and (data.xp or data.expadd)) or tonumber(defaultXp) or 25
    if v <= 12 then v = v * 25 end
    if v < 25 then v = 25 end
    return math.floor(v)
end

local function getRecipeXp(recipe)
    local cfg = Config.RDRealisticCrafting or {}
    recipe = recipe or {}
    local category = tostring(recipe.category or recipe.group or recipe.type or '')
    local categoryDefaults = cfg.CategoryXpReward or {}
    local xp = tonumber(recipe.xp) or tonumber(categoryDefaults[category]) or tonumber(cfg.XpPerCraft) or 15
    local minXp = tonumber(cfg.MinXpReward) or 1
    if xp < minXp then xp = minXp end
    return math.floor(xp)
end

local function materialsToNeeded(materials)
    local needed, labels = {}, {}
    if type(materials) ~= 'table' then return needed, labels end
    for _, m in pairs(materials) do
        if type(m) == 'table' and m.name then
            local name = tostring(m.name)
            local amount = tonumber(m.amount) or 1
            if name ~= '' and amount > 0 then
                needed[name] = (tonumber(needed[name]) or 0) + amount
                labels[name] = tostring(m.label or m.Label or m.name)
            end
        end
    end
    return needed, labels
end

local function generateCustomWeaponRecipes()
    local cfg = Config.RDRealisticCrafting or {}
    local wc = cfg.WeaponCraft or {}
    if wc.Enabled == false or wc.UseCustomConfig == false then return {} end
    if not Config4 or type(Config4.weapons) ~= 'table' then return {} end

    local recipes = {}
    local groups = {}
    for groupName, _ in pairs(Config4.weapons) do groups[#groups + 1] = tostring(groupName) end
    table.sort(groups)

    for _, groupName in ipairs(groups) do
        local group = Config4.weapons[groupName]
        local sub = normalizeSubcategoryId(groupName, 'weapons')
        local names = {}
        if type(group) == 'table' then
            for recipeName, _ in pairs(group) do names[#names + 1] = tostring(recipeName) end
        end
        table.sort(names)
        for _, recipeName in ipairs(names) do
            local data = group[recipeName]
            if type(data) == 'table' and data.letcraft ~= false and data.hashname then
                local needed, labels = materialsToNeeded(data.materials)
                recipes[#recipes + 1] = {
                    label = recipeName,
                    desc = ('Gunsmith table • %s. Vendos materialet në slots poshtë, pastaj craft.'):format(groupName),
                    animation = 'gun',
                    category = 'weapons',
                    subcategory = sub,
                    subcategoryLabel = groupName,
                    level = xpRequirementToLevel(data.expreq),
                    needed = needed,
                    neededLabels = labels,
                    reward = { [tostring(data.hashname):upper()] = 1 },
                    rewardLabel = recipeName,
                    xp = xpAddFromData(data, wc.Xp or 100),
                    craftTime = getConfiguredCraftTime(data),
                    isWeapon = true,
                    weaponName = tostring(data.hashname):upper(),
                    jobonly = data.jobonly == true,
                    jobs = data.jobs,
                }
            end
        end
    end
    return recipes
end

local function generateCustomAmmoRecipes()
    local cfg = Config.RDRealisticCrafting or {}
    local wc = cfg.WeaponCraft or {}
    if wc.Enabled == false or wc.UseCustomConfig == false then return {} end
    if not Config3 or type(Config3.ammo) ~= 'table' then return {} end

    local recipes = {}
    local groups = {}
    for groupName, _ in pairs(Config3.ammo) do groups[#groups + 1] = tostring(groupName) end
    table.sort(groups)

    for _, groupName in ipairs(groups) do
        local group = Config3.ammo[groupName]
        local names = {}
        if type(group) == 'table' then
            for recipeName, _ in pairs(group) do names[#names + 1] = tostring(recipeName) end
        end
        table.sort(names)
        for _, recipeName in ipairs(names) do
            local data = group[recipeName]
            if type(data) == 'table' and data.letcraft ~= false and data.item then
                local needed, labels = materialsToNeeded(data.materials)
                local itemName = tostring(data.item)
                local qt = tonumber(data.qt) or 1
                recipes[#recipes + 1] = {
                    label = recipeName,
                    desc = ('Ammo craft • %s • Box %s. Vendos materialet në slots poshtë, pastaj craft.'):format(groupName, tostring(qt)),
                    animation = 'gun',
                    category = 'weapons',
                    subcategory = 'ammo',
                    subcategoryLabel = 'Ammo',
                    ammoGroup = groupName,
                    level = xpRequirementToLevel(data.expreq),
                    needed = needed,
                    neededLabels = labels,
                    reward = { [itemName] = 1 },
                    rewardLabel = recipeName,
                    xp = xpAddFromData(data, wc.Xp or 80),
                    craftTime = getConfiguredCraftTime(data),
                    isAmmo = true,
                    ammoKey = tostring(data.key or ''),
                    ammoQuantity = qt,
                    jobonly = data.jobonly == true,
                    jobs = data.jobs,
                }
            end
        end
    end
    return recipes
end

local function generateSharedWeaponRecipesFallback()
    local cfg = Config.RDRealisticCrafting or {}
    local wc = cfg.WeaponCraft or {}
    if wc.Enabled == false or wc.IncludeAllSharedWeapons == false then return {} end
    local weapons = (SharedData and SharedData.Weapons) or {}
    local names = {}
    for weaponName, _ in pairs(weapons) do
        if not shouldHideWeaponRecipe(weaponName) then names[#names + 1] = tostring(weaponName):upper() end
    end
    table.sort(names)
    local recipes = {}
    local mats = wc.Materials or {}
    local startLevel = tonumber(wc.StartLevel) or 1
    local step = tonumber(wc.LevelStep) or 18
    local maxWeaponLevel = tonumber(wc.MaxWeaponLevel) or tonumber(cfg.MaxLevel) or 1000
    for i, weaponName in ipairs(names) do
        local data = weapons[weaponName] or {}
        local kind = getWeaponKind(weaponName)
        local needed = cloneTable(mats[kind] or mats.default or { iron = 4, wood = 2 })
        local lvl = math.min(maxWeaponLevel, startLevel + ((i - 1) * step))
        recipes[#recipes + 1] = {
            label = data.Name or weaponName,
            desc = 'Weapon craft / Gunsmith table. Vendos materialet në slots poshtë, pastaj craft arma.',
            animation = 'gun',
            category = 'weapons',
            subcategory = normalizeSubcategoryId(kind, 'weapons'),
            level = lvl,
            needed = needed,
            reward = { [weaponName] = 1 },
            xp = tonumber(wc.Xp) or 120,
            craftTime = tonumber(wc.CraftTime) or 30000,
            isWeapon = true,
            weaponName = weaponName,
        }
    end
    return recipes
end

local function generateWeaponRecipes()
    local recipes = {}
    for _, recipe in ipairs(generateCustomAmmoRecipes()) do recipes[#recipes + 1] = recipe end
    for _, recipe in ipairs(generateCustomWeaponRecipes()) do recipes[#recipes + 1] = recipe end
    if #recipes == 0 then
        for _, recipe in ipairs(generateSharedWeaponRecipesFallback()) do recipes[#recipes + 1] = recipe end
    end
    return recipes
end


local function getAllRecipes()
    local cfg = Config.RDRealisticCrafting or {}
    local all = {}
    for _, recipe in ipairs(cfg.Recipes or {}) do all[#all + 1] = recipe end
    for _, recipe in ipairs(generateWeaponRecipes()) do all[#all + 1] = recipe end
    return all
end

local function firstReward(recipe)
    if type(recipe.reward) ~= 'table' then return nil, 0 end
    for name, amount in pairs(recipe.reward) do
        return tostring(name), tonumber(amount) or 0
    end
    return nil, 0
end

local function getCampfireRuntimeConfig()
    local cfg = (Config.RDRealisticCrafting or {}).CampfireRuntime or {}
    local items = cfg.FuelItems
    if type(items) ~= 'table' or #items == 0 then
        items = { { name = 'wood', label = 'Wood' }, { name = 'hwood', label = 'Hard Wood' } }
    end
    return cfg, items
end

local function isCampfireFuelItem(itemName)
    itemName = tostring(itemName or '')
    local _, items = getCampfireRuntimeConfig()
    for _, item in ipairs(items) do
        if tostring(item.name or '') == itemName then
            return true, tostring(item.label or item.name or itemName)
        end
    end
    return false, itemName
end

local function buildCampfireData(src, counts)
    local cfg, items = getCampfireRuntimeConfig()
    local out = {
        enabled = cfg.Enabled ~= false,
        initialSeconds = tonumber(cfg.InitialSeconds) or 300,
        fuelSecondsPerItem = tonumber(cfg.FuelSecondsPerItem) or 300,
        maxDistance = tonumber(cfg.MaxDistance) or 3.2,
        items = {},
    }
    counts = counts or {}
    for _, item in ipairs(items) do
        local name = tostring(item.name or '')
        if name ~= '' then
            local count = counts[name]
            if count == nil then
                count = getItemCount(src, name)
                counts[name] = count
            end
            out.items[#out.items + 1] = { name = name, label = tostring(item.label or name), count = tonumber(count) or 0 }
        end
    end
    return out
end

local function normalizeRecipe(recipe, index, src, counts, level)
    recipe = recipe or {}
    local needed = recipe.needed or recipe.NEEDED or {}
    local reward = recipe.reward or recipe.REWARD or {}
    local missing = {}
    local can = true

    for item, amount in pairs(needed) do
        local need = tonumber(amount) or 0
        local have = counts[item]
        if have == nil then
            have = getItemCount(src, item)
            counts[item] = have
        end
        if have < need then
            can = false
            missing[#missing + 1] = { name = tostring(item), have = have, need = need }
        end
    end

    local reqLevel = tonumber(recipe.level or recipe.LEVEL) or 1
    if level < reqLevel then can = false end

    local outReward = {}
    for item, amount in pairs(reward) do
        outReward[tostring(item)] = tonumber(amount) or 0
    end

    local outNeeded = {}
    for item, amount in pairs(needed) do
        outNeeded[tostring(item)] = tonumber(amount) or 0
    end

    local outNeededLabels = {}
    if type(recipe.neededLabels) == 'table' then
        for item, label in pairs(recipe.neededLabels) do
            outNeededLabels[tostring(item)] = tostring(label)
        end
    end

    local rewardName, rewardAmount = firstReward({ reward = outReward })

    return {
        index = index - 1,
        label = recipe.label or recipe.LABEL or recipe.name or ('Recipe ' .. tostring(index)),
        desc = recipe.desc or recipe.DESC or '',
        level = reqLevel,
        craftTime = tonumber(recipe.craftTime or recipe.time) or tonumber((Config.RDRealisticCrafting or {}).CraftDuration) or 30000,
        xp = getRecipeXp(recipe),
        animation = tostring(recipe.animation or recipe.anim or recipe.craftAnim or recipe.category or recipe.type or ''),
        category = tostring(recipe.category or recipe.group or recipe.type or 'survival'),
        subcategory = tostring(recipe.subcategory or recipe.weaponCategory or recipe.ammoGroup or ''),
        subcategoryLabel = tostring(recipe.subcategoryLabel or recipe.weaponCategoryLabel or recipe.ammoGroup or ''),
        needed = outNeeded,
        neededLabels = outNeededLabels,
        reward = outReward,
        rewardName = rewardName,
        rewardAmount = rewardAmount,
        rewardLabel = tostring(recipe.rewardLabel or recipe.label or rewardName or ''),
        ammoGroup = tostring(recipe.ammoGroup or ''),
        ammoQuantity = tonumber(recipe.ammoQuantity) or nil,
        isAmmo = recipe.isAmmo == true,
        isWeapon = recipe.isWeapon == true or (rewardName and isWeaponName(rewardName)) or false,
        weaponName = tostring(recipe.weaponName or rewardName or ''),
        canCraft = can,
        missing = missing,
    }
end

function buildData(src)
    local cfg = Config.RDRealisticCrafting or {}
    local xp = getXp(src)
    local profile = getPlayerProfile(src)
    updateLeaderboard(src, xp, profile)
    local level, xpIntoLevel, xpForNext, nextLevelXp = getXpProgress(xp)
    local counts = {}
    local recipes = {}

    local allRecipes = {}
    for _, recipe in ipairs(cfg.Recipes or {}) do allRecipes[#allRecipes + 1] = recipe end
    for _, recipe in ipairs(generateWeaponRecipes()) do allRecipes[#allRecipes + 1] = recipe end

    for i, recipe in ipairs(allRecipes) do
        recipes[#recipes + 1] = normalizeRecipe(recipe, i, src, counts, level)
    end

    return {
        level = level,
        xp = xp,
        xpIntoLevel = xpIntoLevel,
        xpForNext = xpForNext,
        nextLevelXp = nextLevelXp,
        profile = profile,
        categories = cfg.Categories or {},
        craftSubcategories = cfg.CraftSubcategories or {},
        weaponSubcategories = cfg.WeaponSubcategories or {},
        counts = counts,
        campfire = buildCampfireData(src, counts),
        recipes = recipes,
        leaderboard = getLeaderboard(),
    }
end

RegisterNetEvent('rd_inventory:realCraft:requestData', function(refreshOnly)
    local src = source
    if not Config.RDRealisticCrafting or Config.RDRealisticCrafting.Enabled == false then
        TriggerClientEvent('rd_inventory:realCraft:openData', src, { level = 1, xp = 0, recipes = {}, counts = {} })
        return
    end
    local data = buildData(src)
    if refreshOnly then
        TriggerClientEvent('rd_inventory:realCraft:updateData', src, data)
    else
        TriggerClientEvent('rd_inventory:realCraft:openData', src, data)
    end
end)

RegisterNetEvent('rd_inventory:realCraft:campfireStartFuel', function(itemName)
    local src = source
    local cfg = (Config.RDRealisticCrafting or {}).CampfireRuntime or {}
    if cfg.Enabled == false then
        TriggerClientEvent('rd_inventory:realCraft:campfireStartFailed', src, 'Campfire është i çaktivizuar.', buildData(src))
        return
    end

    itemName = tostring(itemName or '')
    local allowed, label = isCampfireFuelItem(itemName)
    if not allowed then
        TriggerClientEvent('rd_inventory:realCraft:campfireStartFailed', src, 'Duhet wood ose hwood për të ndezur campfire.', buildData(src))
        return
    end

    if getItemCount(src, itemName) < 1 then
        TriggerClientEvent('rd_inventory:realCraft:campfireStartFailed', src, ('Nuk ke %s në inventory.'):format(label), buildData(src))
        return
    end

    local ok = subItem(src, itemName, 1)
    if not ok then
        TriggerClientEvent('rd_inventory:realCraft:campfireStartFailed', src, 'Nuk u hoq materiali nga inventory.', buildData(src))
        return
    end

    TriggerClientEvent('rd_inventory:realCraft:campfireStartApproved', src, itemName, buildData(src))
end)

RegisterNetEvent('rd_inventory:realCraft:campfireAddFuel', function(itemName, amount)
    local src = source
    local cfg = (Config.RDRealisticCrafting or {}).CampfireRuntime or {}
    if cfg.Enabled == false then
        TriggerClientEvent('rd_inventory:realCraft:campfireFuelFailed', src, 'Campfire është i çaktivizuar.', buildData(src))
        return
    end

    itemName = tostring(itemName or '')
    amount = math.max(1, math.min(5, math.floor(tonumber(amount) or 1)))
    local allowed, label = isCampfireFuelItem(itemName)
    if not allowed then
        TriggerClientEvent('rd_inventory:realCraft:campfireFuelFailed', src, 'Ky item nuk mund të përdoret si dru.', buildData(src))
        return
    end

    if getItemCount(src, itemName) < amount then
        TriggerClientEvent('rd_inventory:realCraft:campfireFuelFailed', src, ('Nuk ke %s në inventory.'):format(label), buildData(src))
        return
    end

    local ok = subItem(src, itemName, amount)
    if not ok then
        TriggerClientEvent('rd_inventory:realCraft:campfireFuelFailed', src, 'Nuk u hoq materiali nga inventory.', buildData(src))
        return
    end

    local seconds = (tonumber(cfg.FuelSecondsPerItem) or 300) * amount
    TriggerClientEvent('rd_inventory:realCraft:campfireFuelAdded', src, itemName, amount, seconds, buildData(src))
end)

RegisterNetEvent('rd_inventory:realCraft:prepare', function(recipeIndex)
    local src = source
    local idx = (tonumber(recipeIndex) or -1) + 1
    local recipe = Config.RDRealisticCrafting and getAllRecipes()[idx]
    if not recipe then
        TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, 'Recipe nuk ekziston.', buildData(src))
        return
    end

    -- Reserve/remove materials at craft start. If the player cancels, disconnects,
    -- or the reward fails, the removed materials are refunded by refundRemovedItems().
    local xp = getXp(src)
    local level = getLevelFromXp(xp)
    local requiredLevel = tonumber(recipe.level or recipe.LEVEL) or 1
    if level < requiredLevel then
        TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, ('Duhet level %s për këtë recipe.'):format(requiredLevel), buildData(src))
        return
    end

    local needed = recipe.needed or recipe.NEEDED or {}
    local reward = recipe.reward or recipe.REWARD or {}

    for item, amount in pairs(needed) do
        local need = tonumber(amount) or 0
        if need > 0 and getItemCount(src, item) < need then
            TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, 'Nuk ke materialet e duhura.', buildData(src))
            return
        end
    end

    for item, amount in pairs(reward) do
        local give = tonumber(amount) or 0
        if give > 0 then
            if isWeaponName(item) then
                if not canCarryWeapon(src, item, give) then
                    TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, 'Nuk mban dot më shumë armë.', buildData(src))
                    return
                end
            elseif not canCarryItem(src, item, give) then
                TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, 'Inventory është full për reward.', buildData(src))
                return
            end
        end
    end

    local removed = {}
    for item, amount in pairs(needed) do
        local need = tonumber(amount) or 0
        if need > 0 then
            local ok = subItem(src, item, need)
            if not ok then
                refundRemovedItems(src, removed)
                TriggerClientEvent('rd_inventory:realCraft:prepareFailed', src, 'Nuk u hoqën materialet. Craft u anulua.', buildData(src))
                return
            end
            removed[#removed + 1] = { item = item, amount = need }
        end
    end

    CraftPending[src] = {
        index = idx,
        started = GetGameTimer(),
        minMs = math.max(1500, (tonumber(recipe.craftTime or recipe.time) or tonumber((Config.RDRealisticCrafting or {}).CraftDuration) or 5200) - 900),
        removed = removed,
        recipeLabel = tostring(recipe.label or 'item'),
    }
    TriggerClientEvent('rd_inventory:realCraft:prepared', src, buildData(src))
end)

RegisterNetEvent('rd_inventory:realCraft:cancel', function()
    local src = source
    local pending = CraftPending[src]
    if pending and type(pending.removed) == 'table' and #pending.removed > 0 then
        refundRemovedItems(src, pending.removed, 'Craft u anulua. Materialet u kthyen.')
    end
    CraftPending[src] = nil
end)

RegisterNetEvent('rd_inventory:realCraft:execute', function(recipeIndex)
    local src = source
    if CraftBusy[src] then return end
    CraftBusy[src] = true

    local function finish(ok, message)
        local data = buildData(src)
        TriggerClientEvent('rd_inventory:realCraft:result', src, ok, message, data)
        CraftBusy[src] = nil
    end

    if not Config.RDRealisticCrafting or Config.RDRealisticCrafting.Enabled == false then
        finish(false, 'Craft është i çaktivizuar.')
        return
    end

    local idx = (tonumber(recipeIndex) or -1) + 1
    local recipe = getAllRecipes()[idx]
    if not recipe then
        finish(false, 'Recipe nuk ekziston.')
        return
    end

    local pending = CraftPending[src]
    CraftPending[src] = nil
    if not pending or pending.index ~= idx or (GetGameTimer() - pending.started) < pending.minMs then
        if pending and pending.removed then
            refundRemovedItems(src, pending.removed, 'Craft u anulua. Materialet u kthyen.')
        end
        finish(false, 'Craft u anulua.')
        return
    end

    local xp = getXp(src)
    local reward = recipe.reward or recipe.REWARD or {}
    local removed = pending.removed or {}

    -- Materials were already reserved in prepare(). Re-check carry before reward in case inventory changed during animation.
    for item, amount in pairs(reward) do
        local give = tonumber(amount) or 0
        if give > 0 then
            if isWeaponName(item) then
                if not canCarryWeapon(src, item, give) then
                    refundRemovedItems(src, removed, 'Craft u anulua. Materialet u kthyen.')
                    finish(false, 'Nuk mban dot më shumë armë.')
                    return
                end
            elseif not canCarryItem(src, item, give) then
                refundRemovedItems(src, removed, 'Craft u anulua. Materialet u kthyen.')
                finish(false, 'Inventory është full për reward.')
                return
            end
        end
    end

    local given = {}
    for item, amount in pairs(reward) do
        local give = tonumber(amount) or 0
        if give > 0 then
            local ok
            if isWeaponName(item) then
                ok = createWeaponReward(src, item, give, recipe.label)
            else
                ok = addItem(src, item, give)
            end
            if not ok then
                -- Rollback materials and any non-weapon rewards already added.
                for _, g in ipairs(given) do
                    if not isWeaponName(g.item) then subItem(src, g.item, g.amount) end
                end
                refundRemovedItems(src, removed, 'Craft u anulua. Materialet u kthyen.')
                finish(false, ('Reward nuk u shtua: %s'):format(tostring(item)))
                return
            end
            given[#given + 1] = { item = item, amount = give }
        end
    end

    local addXp = getRecipeXp(recipe)
    setXp(src, xp + addXp)
    local rewardName, rewardAmount = firstReward({ reward = reward })
    finish(true, ('U craftua me sukses: %s%s'):format(tostring(recipe.label or rewardName or 'item'), rewardAmount and rewardAmount > 1 and (' x' .. tostring(rewardAmount)) or ''))
end)

AddEventHandler('playerDropped', function()
    local src = source
    if CraftPending[src] and CraftPending[src].removed then
        refundRemovedItems(src, CraftPending[src].removed)
    end
    CraftBusy[src] = nil
    CraftPending[src] = nil
end)


AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src, pending in pairs(CraftPending) do
        if pending and pending.removed then
            refundRemovedItems(src, pending.removed)
        end
    end
end)

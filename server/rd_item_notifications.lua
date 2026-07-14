--==============================================================
-- RD INVENTORY ITEM NOTIFICATIONS
-- Server helper used by inventory API + movement flows.
--==============================================================
RDItemNotify = RDItemNotify or {}

local function cfg()
    Config.RDItemNotifications = Config.RDItemNotifications or {}
    return Config.RDItemNotifications
end

local lastNotify = {}

local function nowMs()
    if GetGameTimer then return GetGameTimer() end
    return math.floor((os.clock() or 0) * 1000)
end

local function cleanName(name)
    if name == nil then return nil end
    name = tostring(name)
    if name == '' then return nil end
    return name
end

local function cleanAmount(amount)
    amount = tonumber(amount) or 1
    amount = math.floor(amount)
    if amount < 1 then amount = 1 end
    return amount
end

function RDItemNotify.GetLabel(name, metadata, fallback)
    name = cleanName(name)
    if type(metadata) == 'table' then
        if metadata.label and tostring(metadata.label) ~= '' then
            return tostring(metadata.label)
        end
        if metadata.name and tostring(metadata.name) ~= '' then
            return tostring(metadata.name)
        end
    end

    if name and ServerItems and ServerItems[name] then
        local ok, label = pcall(function()
            if ServerItems[name].getLabel then return ServerItems[name]:getLabel() end
            return ServerItems[name].label
        end)
        if ok and label and tostring(label) ~= '' then
            return tostring(label)
        end
    end

    local upper = name and string.upper(name) or nil
    if upper and SharedData and SharedData.Weapons and SharedData.Weapons[upper] then
        local wep = SharedData.Weapons[upper]
        if type(wep) == 'table' then
            if wep.label and tostring(wep.label) ~= '' then return tostring(wep.label) end
            if wep.Name and tostring(wep.Name) ~= '' then return tostring(wep.Name) end
            if wep.name and tostring(wep.name) ~= '' then return tostring(wep.name) end
        end
    end

    return tostring(fallback or name or 'Item')
end

local actionText = {
    add = 'MORRE',
    remove = 'U HOQ',
    pickup = 'MORRE NGA TOKA',
    drop = 'E HODHE',
    give_out = 'I DHE',
    give_in = 'MORRE NGA PLAYER',
    storage_put = 'VENDOSE NË STORAGE',
    storage_take = 'MORRE NGA STORAGE',
    player_put = 'I DHE PLAYERIT',
    player_take = 'MORRE NGA PLAYER',
    weapon_add = 'MORRE ARMË',
    weapon_remove = 'U HOQ ARMË',
    money_add = 'MORRE PARA',
    money_remove = 'U HOQËN PARA',
    gold_add = 'MORRE GOLD',
    gold_remove = 'U HOQ GOLD',
}

local typeForAction = {
    add = 'success',
    pickup = 'success',
    give_in = 'success',
    storage_take = 'success',
    player_take = 'success',
    weapon_add = 'success',
    money_add = 'success',
    gold_add = 'success',
    remove = 'error',
    drop = 'warning',
    give_out = 'warning',
    storage_put = 'warning',
    player_put = 'warning',
    weapon_remove = 'warning',
    money_remove = 'warning',
    gold_remove = 'warning',
}

local signForAction = {
    add = '+',
    pickup = '+',
    give_in = '+',
    storage_take = '+',
    player_take = '+',
    weapon_add = '+',
    money_add = '+',
    gold_add = '+',
    remove = '-',
    drop = '-',
    give_out = '-',
    storage_put = '-',
    player_put = '-',
    weapon_remove = '-',
    money_remove = '-',
    gold_remove = '-',
}

function RDItemNotify.Send(target, action, name, amount, metadata, options)
    local c = cfg()
    if c.Enabled == false then return end
    target = tonumber(target)
    if not target or target <= 0 then return end

    action = tostring(action or 'add')
    name = cleanName(name) or 'unknown'
    amount = cleanAmount(amount)
    options = options or {}

    local label = options.label or RDItemNotify.GetLabel(name, metadata, name)
    local title = options.title or actionText[action] or 'INVENTORY'
    local dedupeMs = tonumber(c.DedupeMs) or 450
    local key = ('%s:%s:%s:%s'):format(target, action, name, amount)
    local n = nowMs()
    if lastNotify[key] and (n - lastNotify[key]) < dedupeMs then
        return
    end
    lastNotify[key] = n

    TriggerClientEvent('rd_inventory:itemNotify', target, {
        actionName = action,
        actionLabel = title,
        title = title,
        name = name,
        label = label,
        amount = amount,
        metadata = metadata or {},
        sign = options.sign or signForAction[action] or '',
        notifyType = options.notifyType or typeForAction[action] or 'inform',
        image = options.image,
        imageOverride = options.imageOverride,
        duration = options.duration,
        icon = options.icon,
    })
end

function RDItemNotify.Add(target, name, amount, metadata, options)
    RDItemNotify.Send(target, 'add', name, amount, metadata, options)
end

function RDItemNotify.Remove(target, name, amount, metadata, options)
    RDItemNotify.Send(target, 'remove', name, amount, metadata, options)
end

function RDItemNotify.LegacyMovementEnabled()
    local c = cfg()
    return c.DisableLegacyMovementSuccess ~= true
end

-- Optional public event for other resources:
-- TriggerServerEvent('rd_inventory:itemNotify', 'add', 'bread', 2, {}, { label = 'Bread' })
RegisterNetEvent('rd_inventory:itemNotify', function(action, name, amount, metadata, options)
    RDItemNotify.Send(source, action, name, amount, metadata, options)
end)

--==============================================================
-- RD INVENTORY ITEM NOTIFICATIONS - OX_LIB ONLY
-- Every inventory movement notification goes through ox_lib.
-- No custom NUI toast, no VORP black/right-tip duplicate.
--==============================================================
local function getCfg()
    Config.RDItemNotifications = Config.RDItemNotifications or {}
    return Config.RDItemNotifications
end

local function oxPosition(pos)
    pos = tostring(pos or 'top')
    if pos == 'top-center' or pos == 'center-top' then return 'top' end
    if pos == 'bottom-center' or pos == 'center-bottom' then return 'bottom' end
    return pos
end

local function cleanItemName(name)
    name = tostring(name or 'unknown')
    name = name:gsub('%.%.', ''):gsub('[\\/]', '')
    if name == '' then name = 'unknown' end
    return name
end

local function nuiIconPath(payload)
    payload = payload or {}
    local override = payload.imageOverride or payload.image
    if override and tostring(override) ~= '' then
        local img = tostring(override)
        if img:find('^nui://') or img:find('^https?://') then return img end
        img = img:gsub('^html/', '')
        return ('nui://vorp_inventory/html/%s'):format(img)
    end
    return ('nui://vorp_inventory/html/img/items/%s.png'):format(cleanItemName(payload.name or payload.item))
end

local function notifyOx(payload)
    local cfg = getCfg()
    if cfg.Enabled == false then return end
    if type(payload) ~= 'table' then return end

    local amount = tonumber(payload.amount or payload.count) or 1
    local sign = tostring(payload.sign or '')
    local label = tostring(payload.label or payload.name or payload.item or 'Item')
    local title = tostring(payload.title or payload.actionLabel or 'Inventory')
    local desc = label
    if amount and amount > 0 then
        desc = ('%s  %s%s'):format(label, sign, amount)
    end

    local data = {
        title = title,
        description = desc,
        position = oxPosition(cfg.Position or payload.position or 'top'),
        duration = tonumber(payload.duration or cfg.Duration) or 3200,
        type = payload.notifyType or payload.type or 'inform',
        icon = payload.icon or nuiIconPath(payload),
        iconAnimation = nil,
        showDuration = true,
    }

    if type(lib) == 'table' and type(lib.notify) == 'function' then
        lib.notify(data)
        return
    end

    -- Fallback only to ox_lib event, never VORP/Core tip.
    TriggerEvent('ox_lib:notify', data)
end

RegisterNetEvent('rd_inventory:itemNotify', function(payload)
    notifyOx(payload)
end)

-- Other resources may call this old event; keep it ox_lib only.
RegisterNetEvent('rd_inventory:itemNotifyFallbackText', function(text, ms)
    notifyOx({
        title = 'Inventory',
        label = tostring(text or ''),
        amount = 0,
        duration = tonumber(ms) or 3000,
        notifyType = 'inform',
        icon = 'box'
    })
end)

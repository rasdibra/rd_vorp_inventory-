if Config.DevMode then
    AddEventHandler('onClientResourceStart', function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
            return
        end

        SendNUIMessage({ action = "hide" })
        TriggerServerEvent("DEV:loadweapons")
        TriggerServerEvent("vorpinventory:getItemsTable")
        Wait(1000)
        TriggerServerEvent("vorpinventory:getInventory")
        Wait(1000)
        TriggerServerEvent("vorpCore:LoadAllAmmo")
        Wait(100)
        TriggerEvent("vorpinventory:loaded")
        print("^1WARNING: Dev mode is enabled^7 do not use this in production live servers")
    end)
end


--==============================================================
-- RD HOTBAR V2 PORT (RedM safe)
-- Ported from the V2 hotbar key loop: ALT + 1/2/3/4/5 uses slots.
-- No RegisterKeyMapping is used here, so older RedM builds will not crash.
--==============================================================
local function RDHBValue(primary, fallback)
    if primary ~= nil then return primary end
    return fallback
end

local function RDHBBool(value, fallback)
    if value == nil then return fallback end
    return value == true
end

local function RDHBControl(value, fallback)
    if type(value) == "number" then return value end
    if type(value) == "string" then return GetHashKey(value) end
    return fallback
end

local function RDHBConfig()
    return Config.Hotbar or Config.HOTBAR or {}
end

local function RDHBSlotControl(cfg, index)
    local slotControls = cfg.SlotControls or cfg.SLOT_KEYS or cfg.Controls
    if type(slotControls) == "table" then
        local configured = slotControls[index] or slotControls[tostring(index)]
        if configured ~= nil then
            return RDHBControl(configured, nil)
        end
    end

    local defaults = {
        `INPUT_SELECT_QUICKSELECT_SIDEARMS_LEFT`,
        `INPUT_SELECT_QUICKSELECT_DUALWIELD`,
        `INPUT_SELECT_QUICKSELECT_SIDEARMS_RIGHT`,
        `INPUT_SELECT_QUICKSELECT_UNARMED`,
        `INPUT_SELECT_QUICKSELECT_MELEE_NO_UNARMED`,
    }
    return defaults[index]
end

local function RDHBSetVisible(show)
    show = show == true
    if NUIService and NUIService.RDSetHotbarVisible then
        NUIService.RDSetHotbarVisible(show)
        return
    end
    if show and NUIService and NUIService.RDSendHotbarUpdate then
        NUIService.RDSendHotbarUpdate()
    end
    SendNUIMessage({ action = "hotbarGame", visible = show })
end

local function RDHBUseSlot(slot)
    if NUIService and NUIService.RDUseHotbarSlot then
        NUIService.RDUseHotbarSlot(slot)
    end
end

CreateThread(function()
    local cfg = RDHBConfig()
    local enabled = RDHBBool(RDHBValue(cfg.Enable, cfg.ENABLE), true)
    if not enabled then return end

    repeat Wait(2000) until LocalPlayer.state.IsInSession

    if NUIService and NUIService.RDLoadHotbarPosition then
        local pos = NUIService.RDLoadHotbarPosition()
        if pos and pos.left and pos.top then
            SendNUIMessage({ action = "hotbarSetPos", left = pos.left, top = pos.top })
        end
    end

    local hotbarHudVisible = false
    local hotbarSuppressed = false
    local hideToken = 0
    local lastUse = 0

    local IsPauseMenuActive = IsPauseMenuActive
    local IsUiappActiveByHash = IsUiappActiveByHash
    local IsInCinematicMode = IsInCinematicMode
    local IsScreenFadedOut = IsScreenFadedOut
    local IsControlJustPressed = IsControlJustPressed
    local IsControlPressed = IsControlPressed
    local IsDisabledControlPressed = IsDisabledControlPressed
    local IsDisabledControlJustPressed = IsDisabledControlJustPressed
    local DisableControlAction = DisableControlAction

    while true do
        cfg = RDHBConfig()
        local slotCount = tonumber(RDHBValue(cfg.Slots, cfg.SLOT_COUNT)) or 5
        local holdKey = RDHBControl(RDHBValue(cfg.ModifierControl, cfg.HOLD_KEY), `INPUT_SELECT_RADAR_MODE`)
        local toggleKey = RDHBControl(RDHBValue(cfg.ToggleControl, cfg.TOGGLE_KEY), nil)
        local showWhenHold = RDHBBool(RDHBValue(cfg.ShowWhileHoldingAlt, cfg.SHOW_WHEN_HOLD), true)
        local disableNative = RDHBBool(RDHBValue(cfg.DisableNativeQuickSelect, cfg.DISABLE_NATIVE_QUICKSELECT), true)
        local allowInInventory = RDHBBool(RDHBValue(cfg.AllowWhenInventoryOpen, cfg.ALLOW_WHEN_INVENTORY_OPEN), false)
        local cooldown = tonumber(RDHBValue(cfg.UseCooldown, cfg.USE_COOLDOWN)) or 0

        local sleep = 1000
        local canUseNow = (not InInventory) or allowInInventory

        if canUseNow then
            sleep = 0

            if toggleKey and IsControlJustPressed(0, toggleKey) then
                hideToken = hideToken + 1
                hotbarHudVisible = not hotbarHudVisible
                hotbarSuppressed = false
                RDHBSetVisible(hotbarHudVisible)
            end

            local holdingAlt = IsControlPressed(0, holdKey) or IsDisabledControlPressed(0, holdKey)
            if holdingAlt then
                if showWhenHold and not hotbarHudVisible then
                    hotbarHudVisible = true
                    hotbarSuppressed = false
                    RDHBSetVisible(true)

                    -- Same feel as the V2 hotbar: show briefly while ALT is used,
                    -- then auto-hide without requiring an inventory refresh.
                    hideToken = hideToken + 1
                    local thisToken = hideToken
                    SetTimeout(3000, function()
                        if thisToken ~= hideToken then return end
                        hotbarHudVisible = false
                        hotbarSuppressed = true
                        RDHBSetVisible(false)
                    end)
                end

                for i = 1, slotCount do
                    local key = RDHBSlotControl(cfg, i)
                    if key then
                        if disableNative then
                            DisableControlAction(0, key, true)
                            if IsDisabledControlJustPressed(0, key) then
                                local now = GetGameTimer()
                                if cooldown <= 0 or now - lastUse >= cooldown then
                                    lastUse = now
                                    RDHBUseSlot(i)
                                end
                                break
                            end
                        else
                            if IsControlJustPressed(0, key) then
                                local now = GetGameTimer()
                                if cooldown <= 0 or now - lastUse >= cooldown then
                                    lastUse = now
                                    RDHBUseSlot(i)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end

        local shouldSuppress = false
        if IsPauseMenuActive and IsPauseMenuActive() == 1 then shouldSuppress = true end
        if IsHudHidden and IsHudHidden() then shouldSuppress = true end
        if IsInCinematicMode and IsInCinematicMode() == 1 then shouldSuppress = true end
        if IsUiappActiveByHash and IsUiappActiveByHash(joaat("MAP")) == 1 then shouldSuppress = true end
        if IsScreenFadedOut and IsScreenFadedOut() then shouldSuppress = true end

        if shouldSuppress and hotbarHudVisible and not hotbarSuppressed then
            hotbarSuppressed = true
            RDHBSetVisible(false)
        elseif not shouldSuppress and hotbarSuppressed and hotbarHudVisible then
            hotbarSuppressed = false
            RDHBSetVisible(true)
        end

        Wait(sleep)
    end
end)


CreateThread(function()
    if not Config.UseLanternPutOnBelt then
        return
    end

    repeat Wait(2000) until LocalPlayer.state.IsInSession

    local lastLantern = 0
    while true do
        local pedid = PlayerPedId()
        local weaponHeld <const> = GetPedCurrentHeldWeapon(pedid)
        local isLantern <const> = IsWeaponLantern(weaponHeld) == 1 -- assuming it will return all lanterns to true
        if isLantern then
            lastLantern = weaponHeld
        end

        if lastLantern ~= 0 and not isLantern then
            SetCurrentPedWeapon(pedid, lastLantern, true, 12, false, false)
            lastLantern = 0
        end
        Wait(500)
    end
end)


-- ENABLE PUSH TO TALK
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    if not Config.EnablePushToTalk then
        return
    end
    local isNuiFocused = false

    while true do
        local sleep = 0
        if InInventory then
            if not isNuiFocused then
                SetNuiFocusKeepInput(true)
                isNuiFocused = true
            end

            DisableAllControlActions(0)
            EnableControlAction(0, `INPUT_PUSH_TO_TALK`, true)
        else
            sleep = 1000
            if isNuiFocused then
                SetNuiFocusKeepInput(false)
                isNuiFocused = false
            end
        end
        Wait(sleep)
    end
end)

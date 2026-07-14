--==============================================================
-- RD Realistic Crafting client
-- Adds story-mode style chop prompt + immersive craft scene + movable NUI, without replacing original VORP inventory events.
--==============================================================
local RDRealCraft = {
    active = false,
    intro = false,
    uiOpen = false,
    props = {},
    fireProp = nil,
    fireFX = nil,
    smokeFX = nil,
    categoryToken = 0,
    chopLog = nil,
    splitPieces = 0,
    nativePrompt = nil,
    nativePromptGroup = nil,
    nativePromptActive = false,
    data = nil,
    recipeBusy = false,
    recipeProps = {},
    recipeHandProps = {},
    cameraTargetEntity = nil,
    cameraTargetCoords = nil,
    startCoords = nil,
    startHealth = nil,
    cancelReason = nil,
    currentRecipeKind = nil,
    craftCam = nil,
    refreshThread = false,
    lightThread = false,
    campfireProp = nil,
    campfireEndsAt = 0,
    campfireThread = false,
    campfireWarningSent = false,
    campfireAddBusy = false,
}

local Core = nil
CreateThread(function()
    Wait(500)
    if exports and exports.vorp_core then
        Core = exports.vorp_core:GetCore()
    end
end)

local function notify(msg, ms, notifyType)
    msg = tostring(msg or '')
    ms = tonumber(ms) or 3500
    notifyType = tostring(notifyType or '')
    if notifyType == '' then
        local lower = string.lower(msg)
        if lower:find('anul', 1, true) or lower:find('nuk', 1, true) or lower:find('error', 1, true) or lower:find('failed', 1, true) then
            notifyType = 'error'
        elseif lower:find('sukses', 1, true) or lower:find('craftua', 1, true) or lower:find('mbar', 1, true) then
            notifyType = 'success'
        else
            notifyType = 'inform'
        end
    end

    local sent = false
    if type(lib) == 'table' and type(lib.notify) == 'function' then
        sent = pcall(function()
            lib.notify({
                title = 'Craft',
                description = msg,
                type = notifyType,
                duration = ms,
                position = 'top-center'
            })
        end)
    end
    if sent then return end

    if Core and Core.NotifyRightTip then
        Core.NotifyRightTip(msg, ms)
    else
        print(('[RD Craft] %s'):format(msg))
    end
end

local cameraFocusKinds = {
    CampfireOnly = true,
    Fire = true,
    WorkTable = true,
    GunWorkbench = true,
    GunBench = true,
    AmmoWorkbench = true,
    FoodPrep = true,
    StewPot = true,
    SoupPot = true,
    Kettle = true,
    ChopBlock = true,
    SpooniChopBlock = true,
    Bedroll = true,
    SleepingBag = true,
    MedicalBag = true,
    MoonshineStill = true,
    StillBoiler = true,
    StillCondenser = true,
    StillBarrel = true,
    MashBucket = true,
}


local function clearCraftCameraTarget()
    RDRealCraft.cameraTargetEntity = nil
    RDRealCraft.cameraTargetCoords = nil
end

local function setCraftCameraTarget(coords, entity, force)
    if not coords then return end
    if not force and RDRealCraft.cameraTargetEntity and DoesEntityExist(RDRealCraft.cameraTargetEntity) then return end
    RDRealCraft.cameraTargetCoords = coords
    RDRealCraft.cameraTargetEntity = entity
end

local function getCraftCameraTarget(ped, targetSide, targetForward, targetHeight)
    if RDRealCraft.cameraTargetEntity and DoesEntityExist(RDRealCraft.cameraTargetEntity) then
        local c = GetEntityCoords(RDRealCraft.cameraTargetEntity)
        return vector3(c.x, c.y, c.z + (tonumber(((Config.RDRealisticCrafting or {}).CraftCameraSettings or {}).propTargetLift) or 0.28))
    end
    if RDRealCraft.cameraTargetCoords then
        local c = RDRealCraft.cameraTargetCoords
        return vector3(c.x, c.y, c.z + (tonumber(((Config.RDRealisticCrafting or {}).CraftCameraSettings or {}).propTargetLift) or 0.28))
    end
    return GetOffsetFromEntityInWorldCoords(ped, targetSide or 0.0, targetForward or 0.88, targetHeight or 0.16)
end

local function stopCraftCamera()
    if RDRealCraft.craftCam then
        pcall(function()
            RenderScriptCams(false, true, 350, true, true)
            DestroyCam(RDRealCraft.craftCam, false)
        end)
        RDRealCraft.craftCam = nil
    end
end

local function startCraftCamera(recipe)
    local cfg = Config.RDRealisticCrafting or {}
    if cfg.CraftCamera == false then return end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    stopCraftCamera()

    local camCfg = cfg.CraftCameraSettings or {}
    local kind = string.lower(tostring((recipe and (recipe.animation or recipe.anim or recipe.craftAnim or recipe.category or recipe.type)) or RDRealCraft.currentCategory or ''))
    if recipe and (recipe.isAmmo == true or string.lower(tostring(recipe.category or '')) == 'ammo' or string.lower(tostring(recipe.subcategory or '')) == 'ammo') then
        kind = 'ammo'
    end
    local camSide = tonumber(camCfg.side) or 1.45
    local camForward = tonumber(camCfg.forward) or 2.75
    local camHeight = tonumber(camCfg.height) or 0.72
    local targetSide = tonumber(camCfg.targetSide) or 0.0
    local targetForward = tonumber(camCfg.targetForward) or 0.88
    local targetHeight = tonumber(camCfg.targetHeight) or 0.16
    local fov = tonumber(camCfg.fov) or 56.0

    -- Cooking/drink/survival animations can crouch or sit very low. Pull the camera back
    -- and aim at the craft station/ground, not only at the player's chest, so the pot/fire/bench stays visible.
    if kind:find('food', 1, true) or kind:find('meat', 1, true) or kind:find('soup', 1, true) or kind:find('stew', 1, true) or kind:find('drink', 1, true) or kind:find('water', 1, true) or kind:find('smoke', 1, true) or kind:find('tobacco', 1, true) then
        camForward = tonumber(camCfg.cookForward) or 3.05
        camHeight = tonumber(camCfg.cookHeight) or 0.62
        targetForward = tonumber(camCfg.cookTargetForward) or 1.02
        targetHeight = tonumber(camCfg.cookTargetHeight) or 0.05
        fov = tonumber(camCfg.cookFov) or 58.0
    elseif kind:find('ammo', 1, true) or kind:find('gun', 1, true) or kind:find('weapon', 1, true) or kind:find('medical', 1, true) or kind:find('bandage', 1, true) or kind:find('syringe', 1, true) or kind:find('moonshine', 1, true) then
        camForward = tonumber(camCfg.gunForward) or 3.15
        camHeight = tonumber(camCfg.gunHeight) or 0.58
        targetForward = tonumber(camCfg.gunTargetForward) or 1.03
        targetHeight = tonumber(camCfg.gunTargetHeight) or 0.03
        fov = tonumber(camCfg.gunFov) or 58.0
    elseif kind:find('furniture', 1, true) or kind:find('woodwork', 1, true) or kind:find('survival', 1, true) or kind:find('tools', 1, true) then
        camForward = tonumber(camCfg.workForward) or 2.95
        camHeight = tonumber(camCfg.workHeight) or 0.68
        targetForward = tonumber(camCfg.workTargetForward) or 0.98
        targetHeight = tonumber(camCfg.workTargetHeight) or 0.10
        fov = tonumber(camCfg.workFov) or 57.0
    end

    local ok = pcall(function()
        local camCoords = GetOffsetFromEntityInWorldCoords(ped, camSide, camForward, camHeight)
        local targetCoords = getCraftCameraTarget(ped, targetSide, targetForward, targetHeight)
        local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
        PointCamAtCoord(cam, targetCoords.x, targetCoords.y, targetCoords.z)
        SetCamFov(cam, fov)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 450, true, true)
        RDRealCraft.craftCam = cam

        CreateThread(function()
            while RDRealCraft.craftCam == cam and RDRealCraft.active and RDRealCraft.recipeBusy do
                local p = PlayerPedId()
                if p and p ~= 0 then
                    local c = GetOffsetFromEntityInWorldCoords(p, camSide, camForward, camHeight)
                    local t = getCraftCameraTarget(p, targetSide, targetForward, targetHeight)
                    pcall(function()
                        SetCamCoord(cam, c.x, c.y, c.z)
                        PointCamAtCoord(cam, t.x, t.y, t.z)
                    end)
                end
                Wait(250)
            end
        end)
    end)
    if not ok then RDRealCraft.craftCam = nil end
end

local function playCraftSound(name, entity)
    if not (Config.RDRealisticCrafting and Config.RDRealisticCrafting.Audio) then return end
    name = tostring(name or '')
    if name == '' then return end
    pcall(function()
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            PlaySoundFromEntity(-1, name, entity, 0, false, 0)
        else
            PlaySoundFrontend(name, 0, true, 0)
        end
    end)
end

local function markCraftOrigin()
    local ped = PlayerPedId()
    RDRealCraft.startCoords = GetEntityCoords(ped)
    RDRealCraft.startHealth = GetEntityHealth(ped)
    RDRealCraft.cancelReason = nil
end

local function shouldInterruptCraft()
    if not RDRealCraft.active then return true, 'Craft u anulua.' end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return true, 'Craft u anulua.' end
    if IsPedDeadOrDying(ped, false) then return true, 'Nuk mund te besh craft kur je i rrezuar.' end
    if IsPedInAnyVehicle(ped, false) then return true, 'Craft u anulua.' end
    local ragdoll = false
    local stunned = false
    pcall(function() ragdoll = IsPedRagdoll(ped) end)
    pcall(function() stunned = IsPedBeingStunned(ped, 0) end)
    if ragdoll or stunned then return true, 'Craft u nderpre.' end

    local cfg = Config.RDRealisticCrafting or {}
    if cfg.CancelOnDamage ~= false and RDRealCraft.startHealth and GetEntityHealth(ped) < RDRealCraft.startHealth then
        return true, 'Craft u nderpre nga demtimi.'
    end

    if RDRealCraft.startCoords then
        local maxDist = tonumber(cfg.MaxCraftDistance) or 2.8
        local coords = GetEntityCoords(ped)
        if #(coords - RDRealCraft.startCoords) > maxDist then
            return true, 'U largove nga vendi i craft-it.'
        end
    end

    return false, nil
end

local function setCraftCanceled(reason)
    RDRealCraft.cancelReason = reason or 'Craft u anulua.'
    RDRealCraft.active = false
    RDRealCraft.recipeBusy = false
    TriggerServerEvent('rd_inventory:realCraft:cancel')
end

local function varString(text)
    text = tostring(text or '')
    local ok, result = pcall(function()
        return CreateVarString(10, 'LITERAL_STRING', text)
    end)
    if ok then return result end
    return text
end

local function destroyNativeChopPrompt()
    RDRealCraft.nativePromptActive = false
    if RDRealCraft.nativePrompt then
        pcall(function()
            PromptSetEnabled(RDRealCraft.nativePrompt, false)
            PromptSetVisible(RDRealCraft.nativePrompt, false)
            PromptDelete(RDRealCraft.nativePrompt)
        end)
    end
    RDRealCraft.nativePrompt = nil
    RDRealCraft.nativePromptGroup = nil
end

local function ensureNativeChopPrompt()
    -- Native RedM prompt that looks like story-mode: CHOP [LEFT CLICK] / FIREWOOD.
    -- If a build does not expose Prompt* functions, the NUI prompt below is used safely.
    if RDRealCraft.nativePrompt then return true end

    local ok, prompt, group = pcall(function()
        local g = GetRandomIntInRange(0, 0xffffff)
        local p = PromptRegisterBegin()
        PromptSetControlAction(p, `INPUT_ATTACK`)
        PromptSetText(p, varString(((Config.RDRealisticCrafting or {}).SpooniFirewoodScene or {}).PromptText or 'Prej'))
        PromptSetEnabled(p, true)
        PromptSetVisible(p, true)
        PromptSetStandardMode(p, true)
        PromptSetGroup(p, g, 0)
        PromptRegisterEnd(p)
        return p, g
    end)

    if ok and prompt then
        RDRealCraft.nativePrompt = prompt
        RDRealCraft.nativePromptGroup = group
        return true
    end
    RDRealCraft.nativePrompt = nil
    RDRealCraft.nativePromptGroup = nil
    return false
end

local function drawNativeChopPrompt(step, total)
    if not RDRealCraft.nativePromptActive then return end
    if not ensureNativeChopPrompt() then return end
    pcall(function()
        PromptSetEnabled(RDRealCraft.nativePrompt, true)
        PromptSetVisible(RDRealCraft.nativePrompt, true)
        PromptSetText(RDRealCraft.nativePrompt, varString(((Config.RDRealisticCrafting or {}).SpooniFirewoodScene or {}).PromptText or 'Prej'))
        PromptSetActiveGroupThisFrame(RDRealCraft.nativePromptGroup, varString(((Config.RDRealisticCrafting or {}).SpooniFirewoodScene or {}).PromptTitle or 'Dru per zjarr'), 1, 0, 0, 0)
    end)
end

local function sendPrompt(show, text, step, total)
    total = total or (Config.RDRealisticCrafting and Config.RDRealisticCrafting.ChopClicks or 5)
    step = step or 0

    -- Keep native prompt alive during the chop phase, but also send the fallback NUI prompt.
    if show then
        RDRealCraft.nativePromptActive = true
        ensureNativeChopPrompt()
    else
        destroyNativeChopPrompt()
    end

    SendNUIMessage({
        action = 'rdRealCraftPrompt',
        show = show,
        text = text or 'PREJ',
        step = step,
        total = total,
        title = (((Config.RDRealisticCrafting or {}).SpooniFirewoodScene or {}).PromptText or 'PREJ'),
        key = (Config.RDRealisticCrafting and Config.RDRealisticCrafting.ChopPromptKey) or 'KLIK MAJTAS',
        subtitle = (((Config.RDRealisticCrafting or {}).SpooniFirewoodScene or {}).PromptTitle or 'DRU PER ZJARR')
    })
end

local function requestModelByList(list, timeout)
    timeout = timeout or 1200
    if type(list) == 'string' then list = { list } end
    if type(list) ~= 'table' then return nil end

    for _, modelName in ipairs(list) do
        local hash = type(modelName) == 'number' and modelName or GetHashKey(tostring(modelName))
        RequestModel(hash)
        local endAt = GetGameTimer() + timeout
        while not HasModelLoaded(hash) and GetGameTimer() < endAt do
            Wait(10)
        end
        if HasModelLoaded(hash) then
            return hash
        end
    end
    return nil
end



local function getSpooniFirewoodScene()
    local cfg = Config.RDRealisticCrafting or {}
    local scene = cfg.SpooniFirewoodScene or {}
    if scene.Enabled == false then return nil end
    return scene
end

local function getFirewoodScenarios()
    local scene = getSpooniFirewoodScene()
    if scene and type(scene.Scenarios) == 'table' and #scene.Scenarios > 0 then
        return scene.Scenarios
    end
    return (Config.RDRealisticCrafting and Config.RDRealisticCrafting.ChopScenarios) or {
        'WORLD_HUMAN_CHOP_WOOD',
        'WORLD_HUMAN_FIREWOOD_CHOP',
        'WORLD_HUMAN_SPLIT_WOOD',
        'WORLD_HUMAN_WOOD_CHOP',
    }
end

local function getFirewoodFallbackAnimations()
    local scene = getSpooniFirewoodScene()
    if scene and type(scene.FallbackAnimations) == 'table' and #scene.FallbackAnimations > 0 then
        return scene.FallbackAnimations
    end
    return {
        { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
        { dict = 'amb_work@world_human_hammer@male_a@idle_a', anim = 'idle_a' },
        { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
    }
end

local function createCraftProp(kind, offsetX, offsetY, offsetZ, headingOffset)
    local props = (Config.RDRealisticCrafting and Config.RDRealisticCrafting.Props) or {}
    local modelList = props[kind]
    local hash = requestModelByList(modelList, 900)
    if not hash then return nil end

    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, offsetX or 0.0, offsetY or 1.0, offsetZ or -0.95)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false, false, true)
    if obj and obj ~= 0 then
        SetEntityHeading(obj, GetEntityHeading(ped) + (headingOffset or 0.0))
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        table.insert(RDRealCraft.props, obj)
        SetModelAsNoLongerNeeded(hash)
        return obj
    end
    SetModelAsNoLongerNeeded(hash)
    return nil
end


local function createCraftPropAdvanced(kind, offsetX, offsetY, offsetZ, headingOffset, rotation, placeOnGround)
    local props = (Config.RDRealisticCrafting and Config.RDRealisticCrafting.Props) or {}
    local modelList = props[kind]
    local hash = requestModelByList(modelList, 950)
    if not hash then return nil end

    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, offsetX or 0.0, offsetY or 1.0, offsetZ or -0.95)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false, false, true)
    if obj and obj ~= 0 then
        local heading = GetEntityHeading(ped) + (headingOffset or 0.0)
        SetEntityHeading(obj, heading)
        if rotation then
            pcall(function()
                SetEntityRotation(obj, rotation.x or 0.0, rotation.y or 0.0, rotation.z or heading, 2, true)
            end)
        end
        if placeOnGround ~= false then
            PlaceObjectOnGroundProperly(obj)
        end
        FreezeEntityPosition(obj, true)
        table.insert(RDRealCraft.props, obj)
        SetModelAsNoLongerNeeded(hash)
        return obj, coords
    end
    SetModelAsNoLongerNeeded(hash)
    return nil, coords
end

local function faceCraftStation(ped, coords, waitMs)
    if not coords then return end
    pcall(function()
        TaskTurnPedToFaceCoord(ped, coords.x, coords.y, coords.z, waitMs or 450)
    end)
    Wait(waitMs or 450)
end

local function spawnWoodChopStation(ped)
    -- Spooni-style FIREWOOD / CHOP interaction scene: block/stump, log, pile and split pieces.
    -- Props are read from Config.RDRealisticCrafting.SpooniFirewoodScene first, with safe fallbacks.
    local scene = getSpooniFirewoodScene()
    local firstCoords = nil
    RDRealCraft.chopLog = nil

    if scene and type(scene.Station) == 'table' and #scene.Station > 0 then
        for _, entry in ipairs(scene.Station) do
            if entry and entry.kind then
                local rot = entry.rot
                if rot and rot.z then
                    rot = { x = rot.x or 0.0, y = rot.y or 0.0, z = GetEntityHeading(ped) + (rot.z or 0.0) }
                end
                local ent, coords = createCraftPropAdvanced(
                    entry.kind,
                    entry.x or 0.0,
                    entry.y or 1.0,
                    entry.z or -0.98,
                    entry.heading or 0.0,
                    rot,
                    entry.ground ~= false
                )
                if ent and not firstCoords then firstCoords = coords end
                if ent and tostring(entry.kind):lower():find('log', 1, true) then RDRealCraft.chopLog = ent end
            end
        end
    end

    -- Fallback for builds where the configured station prop names are absent.
    if not firstCoords then
        local block, blockCoords = createCraftPropAdvanced('ChopBlock', 0.0, 1.05, -0.98, 0.0, nil, true)
        local log, logCoords = createCraftPropAdvanced('ChopLog', 0.0, 1.05, -0.74, 90.0, { x = 86.0, y = 0.0, z = GetEntityHeading(ped) + 90.0 }, false)
        RDRealCraft.chopLog = log
        createCraftPropAdvanced('WoodPile', -0.55, 1.08, -0.98, 22.0, nil, true)
        if not block then
            block, blockCoords = createCraftPropAdvanced('Wood', 0.0, 1.05, -0.98, 90.0, nil, true)
        end
        firstCoords = blockCoords or logCoords
    end

    faceCraftStation(ped, firstCoords, 520)
    return firstCoords
end
local function deleteEntitySafe(ent)
    if ent and ent ~= 0 and DoesEntityExist(ent) then
        pcall(function()
            if NetworkGetEntityIsNetworked(ent) then
                local netId = NetworkGetNetworkIdFromEntity(ent)
                if netId and netId ~= 0 then
                    SetNetworkIdCanMigrate(netId, false)
                    NetworkRequestControlOfEntity(ent)
                    local endAt = GetGameTimer() + 450
                    while DoesEntityExist(ent) and not NetworkHasControlOfEntity(ent) and GetGameTimer() < endAt do
                        Wait(0)
                        NetworkRequestControlOfEntity(ent)
                    end
                    NetworkUnregisterNetworkedEntity(ent)
                end
            end
        end)
        pcall(function() DetachEntity(ent, true, true) end)
        pcall(function() SetEntityAsMissionEntity(ent, true, true) end)
        pcall(function() DeleteObject(ent) end)
        pcall(function() DeleteEntity(ent) end)
    end
end

local function stopCraftFx()
    if RDRealCraft.fireFX then
        pcall(function() StopParticleFxLooped(RDRealCraft.fireFX, false) end)
        RDRealCraft.fireFX = nil
    end
    if RDRealCraft.smokeFX then
        pcall(function() StopParticleFxLooped(RDRealCraft.smokeFX, false) end)
        RDRealCraft.smokeFX = nil
    end
end

local function cleanupRecipeStation()
    -- CLEAN OLD (FIXED nil safety)
    stopCraftCamera()
    stopCraftFx()

    if RDRealCraft.fireProp then
        deleteEntitySafe(RDRealCraft.fireProp)
        RDRealCraft.fireProp = nil
    end

    for _, ent in ipairs(RDRealCraft.props or {}) do
        deleteEntitySafe(ent)
    end
    RDRealCraft.props = {}
    RDRealCraft.recipeProps = {}
    RDRealCraft.recipeHandProps = {}
    clearCraftCameraTarget()
end

local function cleanupScene(keepFire)
    stopCraftCamera()
    if not keepFire then stopCraftFx() end
    for _, ent in ipairs(RDRealCraft.props or {}) do
        if keepFire and ent == RDRealCraft.fireProp then
            goto continue
        end
        deleteEntitySafe(ent)
        ::continue::
    end
    RDRealCraft.props = {}
    if keepFire and RDRealCraft.fireProp and DoesEntityExist(RDRealCraft.fireProp) then
        RDRealCraft.props = { RDRealCraft.fireProp }
        setCraftCameraTarget(GetEntityCoords(RDRealCraft.fireProp), RDRealCraft.fireProp, true)
    else
        RDRealCraft.fireProp = nil
        RDRealCraft.recipeProps = {}
        RDRealCraft.recipeHandProps = {}
        clearCraftCameraTarget()
    end
end

local function startFireLight()
    if RDRealCraft.lightThread then return end
    if not (Config.RDRealisticCrafting and Config.RDRealisticCrafting.FireLight) then return end
    RDRealCraft.lightThread = true
    CreateThread(function()
        while RDRealCraft.active and RDRealCraft.fireProp and DoesEntityExist(RDRealCraft.fireProp) do
            local coords = GetEntityCoords(RDRealCraft.fireProp)
            pcall(function()
                DrawLightWithRange(coords.x, coords.y, coords.z + 0.45, 255, 146, 61, tonumber(Config.RDRealisticCrafting.FireLightRadius) or 7.5, tonumber(Config.RDRealisticCrafting.FireLightIntensity) or 5.0)
            end)
            Wait(0)
        end
        RDRealCraft.lightThread = false
    end)
end

local function tryScenario(ped, scenario, duration)
    local ok = pcall(function()
        TaskStartScenarioInPlace(ped, GetHashKey(scenario), duration or -1, true, false, false, false)
    end)
    return ok
end

local function loadAnimDict(dict, timeout)
    timeout = timeout or 900
    RequestAnimDict(dict)
    local endAt = GetGameTimer() + timeout
    while not HasAnimDictLoaded(dict) and GetGameTimer() < endAt do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end


local function spawnSplitWoodPiece(step)
    -- Visual feedback per click: the intact log disappears after the first heavy hit,
    -- then small chopped pieces appear around the block like story-mode wood chopping.
    step = tonumber(step) or 1
    if step == 1 and RDRealCraft.chopLog and DoesEntityExist(RDRealCraft.chopLog) then
        deleteEntitySafe(RDRealCraft.chopLog)
        RDRealCraft.chopLog = nil
    end

    local scene = getSpooniFirewoodScene()
    local pieceCfg = scene and type(scene.SplitPieces) == 'table' and scene.SplitPieces[step] or nil
    if pieceCfg then
        createCraftPropAdvanced('SpooniChopSplit', pieceCfg.x or 0.0, pieceCfg.y or 1.0, pieceCfg.z or -0.90, pieceCfg.heading or (60.0 + step * 18.0), { x = 0.0, y = 0.0, z = GetEntityHeading(PlayerPedId()) + (pieceCfg.heading or (step * 24.0)) }, true)
    else
        local side = (step % 2 == 0) and 1 or -1
        local x = 0.12 * side * math.min(step, 4)
        local y = 1.02 + (0.06 * math.min(step, 5))
        local z = -0.89
        createCraftPropAdvanced('ChopSplit', x, y, z, 60.0 + (step * 18.0), { x = 0.0, y = 0.0, z = GetEntityHeading(PlayerPedId()) + (step * 24.0) }, true)
    end
    RDRealCraft.splitPieces = (RDRealCraft.splitPieces or 0) + 1
end
local function playChopAnim(ped, step, stationCoords)
    -- RD FIX11: firewood chopping must look like the story-mode CHOP/FIREWOOD scene,
    -- not like cutting a tree. Keep the spawned stump/log pile and run only the
    -- firewood/chop scenarios first. If the build misses those scenarios, fall back
    -- to a short hammer/work motion while the axe prop stays in hand.
    faceCraftStation(ped, stationCoords, 120)
    ClearPedSecondaryTask(ped)

    local played = false
    local scenarios = getFirewoodScenarios()

    for _, scenario in ipairs(scenarios) do
        scenario = tostring(scenario or '')
        if scenario ~= '' then
            -- Try the story-mode station scenario first so it looks like FIREWOOD/CHOP,
            -- not tree cutting. If a server build rejects that, fall back in-place.
            local ok = false
            if stationCoords then
                ok = pcall(function()
                    TaskStartScenarioAtPosition(ped, GetHashKey(scenario), stationCoords.x, stationCoords.y, stationCoords.z, GetEntityHeading(ped), 1650, true, false, 0, false)
                end)
            end
            if not ok then
                ok = pcall(function()
                    TaskStartScenarioInPlace(ped, GetHashKey(scenario), 1650, true, false, false, false)
                end)
            end
            if ok then
                played = true
                break
            end
        end
    end

    if not played then
        local candidates = getFirewoodFallbackAnimations()
        for _, a in ipairs(candidates) do
            if loadAnimDict(a.dict, 900) then
                TaskPlayAnim(ped, a.dict, a.anim, 4.0, -4.0, 1450, 1, 0.0, false, 0, false, 0, false)
                played = true
                break
            end
        end
    end

    if not played then
        tryScenario(ped, 'WORLD_HUMAN_HAMMER_TABLE', 1450)
    end

    SetTimeout(620, function()
        if RDRealCraft.active then spawnSplitWoodPiece(step) end
    end)
end
local function playLightFireAnim(ped)
    local played = false
    local candidates = {
        { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
        { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
    }

    for _, a in ipairs(candidates) do
        if loadAnimDict(a.dict, 650) then
            TaskPlayAnim(ped, a.dict, a.anim, 3.0, -3.0, 3600, 1, 0.0, false, 0, false, 0, false)
            played = true
            break
        end
    end

    if not played then
        tryScenario(ped, 'WORLD_HUMAN_CAMP_FIRE', 3600)
    end
end


-- RD HAND FIX: RedM bone names are case-sensitive on many builds.
-- Old configs used SKEL_R_HAND/SKEL_L_HAND which can resolve to the wrong/root bone.
-- This resolver accepts both old and correct RDR2 names and tries PH_* hand bones too.
local function resolveEntityBone(entity, boneName)
    boneName = tostring(boneName or '')
    local candidates = {}
    local seen = {}
    local function add(name)
        name = tostring(name or '')
        if name ~= '' and not seen[name] then
            seen[name] = true
            candidates[#candidates + 1] = name
        end
    end

    -- Prefer the correct RDR2 case first when an older all-caps alias is passed.
    if boneName == 'SKEL_R_HAND' then add('SKEL_R_Hand') end
    if boneName == 'SKEL_L_HAND' then add('SKEL_L_Hand') end
    add(boneName)
    local upper = boneName:upper()
    if upper:find('R_HAND', 1, true) or upper:find('R_ HAND', 1, true) or upper:find('RIGHT', 1, true) then
        add('SKEL_R_Hand')
        add('PH_R_Hand')
        add('IK_R_Hand')
        add('SKEL_R_Finger00')
        add('SKEL_R_Finger01')
        add('SKEL_R_HAND')
    elseif upper:find('L_HAND', 1, true) or upper:find('L_ HAND', 1, true) or upper:find('LEFT', 1, true) then
        add('SKEL_L_Hand')
        add('PH_L_Hand')
        add('IK_L_Hand')
        add('SKEL_L_Finger00')
        add('SKEL_L_Finger01')
        add('SKEL_L_HAND')
    end

    for _, name in ipairs(candidates) do
        local ok, bone = pcall(function()
            return GetEntityBoneIndexByName(entity, name)
        end)
        if ok and bone and bone >= 0 then
            return bone
        end
    end

    return 0
end

local function attachAxe(ped)
    local props = (Config.RDRealisticCrafting and Config.RDRealisticCrafting.Props) or {}
    local scene = getSpooniFirewoodScene()
    local hash = requestModelByList(props.SpooniAxe or props.Axe, 900)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local axe = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false, false, true)
    if axe and axe ~= 0 then
        local attach = (scene and scene.AxeAttach) or { bone = 'SKEL_R_Hand', x = 0.05, y = -0.02, z = -0.02, rx = -78.0, ry = 10.0, rz = 4.0 }
        local bone = resolveEntityBone(ped, attach.bone or 'SKEL_R_Hand')
        AttachEntityToEntity(
            axe,
            ped,
            bone,
            attach.x or 0.05,
            attach.y or -0.02,
            attach.z or -0.02,
            attach.rx or -78.0,
            attach.ry or 10.0,
            attach.rz or 4.0,
            true,
            true,
            false,
            true,
            1,
            true
        )
        table.insert(RDRealCraft.props, axe)
        RDRealCraft.recipeProps = RDRealCraft.recipeProps or {}
        table.insert(RDRealCraft.recipeProps, axe)
        RDRealCraft.recipeHandProps = RDRealCraft.recipeHandProps or {}
        table.insert(RDRealCraft.recipeHandProps, axe)
        SetModelAsNoLongerNeeded(hash)
        return axe
    end
    SetModelAsNoLongerNeeded(hash)
    return nil
end

local function cleanupRecipeProps()
    for _, ent in ipairs(RDRealCraft.recipeProps or {}) do
        if RDRealCraft.fireProp and ent == RDRealCraft.fireProp then
            RDRealCraft.fireProp = nil
        end
        deleteEntitySafe(ent)
    end
    RDRealCraft.recipeProps = {}
    RDRealCraft.recipeHandProps = {}
    clearCraftCameraTarget()
end

local function rememberRecipeHandProp(ent)
    if ent and ent ~= 0 then
        RDRealCraft.recipeHandProps = RDRealCraft.recipeHandProps or {}
        table.insert(RDRealCraft.recipeHandProps, ent)
    end
end

local function cleanupRecipeHandProps()
    for _, ent in ipairs(RDRealCraft.recipeHandProps or {}) do
        deleteEntitySafe(ent)
    end
    RDRealCraft.recipeHandProps = {}
end

local function createRecipeProp(kind, offsetX, offsetY, offsetZ, headingOffset, rotation, placeOnGround)
    local ent, coords = createCraftPropAdvanced(kind, offsetX, offsetY, offsetZ, headingOffset, rotation, placeOnGround)
    if ent then
        RDRealCraft.recipeProps = RDRealCraft.recipeProps or {}
        table.insert(RDRealCraft.recipeProps, ent)
        setCraftCameraTarget(coords, ent, cameraFocusKinds[kind] == true)
    end
    return ent, coords
end

local function ensureRecipeFire(offsetY)
    offsetY = tonumber(offsetY) or 1.22
    if RDRealCraft.fireProp and DoesEntityExist(RDRealCraft.fireProp) then
        return GetEntityCoords(RDRealCraft.fireProp)
    end
    RDRealCraft.fireProp = nil

    -- Use ONLY a clean campfire prop here. Do not use p_campfirecombined01x because
    -- that model spawns the huge tripod/cauldron seen in the screenshot.
    local ent, coords = createRecipeProp('CampfireOnly', 0.0, offsetY, -0.98, 0.0, nil, true)
    if not ent then
        ent, coords = createRecipeProp('Fire', 0.0, offsetY, -0.98, 0.0, nil, true)
    end
    if ent then
        RDRealCraft.fireProp = ent
        startFireLight()
    end
    return coords
end

local function lowerText(value)
    return string.lower(tostring(value or ''))
end

local function firstRewardName(recipe)
    local reward = recipe and recipe.reward or {}
    if type(reward) ~= 'table' then return '' end
    for name, _ in pairs(reward) do
        return tostring(name or '')
    end
    return tostring(recipe and recipe.rewardName or '')
end

local function inferRecipeAnimation(recipe)
    recipe = recipe or {}
    local recipeCategory = lowerText(recipe.category)
    local recipeSubcategory = lowerText(recipe.subcategory)
    if recipe.isAmmo == true or recipeCategory == 'ammo' or recipeSubcategory == 'ammo' then
        return 'ammo'
    end
    local explicit = lowerText(recipe.animation or recipe.anim or recipe.craftAnim or recipe.category or recipe.type)
    if explicit ~= '' then return explicit end

    local text = lowerText((recipe.label or '') .. ' ' .. (recipe.desc or '') .. ' ' .. firstRewardName(recipe))
    if text:find('firewood', 1, true) or text:find('chop', 1, true) or text:find('kindling', 1, true) or text:find('campfire kit', 1, true) or text:find('wood', 1, true) or text:find('log', 1, true) then
        return 'firewood'
    end
    if text:find('weapon', 1, true) or text:find('gun', 1, true) or text:find('rifle', 1, true) or text:find('revolver', 1, true) or text:find('pistol', 1, true) or text:find('ammo', 1, true) or text:find('shotgun', 1, true) then
        return 'gun'
    end
    if text:find('chair', 1, true) or text:find('furniture', 1, true) or text:find('woodwork', 1, true) or text:find('table', 1, true) or text:find('bench', 1, true) then
        return 'woodwork'
    end
    if text:find('soup', 1, true) or text:find('stew', 1, true) or text:find('broth', 1, true) then
        return 'soup'
    end
    if text:find('forage', 1, true) or text:find('herb', 1, true) or text:find('pouch', 1, true) or text:find('sort', 1, true) then
        return 'forage'
    end
    if text:find('meat', 1, true) or text:find('steak', 1, true) or text:find('cooked_game', 1, true) or text:find('venison', 1, true) then
        return 'meat'
    end
    if text:find('coffee', 1, true) or text:find('water', 1, true) or text:find('drink', 1, true) or text:find('tea', 1, true) then
        return 'drink'
    end
    if text:find('bread', 1, true) or text:find('food', 1, true) or text:find('meal', 1, true) or text:find('corn', 1, true) or text:find('fish', 1, true) then
        return 'food'
    end
    if text:find('cigarette', 1, true) or text:find('cigar', 1, true) or text:find('duhan', 1, true) or text:find('tobacco', 1, true) or text:find('pipe', 1, true) then
        return 'smoke_cigarette'
    end
    if text:find('bandage', 1, true) or text:find('syringe', 1, true) or text:find('mjek', 1, true) then
        return 'medical'
    end
    if text:find('bedroll', 1, true) or text:find('sleeping', 1, true) or text:find('gjumi', 1, true) then
        return 'bedroll_craft'
    end
    if text:find('moonshine', 1, true) or text:find('still', 1, true) or text:find('mash', 1, true) then
        return 'moonshine_metal'
    end
    return 'generic'
end

local function startScenarioList(ped, scenarios, duration, coords)
    if type(scenarios) ~= 'table' then return false end
    for _, scenario in ipairs(scenarios) do
        scenario = tostring(scenario or '')
        if scenario ~= '' then
            local ok = pcall(function()
                if coords then
                    TaskStartScenarioAtPosition(
                        ped,
                        GetHashKey(scenario),
                        coords.x,
                        coords.y,
                        coords.z,
                        GetEntityHeading(ped),
                        duration or -1,
                        true,
                        false,
                        0,
                        false
                    )
                else
                    TaskStartScenarioInPlace(ped, GetHashKey(scenario), duration or -1, true, false, false, false)
                end
            end)
            if ok then return true end
        end
    end
    return false
end

local function playAnimCandidates(ped, candidates, duration, flag)
    if type(candidates) ~= 'table' then return false end
    for _, a in ipairs(candidates) do
        if a and a.dict and a.anim and loadAnimDict(a.dict, 900) then
            TaskPlayAnim(ped, a.dict, a.anim, 3.0, -3.0, duration or -1, flag or 1, 0.0, false, 0, false, 0, false)
            return true
        end
    end
    return false
end

local function isPedPlayingAnyCandidate(ped, candidates)
    if type(candidates) ~= 'table' then return false end
    for _, a in ipairs(candidates) do
        if a and a.dict and a.anim then
            local ok, playing = pcall(function()
                return IsEntityPlayingAnim(ped, a.dict, a.anim, 3)
            end)
            if ok and playing then return true end
        end
    end
    return false
end

local function playLoopedCraftAnim(ped, candidates, duration, flag, replayMs)
    if type(candidates) ~= 'table' then return false end
    local selected = nil
    for _, a in ipairs(candidates) do
        if a and a.dict and a.anim and loadAnimDict(a.dict, 900) then
            selected = a
            break
        end
    end
    if not selected then return false end

    flag = flag or 17
    replayMs = tonumber(replayMs) or 3200
    ClearPedTasks(ped)
    TaskPlayAnim(ped, selected.dict, selected.anim, 3.0, -3.0, duration or -1, flag, 0.0, false, 0, false, 0, false)

    CreateThread(function()
        local nextReplay = GetGameTimer() + replayMs
        while RDRealCraft.active and RDRealCraft.uiOpen and RDRealCraft.recipeBusy do
            local p = PlayerPedId()
            if p and p ~= 0 and GetGameTimer() >= nextReplay then
                local okPlaying = isPedPlayingAnyCandidate(p, { selected })
                if not okPlaying then
                    TaskPlayAnim(p, selected.dict, selected.anim, 3.0, -3.0, duration or -1, flag, 0.0, false, 0, false, 0, false)
                end
                nextReplay = GetGameTimer() + replayMs
            end
            Wait(250)
        end
    end)
    return true
end


local function getRuntimeCampfireConfig()
    local cfg = (Config.RDRealisticCrafting or {}).CampfireRuntime or {}
    if cfg.Enabled == false then return cfg end
    cfg.InitialSeconds = tonumber(cfg.InitialSeconds) or 300
    cfg.FuelSecondsPerItem = tonumber(cfg.FuelSecondsPerItem) or 300
    cfg.MaxDistance = tonumber(cfg.MaxDistance) or 3.2
    cfg.WarningSeconds = tonumber(cfg.WarningSeconds) or 60
    return cfg
end

local function runtimeCampfireExists()
    return RDRealCraft.campfireProp and RDRealCraft.campfireProp ~= 0 and DoesEntityExist(RDRealCraft.campfireProp)
end

local function getRuntimeCampfireCoords()
    if runtimeCampfireExists() then
        return GetEntityCoords(RDRealCraft.campfireProp)
    end
    return nil
end

local function getRuntimeCampfireSecondsLeft()
    if not runtimeCampfireExists() then return 0 end
    local left = math.ceil(((tonumber(RDRealCraft.campfireEndsAt) or 0) - GetGameTimer()) / 1000)
    if left < 0 then left = 0 end
    return left
end

local function isNearRuntimeCampfire(maxDist)
    if not runtimeCampfireExists() then return false end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    local fireCoords = GetEntityCoords(RDRealCraft.campfireProp)
    return #(coords - fireCoords) <= (tonumber(maxDist) or tonumber(getRuntimeCampfireConfig().MaxDistance) or 3.2)
end

local function sendRuntimeCampfireState(flash, busy, data, message)
    local exists = runtimeCampfireExists()
    local cfg = getRuntimeCampfireConfig()
    local payload = {
        action = 'rdRealCraftCampfireState',
        active = exists,
        seconds = exists and getRuntimeCampfireSecondsLeft() or 0,
        near = exists and isNearRuntimeCampfire(cfg.MaxDistance) or true,
        flash = flash and true or false,
        busy = busy and true or false,
        message = message or '',
    }
    if data ~= nil then payload.data = data end
    SendNUIMessage(payload)
end

local function deleteRuntimeCampfire(silent)
    if runtimeCampfireExists() then
        deleteEntitySafe(RDRealCraft.campfireProp)
    end
    RDRealCraft.campfireProp = nil
    RDRealCraft.campfireEndsAt = 0
    RDRealCraft.campfireWarningSent = false
    RDRealCraft.campfireAddBusy = false
    if not silent then
        notify('Campfire u fik dhe u zhduk.', 4200, 'error')
    end
    sendRuntimeCampfireState(false, false, RDRealCraft.data)
end

local function startRuntimeCampfireMonitor()
    if RDRealCraft.campfireThread then return end
    RDRealCraft.campfireThread = true
    CreateThread(function()
        while runtimeCampfireExists() do
            local cfg = getRuntimeCampfireConfig()
            local left = getRuntimeCampfireSecondsLeft()
            if left <= 0 then
                deleteRuntimeCampfire(false)
                break
            end
            if not RDRealCraft.campfireWarningSent and left <= (tonumber(cfg.WarningSeconds) or 60) then
                RDRealCraft.campfireWarningSent = true
                notify('Zjarri po shuhet. Shto wood ose hwood që të zgjasë më shumë.', 6500, 'warning')
                sendRuntimeCampfireState(true, false, RDRealCraft.data)
            end
            local coords = getRuntimeCampfireCoords()
            if coords and (Config.RDRealisticCrafting or {}).FireLight ~= false then
                pcall(function()
                    DrawLightWithRange(coords.x, coords.y, coords.z + 0.48, 255, 146, 61, tonumber((Config.RDRealisticCrafting or {}).FireLightRadius) or 7.5, tonumber((Config.RDRealisticCrafting or {}).FireLightIntensity) or 5.0)
                end)
            end
            if RDRealCraft.uiOpen then sendRuntimeCampfireState(false, RDRealCraft.campfireAddBusy, nil) end
            Wait(1000)
        end
        RDRealCraft.campfireThread = false
    end)
end

local function getRuntimeFuelFromData(preferredItem)
    local cfg = getRuntimeCampfireConfig()
    local allowed = cfg.FuelItems or { { name = 'wood', label = 'Wood' }, { name = 'hwood', label = 'Hard Wood' } }
    local counts = (RDRealCraft.data and RDRealCraft.data.counts) or {}
    local camp = (RDRealCraft.data and RDRealCraft.data.campfire) or {}
    local campItems = camp.items or {}

    local function countFor(name)
        name = tostring(name or '')
        local c = tonumber(counts[name])
        if c ~= nil then return c end
        for _, it in ipairs(campItems) do
            if tostring(it.name or '') == name then return tonumber(it.count) or 0 end
        end
        return 0
    end

    preferredItem = tostring(preferredItem or '')
    if preferredItem ~= '' then
        for _, it in ipairs(allowed) do
            local name = tostring(it.name or '')
            if name == preferredItem and countFor(name) > 0 then return name end
        end
    end

    for _, it in ipairs(allowed) do
        local name = tostring(it.name or '')
        if name ~= '' and countFor(name) > 0 then return name end
    end
    return nil
end

local function spawnRuntimeCampfire()
    local cfg = getRuntimeCampfireConfig()
    if cfg.Enabled == false then
        notify('Campfire është i çaktivizuar.', 3000, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsPedDeadOrDying(ped, false) or IsPedInAnyVehicle(ped, false) then
        notify('Nuk mund ta ndezësh campfire tani.', 3200, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end

    if runtimeCampfireExists() then
        if isNearRuntimeCampfire(cfg.MaxDistance) then
            notify('Campfire është ndezur. Shtyp + te wood/hwood për të shtuar dru.', 3600, 'inform')
            sendRuntimeCampfireState(true, false, RDRealCraft.data)
            return
        else
            -- If the old campfire is far away, allow the player to light a new one here.
            -- The old one is removed so every player keeps only one active runtime campfire.
            deleteRuntimeCampfire(true)
            notify('Campfire i vjetër ishte larg, u zhduk. Po ndezim një tjetër këtu.', 4200, 'inform')
        end
    end

    local modelList = cfg.PropModels or ((Config.RDRealisticCrafting or {}).Props or {}).CampfireLarge or ((Config.RDRealisticCrafting or {}).Props or {}).CampfireOnly or { 'p_campfirecombined01x', 'p_campfire03x', 'p_campfire01x', 'p_campfirefresh01x' }
    local hash = requestModelByList(modelList, 1200)
    if not hash then
        notify('Nuk u gjet modeli i campfire.', 3500, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end

    ClearPedTasks(ped)
    pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.25, -0.98)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false, false, true)
    if not obj or obj == 0 then
        SetModelAsNoLongerNeeded(hash)
        notify('Campfire nuk u krijua.', 3500, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end

    pcall(function() SetEntityAsMissionEntity(obj, true, true) end)
    SetEntityHeading(obj, GetEntityHeading(ped))
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)

    RDRealCraft.campfireProp = obj
    RDRealCraft.campfireEndsAt = GetGameTimer() + ((tonumber(cfg.InitialSeconds) or 300) * 1000)
    RDRealCraft.campfireWarningSent = false
    faceCraftStation(ped, GetEntityCoords(obj), 350)
    playLightFireAnim(ped)
    startRuntimeCampfireMonitor()
    notify('Campfire u ndez. Çdo wood/hwood shton 5 minuta. Shto dru ose do fiket.', 6500, 'inform')
    sendRuntimeCampfireState(true, false, RDRealCraft.data)
    TriggerServerEvent('rd_inventory:realCraft:requestData', true)
end

local function requestRuntimeCampfireStart(preferredItem)
    local cfg = getRuntimeCampfireConfig()
    if cfg.Enabled == false then
        notify('Campfire është i çaktivizuar.', 3000, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsPedDeadOrDying(ped, false) or IsPedInAnyVehicle(ped, false) then
        notify('Nuk mund ta ndezësh campfire tani.', 3200, 'error')
        sendRuntimeCampfireState(runtimeCampfireExists(), false, RDRealCraft.data)
        return
    end
    if runtimeCampfireExists() and isNearRuntimeCampfire(cfg.MaxDistance) then
        notify('Campfire është ndezur. Shtyp + te wood/hwood për të shtuar dru.', 3600, 'inform')
        sendRuntimeCampfireState(true, false, RDRealCraft.data)
        return
    end

    local fuelItem = getRuntimeFuelFromData(preferredItem)
    if not fuelItem then
        notify('Duhet të kesh wood ose hwood në inventory për të ndezur campfire.', 4200, 'error')
        sendRuntimeCampfireState(runtimeCampfireExists(), false, RDRealCraft.data)
        return
    end

    RDRealCraft.campfireAddBusy = true
    sendRuntimeCampfireState(runtimeCampfireExists(), true, RDRealCraft.data)
    TriggerServerEvent('rd_inventory:realCraft:campfireStartFuel', fuelItem)
end

local function runtimeFuelLabel(itemName)
    itemName = tostring(itemName or '')
    local cfg = getRuntimeCampfireConfig()
    local items = cfg.FuelItems or { { name = 'wood', label = 'Wood' }, { name = 'hwood', label = 'Hard Wood' } }
    for _, item in ipairs(items) do
        if tostring(item.name or '') == itemName then return tostring(item.label or itemName) end
    end
    return itemName
end

local function createWoodHandProp(ped, itemName)
    local props = (Config.RDRealisticCrafting or {}).Props or {}
    local modelList = props.Wood or { 'p_chopwood01x', 'p_log_01x', 'p_woodpile01x' }
    local hash = requestModelByList(modelList, 900)
    if not hash then return nil end
    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false, false, true)
    if obj and obj ~= 0 then
        local bone = resolveEntityBone(ped, 'SKEL_R_Hand')
        AttachEntityToEntity(obj, ped, bone, 0.06, 0.02, -0.02, -82.0, 8.0, 76.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(hash)
        return obj
    end
    SetModelAsNoLongerNeeded(hash)
    return nil
end

local function playAddWoodToRuntimeCampfire(itemName, amount)
    local cfg = getRuntimeCampfireConfig()
    if cfg.Enabled == false then
        notify('Campfire është i çaktivizuar.', 3000, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
        return
    end
    if RDRealCraft.campfireAddBusy then return end
    if not runtimeCampfireExists() then
        notify('Ndez campfire fillimisht.', 3200, 'error')
        sendRuntimeCampfireState(true, false, RDRealCraft.data)
        return
    end
    if not isNearRuntimeCampfire(cfg.MaxDistance) then
        notify('Duhet të jesh afër campfire për të futur dru.', 3600, 'error')
        sendRuntimeCampfireState(true, false, RDRealCraft.data)
        return
    end

    RDRealCraft.campfireAddBusy = true
    sendRuntimeCampfireState(false, true, RDRealCraft.data)
    itemName = tostring(itemName or 'wood')
    amount = math.max(1, math.min(5, math.floor(tonumber(amount) or 1)))

    CreateThread(function()
        local ped = PlayerPedId()
        local woodProp = nil
        if ped and ped ~= 0 then
            ClearPedTasks(ped)
            pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)
            local fireCoords = getRuntimeCampfireCoords()
            if fireCoords then faceCraftStation(ped, fireCoords, 280) end
            woodProp = createWoodHandProp(ped, itemName)
            local played = startScenarioList(ped, { 'WORLD_HUMAN_CAMP_FIRE', 'WORLD_HUMAN_CROUCH_INSPECT' }, 2100, fireCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                }, 2100, 1)
            end
            Wait(1250)
            deleteEntitySafe(woodProp)
            if RDRealCraft.active and RDRealCraft.uiOpen and runtimeCampfireExists() then
                local fc = getRuntimeCampfireCoords()
                startScenarioList(ped, { 'WORLD_HUMAN_CAMP_FIRE', 'WORLD_HUMAN_CROUCH_INSPECT' }, -1, fc)
            end
        end

        if runtimeCampfireExists() and isNearRuntimeCampfire(cfg.MaxDistance) then
            TriggerServerEvent('rd_inventory:realCraft:campfireAddFuel', itemName, amount)
        else
            RDRealCraft.campfireAddBusy = false
            notify('U largove nga campfire. Dru nuk u shtua.', 3200, 'error')
            sendRuntimeCampfireState(true, false, RDRealCraft.data)
        end

        SetTimeout(6000, function()
            if RDRealCraft.campfireAddBusy then
                RDRealCraft.campfireAddBusy = false
                sendRuntimeCampfireState(false, false, RDRealCraft.data)
            end
        end)
    end)
end

local function playExitAnimation(kind)
    local ped = PlayerPedId()
    kind = lowerText(kind or RDRealCraft.currentRecipeKind or '')
    ClearPedTasks(ped)

    local played = false
    if kind == 'meat' or kind == 'soup' or kind == 'stew' or kind == 'drink' or kind == 'water' or kind == 'coffee' or kind:find('smoke', 1, true) or kind:find('tobacco', 1, true) then
        played = playAnimCandidates(ped, {
            { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, 900, 1)
    elseif kind == 'woodwork' or kind == 'furniture' or kind == 'woodworking' or kind:find('moonshine', 1, true) or kind:find('bandage', 1, true) or kind:find('syringe', 1, true) then
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_hammer@male_a@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, 900, 1)
    else
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, 650, 1)
    end

    if played then Wait(650) end
    ClearPedTasks(ped)
end

local function attachRecipeTool(ped, propKind, attach)
    local props = (Config.RDRealisticCrafting and Config.RDRealisticCrafting.Props) or {}
    local hash = requestModelByList(props[propKind], 900)
    if not hash then return nil end

    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false, false, true)
    if obj and obj ~= 0 then
        attach = attach or {}
        local boneName = attach.bone or 'SKEL_R_Hand'
        local bone = resolveEntityBone(ped, boneName)
        AttachEntityToEntity(
            obj,
            ped,
            bone,
            attach.x or 0.04,
            attach.y or -0.02,
            attach.z or -0.02,
            attach.rx or -70.0,
            attach.ry or 10.0,
            attach.rz or 5.0,
            true,
            true,
            false,
            true,
            1,
            true
        )
        table.insert(RDRealCraft.props, obj)
        RDRealCraft.recipeProps = RDRealCraft.recipeProps or {}
        table.insert(RDRealCraft.recipeProps, obj)
        rememberRecipeHandProp(obj)
        SetModelAsNoLongerNeeded(hash)
        return obj
    end
    SetModelAsNoLongerNeeded(hash)
    return nil
end

local function sendRecipeProgress(pct, text)
    SendNUIMessage({
        action = 'rdRealCraftRecipeProgress',
        pct = math.max(0, math.min(100, tonumber(pct) or 0)),
        text = tostring(text or 'Crafting...')
    })
end

local function runRecipeProgress(duration, text)
    duration = tonumber(duration) or 5200
    local started = GetGameTimer()
    local nextNui = 0
    local nextSfx = 0
    while RDRealCraft.active and RDRealCraft.uiOpen and RDRealCraft.recipeBusy do
        local interrupted, reason = shouldInterruptCraft()
        if interrupted then
            setCraftCanceled(reason)
            break
        end
        local elapsed = GetGameTimer() - started
        local pct = (elapsed / duration) * 100.0
        if GetGameTimer() >= nextNui then
            sendRecipeProgress(pct, text)
            nextNui = GetGameTimer() + 90
        end
        if GetGameTimer() >= nextSfx then
            local kind = lowerText(RDRealCraft.currentRecipeKind)
            if kind == 'woodwork' or kind == 'woodworking' or kind == 'furniture' then
                playCraftSound('WOOD_HIT')
                nextSfx = GetGameTimer() + 1450
            elseif kind == 'gun' or kind == 'weapon' or kind == 'ammo' then
                playCraftSound('METAL_CLANK')
                nextSfx = GetGameTimer() + 1600
            elseif kind == 'meat' or kind == 'soup' or kind == 'drink' or kind == 'food' then
                playCraftSound('FIRE_CRACKLE', RDRealCraft.fireProp)
                nextSfx = GetGameTimer() + 2100
            else
                nextSfx = GetGameTimer() + 2200
            end
        end
        if elapsed >= duration then break end
        Wait(0)
        DisableControlAction(0, `INPUT_ATTACK`, true)
        DisableControlAction(0, `INPUT_AIM`, true)
        DisableControlAction(0, `INPUT_MELEE_ATTACK`, true)
        DisableControlAction(0, `INPUT_JUMP`, true)
        DisableControlAction(0, `INPUT_SPRINT`, true)
    end
    if RDRealCraft.active and RDRealCraft.recipeBusy then
        sendRecipeProgress(100, text)
    end
    return RDRealCraft.active and RDRealCraft.uiOpen and RDRealCraft.recipeBusy
end


local function spawnConfiguredAnimationProp(modelName)
    local hash = requestModelByList(modelName, 900)
    if not hash then return nil end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false, false, true)
    if obj and obj ~= 0 then
        RDRealCraft.recipeProps = RDRealCraft.recipeProps or {}
        table.insert(RDRealCraft.props, obj)
        table.insert(RDRealCraft.recipeProps, obj)
        SetModelAsNoLongerNeeded(hash)
        return obj
    end
    SetModelAsNoLongerNeeded(hash)
    return nil
end

local function attachConfiguredProp(obj, target, boneName, c)
    if not obj or obj == 0 or not target or target == 0 then return end
    c = c or {}
    local bone = 0
    if boneName and boneName ~= '' then
        bone = resolveEntityBone(target, tostring(boneName))
        if not bone or bone < 0 then bone = 0 end
    end
    AttachEntityToEntity(
        obj,
        target,
        bone,
        c.x or 0.0,
        c.y or 0.0,
        c.z or 0.0,
        c.xr or c.rx or 0.0,
        c.yr or c.ry or 0.0,
        c.zr or c.rz or 0.0,
        true,
        true,
        false,
        true,
        1,
        true
    )
end

local function playConfiguredCraftAnimation(ped, animKey, duration, progressText)
    local animations = Config and Config.Animations or {}
    local cfg = animations and animations[animKey]
    if not cfg then return false end

    local function spawnStationEntry(entry)
        if type(entry) ~= 'table' then return nil end
        local kind = entry.kind or entry.propKind or entry.model
        if not kind then return nil end
        local ent, coords = createRecipeProp(
            kind,
            entry.x or 0.0,
            entry.y or 1.05,
            entry.z or -0.98,
            entry.heading or 0.0,
            entry.rotation,
            entry.ground ~= false
        )
        if coords then faceCraftStation(ped, coords, 180) end
        return ent, coords
    end

    if type(cfg.stationProps) == 'table' then
        for _, entry in ipairs(cfg.stationProps) do
            spawnStationEntry(entry)
        end
    end

    if type(cfg.groundProp) == 'table' then
        spawnStationEntry(cfg.groundProp)
    end

    if cfg.prop and cfg.prop.model then
        local mainProp = spawnConfiguredAnimationProp(cfg.prop.model)
        if mainProp then
            attachConfiguredProp(mainProp, ped, cfg.prop.bone or 'SKEL_R_Hand', cfg.prop.coords or {})
            rememberRecipeHandProp(mainProp)
            if type(cfg.prop.subprops) == 'table' then
                for _, sub in ipairs(cfg.prop.subprops) do
                    if sub and sub.model then
                        local subProp = spawnConfiguredAnimationProp(sub.model)
                        if subProp then
                            local target = mainProp
                            local boneName = nil
                            if sub.target == 'ped' or sub.attachTo == 'ped' then
                                target = ped
                                boneName = sub.bone or 'SKEL_L_Hand'
                                rememberRecipeHandProp(subProp)
                            end
                            attachConfiguredProp(subProp, target, boneName, sub.coords or {})
                        end
                    end
                end
            end
        end
    end

    if cfg.type == 'scenario' or cfg.scenario or cfg.scenarios then
        local scenarios = cfg.scenarios or { cfg.scenario }
        local played = startScenarioList(ped, scenarios, duration, nil)
        if not played then
            played = startScenarioList(ped, getFirewoodScenarios(), duration, nil)
        end
        if not played then
            played = playAnimCandidates(ped, getFirewoodFallbackAnimations(), duration, cfg.flag or 1)
        end
        return runRecipeProgress(duration, progressText or 'Duke bërë craft...')
    end

    if not cfg.dict or not cfg.name then
        local fallback = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
        }, duration, cfg.flag or 1)
        if not fallback then tryScenario(ped, 'WORLD_HUMAN_CROUCH_INSPECT', duration) end
        return runRecipeProgress(duration, progressText or 'Duke bërë craft...')
    end

    if not loadAnimDict(cfg.dict, 1000) then
        local fallback = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
            { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
        }, duration, cfg.flag or 1)
        if not fallback then tryScenario(ped, 'WORLD_HUMAN_CROUCH_INSPECT', duration) end
        return runRecipeProgress(duration, progressText or 'Duke bërë craft...')
    end

    TaskPlayAnim(ped, cfg.dict, cfg.name, 3.0, -3.0, duration or -1, cfg.flag or 1, 0.0, false, 0, false, 0, false)
    return runRecipeProgress(duration, progressText or 'Duke bërë craft...')
end


local function playFirewoodRecipe(ped, recipe, duration)
    -- Recipe-level firewood animation: same Spooni-style station used before the craft UI opens.
    local stationCoords = spawnWoodChopStation(ped)
    attachAxe(ped)
    if stationCoords then faceCraftStation(ped, stationCoords, 450) end

    local played = startScenarioList(ped, getFirewoodScenarios(), duration, stationCoords)
    if not played then
        played = playAnimCandidates(ped, getFirewoodFallbackAnimations(), duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_HAMMER_TABLE', duration) end

    CreateThread(function()
        local totalPieces = tonumber(Config.RDRealisticCrafting.ChopClicks) or 5
        local delay = math.max(650, math.floor((tonumber(duration) or 5200) / math.max(totalPieces, 1)))
        for i = 1, totalPieces do
            Wait(delay)
            if RDRealCraft.active and RDRealCraft.recipeBusy then
                spawnSplitWoodPiece(i)
                playCraftSound('WOOD_HIT', RDRealCraft.chopLog)
            else
                break
            end
        end
    end)

    return runRecipeProgress(duration, 'Duke prerë dru...')
end

local function playAmmoRecipe(ped, recipe, duration)
    pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)
    local bench, benchCoords = createRecipeProp('AmmoWorkbench', 0.0, 1.03, -0.98, 0.0, nil, true)
    if not bench then bench, benchCoords = createRecipeProp('GunWorkbench', 0.0, 1.03, -0.98, 0.0, nil, true) end
    if not bench then bench, benchCoords = createRecipeProp('GunBench', 0.0, 1.03, -0.98, 0.0, nil, true) end

    -- Small items on top of/around the bench so ammo crafting does not look empty.
    createRecipeProp('AmmoBox', 0.26, 0.95, -0.85, 20.0, nil, true)
    createRecipeProp('AmmoRound', -0.20, 1.02, -0.84, -18.0, nil, true)
    createRecipeProp('GunPowder', 0.02, 1.14, -0.84, 5.0, nil, true)
    attachRecipeTool(ped, 'GunTool', { bone = 'SKEL_R_Hand', x = 0.04, y = -0.01, z = -0.01, rx = -15.0, ry = 82.0, rz = 12.0 })
    attachRecipeTool(ped, 'AmmoRound', { bone = 'SKEL_L_Hand', x = 0.035, y = 0.015, z = -0.015, rx = 80.0, ry = 0.0, rz = 6.0 })

    if benchCoords then faceCraftStation(ped, benchCoords, 500) end
    playCraftSound('METAL_CLANK', bench)

    -- Force a visible RedM craft loop. Scenario natives can return ok while the ped stays idle on some builds,
    -- so ammo/gunsmith craft now drives the animation itself and replays it if it drops.
    local played = playLoopedCraftAnim(ped, {
        { dict = 'mech_inventory@crafting@fallbacks', anim = 'full_craft_and_stow' },
        { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
        { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
        { dict = 'amb_work@world_human_hammer@male_a@idle_a', anim = 'idle_a' },
    }, duration, 17, 2800)
    if not played then
        tryScenario(ped, 'WORLD_HUMAN_HAMMER_TABLE', duration)
    end
    return runRecipeProgress(duration, 'Ammo bench: duke mbushur fishekët...')
end

local function playGunRecipe(ped, recipe, duration)
    pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)
    local bench, benchCoords = createRecipeProp('GunWorkbench', 0.0, 1.04, -0.98, 0.0, nil, true)
    if not bench then bench, benchCoords = createRecipeProp('GunBench', 0.0, 1.04, -0.98, 0.0, nil, true) end
    createRecipeProp('GunParts', 0.18, 1.0, -0.84, 25.0, nil, true)
    createRecipeProp('GunParts', -0.22, 1.04, -0.84, -18.0, nil, true)
    attachRecipeTool(ped, 'GunTool', { bone = 'SKEL_R_Hand', x = 0.03, y = -0.01, z = -0.01, rx = -10.0, ry = 80.0, rz = 10.0 })
    if benchCoords then faceCraftStation(ped, benchCoords, 500) end
    playCraftSound('WOOD_HIT', bench)

    -- Force a visible gunsmith work loop instead of trusting scenarios that may silently fail.
    local played = playLoopedCraftAnim(ped, {
        { dict = 'mech_inventory@crafting@fallbacks', anim = 'full_craft_and_stow' },
        { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
        { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
        { dict = 'amb_work@world_human_repair@male_a@idle_a', anim = 'idle_a' },
    }, duration, 17, 3000)
    if not played then
        tryScenario(ped, 'WORLD_HUMAN_HAMMER_TABLE', duration)
    end
    return runRecipeProgress(duration, 'Gunsmith table: duke ndërtuar armën...')
end
local function playMeatRecipe(ped, recipe, duration)
    local fireCoords = ensureRecipeFire(1.18)
    if fireCoords then faceCraftStation(ped, fireCoords, 450) end
    createRecipeProp('Meat', 0.14, 1.08, -0.86, 18.0, nil, true)

    if playConfiguredCraftAnimation(ped, 'knifecooking', duration, 'Duke pjekur mishin...') then return true end
    attachRecipeTool(ped, 'Knife', { bone = 'SKEL_R_Hand', x = 0.035, y = 0.025, z = -0.018, rx = -96.0, ry = 6.0, rz = 84.0 })

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CAMP_FIRE_COOKING',
        'WORLD_HUMAN_CAMP_FIRE',
        'WORLD_HUMAN_CROUCH_INSPECT',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_camp@world_camp_fire@male_a@base', anim = 'base' },
            { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_CAMP_FIRE', duration) end
    return runRecipeProgress(duration, 'Duke pjekur mishin...')
end

local function playSoupRecipe(ped, recipe, duration)
    local fireCoords = ensureRecipeFire(1.20)
    local pot, potCoords = createRecipeProp('StewPot', 0.0, 1.05, -0.78, 0.0, nil, true)
    if not pot then pot, potCoords = createRecipeProp('SoupPot', 0.0, 1.05, -0.78, 0.0, nil, true) end
    createRecipeProp('Kettle', 0.22, 1.02, -0.90, 20.0, nil, true)
    if potCoords then faceCraftStation(ped, potCoords, 450) elseif fireCoords then faceCraftStation(ped, fireCoords, 450) end

    if playConfiguredCraftAnimation(ped, 'stirpot', duration, 'Duke zier supën...') then return true end
    attachRecipeTool(ped, 'Spoon', { bone = 'SKEL_R_Hand', x = 0.045, y = 0.030, z = -0.018, rx = -72.0, ry = 12.0, rz = 78.0 })

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CAMP_FIRE_COOKING',
        'WORLD_HUMAN_CAMP_FIRE',
        'WORLD_HUMAN_CROUCH_INSPECT',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_camp@world_camp_fire@male_a@base', anim = 'base' },
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_CAMP_FIRE', duration) end
    return runRecipeProgress(duration, 'Duke zier supën...')
end

local function playFoodRecipe(ped, recipe, duration)
    local fireCoords = ensureRecipeFire(1.18)
    local plate, plateCoords = createRecipeProp('FoodPrep', 0.0, 1.0, -0.90, 0.0, nil, true)
    if plateCoords then faceCraftStation(ped, plateCoords, 450) elseif fireCoords then faceCraftStation(ped, fireCoords, 450) end

    if playConfiguredCraftAnimation(ped, 'knifecooking', duration, 'Duke përgatitur ushqimin...') then return true end
    attachRecipeTool(ped, 'Knife', { bone = 'SKEL_R_Hand', x = 0.035, y = 0.025, z = -0.018, rx = -96.0, ry = 6.0, rz = 84.0 })

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CAMP_FIRE_COOKING',
        'WORLD_HUMAN_CROUCH_INSPECT',
        'WORLD_HUMAN_WRITE_NOTEBOOK',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
            { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_CROUCH_INSPECT', duration) end
    return runRecipeProgress(duration, 'Duke përgatitur ushqimin...')
end

local function playDrinkRecipe(ped, recipe, duration)
    local fireCoords = ensureRecipeFire(1.20)
    local kettle, kettleCoords = createRecipeProp('Kettle', 0.0, 1.05, -0.86, 0.0, nil, true)
    createRecipeProp('Cup', 0.22, 1.0, -0.91, 0.0, nil, true)
    if kettleCoords then faceCraftStation(ped, kettleCoords, 450) elseif fireCoords then faceCraftStation(ped, fireCoords, 450) end

    if playConfiguredCraftAnimation(ped, 'stirpot', duration, 'Duke zier pijen...') then return true end
    attachRecipeTool(ped, 'Bottle', { bone = 'SKEL_L_Hand', x = 0.035, y = 0.025, z = -0.012, rx = 78.0, ry = 8.0, rz = -18.0 })

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CAMP_FIRE_COOKING',
        'WORLD_HUMAN_CAMP_FIRE',
        'WORLD_HUMAN_CROUCH_INSPECT',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_camp@world_camp_fire@male_a@base', anim = 'base' },
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_CAMP_FIRE', duration) end
    return runRecipeProgress(duration, 'Duke zier pijen...')
end

local function playWoodworkRecipe(ped, recipe, duration)
    local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
    createRecipeProp('CarpenterTools', 0.20, 1.02, -0.82, 25.0, nil, true)
    createRecipeProp('ChairPart', -0.25, 1.08, -0.92, -20.0, nil, true)
    attachRecipeTool(ped, 'CarpenterTools', { bone = 'SKEL_R_Hand', x = 0.035, y = 0.020, z = -0.020, rx = -92.0, ry = 4.0, rz = 82.0 })
    if tableCoords then faceCraftStation(ped, tableCoords, 450) end
    playCraftSound('WOOD_HIT', tableObj)

    if playConfiguredCraftAnimation(ped, 'craft', duration, 'Duke punuar drurin...') then return true end

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_HAMMER_TABLE',
        'WORLD_HUMAN_CARPENTER',
        'WORLD_HUMAN_WRITE_NOTEBOOK',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
            { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_HAMMER_TABLE', duration) end
    return runRecipeProgress(duration, 'Duke punuar drurin...')
end

local function playForageRecipe(ped, recipe, duration)
    local pouch, pouchCoords = createRecipeProp('ForagePouch', 0.0, 0.82, -0.96, 0.0, nil, true)
    createRecipeProp('SortingItems', 0.18, 0.90, -0.92, 18.0, nil, true)
    if pouchCoords then faceCraftStation(ped, pouchCoords, 450) end

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CROUCH_INSPECT',
        'WORLD_HUMAN_PICKUP_WEAPON',
        'WORLD_HUMAN_WRITE_NOTEBOOK',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
        }, duration, 1)
    end
    if not played then tryScenario(ped, 'WORLD_HUMAN_CROUCH_INSPECT', duration) end
    return runRecipeProgress(duration, 'Duke perpunuar materialet...')
end

local function playGenericRecipe(ped, recipe, duration)
    if playConfiguredCraftAnimation(ped, 'craft', duration, 'Duke bërë craft...') then return true end

    local played = startScenarioList(ped, {
        'WORLD_HUMAN_CROUCH_INSPECT',
        'WORLD_HUMAN_WRITE_NOTEBOOK',
        'WORLD_HUMAN_HAMMER_TABLE',
    }, duration, nil)
    if not played then
        played = playAnimCandidates(ped, {
            { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
            { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
        }, duration, 1)
    end
    return runRecipeProgress(duration, 'Duke bërë craft...')
end

local function playRecipeAnimation(recipe)
    recipe = recipe or {}
    local ped = PlayerPedId()
    local duration = tonumber(recipe.craftTime) or tonumber((Config.RDRealisticCrafting or {}).CraftDuration) or 5200
    local kind = inferRecipeAnimation(recipe)
    RDRealCraft.currentRecipeKind = kind

    cleanupRecipeProps()
    ClearPedTasks(ped)
    pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)

    local explicitAnimKey = lowerText(recipe.animKey or recipe.animationName or recipe.animationKey or recipe.animation or recipe.anim or recipe.craftAnim)
    if explicitAnimKey == 'firewood' or explicitAnimKey == 'spooni_firewood' or explicitAnimKey == 'chop_firewood' or explicitAnimKey == 'chopwood' then
        return playFirewoodRecipe(ped, recipe, duration)
    end
    if explicitAnimKey ~= '' and Config and Config.Animations and Config.Animations[explicitAnimKey] then
        return playConfiguredCraftAnimation(ped, explicitAnimKey, duration, 'Duke bërë craft...')
    end

    if kind == 'firewood' or kind == 'chop_firewood' or kind == 'spooni_firewood' or kind == 'chopwood' or kind == 'woodcut' or kind == 'wood' then
        return playFirewoodRecipe(ped, recipe, duration)
    elseif kind == 'ammo' or recipe.isAmmo == true or lowerText(recipe.category) == 'ammo' then
        return playAmmoRecipe(ped, recipe, duration)
    elseif kind == 'gun' or kind == 'guns' or kind == 'weapon' then
        return playGunRecipe(ped, recipe, duration)
    elseif kind == 'woodwork' or kind == 'woodworking' or kind == 'furniture' or kind == 'carpenter' then
        return playWoodworkRecipe(ped, recipe, duration)
    elseif kind == 'meat' or kind == 'cook_meat' or kind == 'cooked_meat' then
        return playMeatRecipe(ped, recipe, duration)
    elseif kind == 'soup' or kind == 'stew' or kind == 'broth' then
        return playSoupRecipe(ped, recipe, duration)
    elseif kind == 'forage' or kind == 'processing' or kind == 'process' then
        return playForageRecipe(ped, recipe, duration)
    elseif kind == 'food' or kind == 'meal' or kind == 'cook' then
        return playFoodRecipe(ped, recipe, duration)
    elseif kind == 'drink' or kind == 'water' or kind == 'coffee' or kind == 'boil' then
        return playDrinkRecipe(ped, recipe, duration)
    end
    return playGenericRecipe(ped, recipe, duration)
end



local function playCategorySetupAnimation(ped, category, token)
    -- Before any category prop spawns, the ped does a small setup/build animation.
    -- This makes the campfire/bench/table appear after player action, not suddenly.
    category = tostring(category or ''):lower()
    if category == '' or category == 'all' or category == 'none' or category == 'scoreboard' or category == 'leaderboard' then
        return true
    end

    local animDict = 'mini_games@story@beechers@build_floor@john'
    local animName = 'hammer_loop_good'
    local pedNow = ped or PlayerPedId()
    if pedNow and pedNow ~= 0 and loadAnimDict(animDict, 900) then
        ClearPedTasks(pedNow)
        local hammer = attachRecipeTool(pedNow, 'CarpenterTools', { bone = 'SKEL_R_Hand', x = 0.035, y = 0.020, z = -0.020, rx = -92.0, ry = 4.0, rz = 82.0 })
        TaskPlayAnim(pedNow, animDict, animName, 3.0, -3.0, 1050, 1, 0.0, false, 0, false, 0, false)
        local untilTime = GetGameTimer() + 720
        while GetGameTimer() < untilTime do
            if not RDRealCraft.active or not RDRealCraft.uiOpen or RDRealCraft.recipeBusy or token ~= RDRealCraft.categoryToken then
                deleteEntitySafe(hammer)
                return false
            end
            Wait(0)
        end
        deleteEntitySafe(hammer)
        ClearPedTasks(pedNow)
        return true
    end

    Wait(350)
    return RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy and token == RDRealCraft.categoryToken
end

local function playShortCraftGesture(ped, kind)
    kind = tostring(kind or 'wave')
    ClearPedSecondaryTask(ped)
    local candidates = {
        { dict = 'script_common@gestures@unarmed', anim = 'gesture_hello' },
        { dict = 'script_common@gestures@unarmed', anim = 'gesture_nod_yes' },
        { dict = 'amb_misc@world_human_stand_waiting@male_a@idle_a', anim = 'idle_a' },
    }
    if kind == 'thumbs' then
        candidates = {
            { dict = 'script_common@gestures@unarmed', anim = 'gesture_thumbs_up' },
            { dict = 'script_common@gestures@unarmed', anim = 'gesture_nod_yes' },
            { dict = 'amb_misc@world_human_stand_waiting@male_a@idle_a', anim = 'idle_a' },
        }
    end
    for _, a in ipairs(candidates) do
        if loadAnimDict(a.dict, 450) then
            TaskPlayAnim(ped, a.dict, a.anim, 2.2, -2.2, 1250, 1, 0.0, false, 0, false, 0, false)
            return true
        end
    end
    if kind == 'thumbs' then
        return tryScenario(ped, 'WORLD_HUMAN_CHEER', 1250)
    end
    return tryScenario(ped, 'WORLD_HUMAN_STARE_STOIC', 1250)
end

local function playIdleSelectAnimation(category)
    local ped = PlayerPedId()
    category = tostring(category or 'all'):lower()
    local token = RDRealCraft.categoryToken or 0
    if not RDRealCraft.active or not RDRealCraft.uiOpen or RDRealCraft.recipeBusy then return end

    -- Full old-station cleanup on every category/subcategory click, including stale campfire + FX.
    cleanupRecipeStation()
    ClearPedTasks(ped)

    -- Do NOT spawn any table/fire/bench on initial open or when the ALL tab is selected.
    -- Props appear only after the player chooses a real category like FOOD, DRINKS, TOOLS, GUNS, AMMO, or FURNITURE.
    if category == '' or category == 'all' or category == 'none' then
        return
    end

    if not playCategorySetupAnimation(ped, category, token) then return end
    if not RDRealCraft.active or not RDRealCraft.uiOpen or RDRealCraft.recipeBusy or token ~= RDRealCraft.categoryToken then return end

    if category == 'scoreboard' or category == 'leaderboard' then
        -- Scoreboard is only a UI category: no work props, no heavy animation.
        playShortCraftGesture(ped, 'wave')
        Wait(650)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            startScenarioList(ped, { 'WORLD_HUMAN_WRITE_NOTEBOOK', 'WORLD_HUMAN_STARE_STOIC' }, -1, nil)
        end
        return
    end

    if category == 'smoking' or category == 'smoke' or category == 'tobacco' then
        local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
        createRecipeProp('TobaccoPouch', -0.22, 1.02, -0.84, -18.0, nil, true)
        createRecipeProp('SmokePipe', 0.20, 1.00, -0.84, 22.0, nil, true)
        attachRecipeTool(ped, 'Cigarette', { bone = 'SKEL_R_Finger11', x = 0.030, y = 0.012, z = -0.008, rx = 18.0, ry = 2.0, rz = 84.0 })
        if tableCoords then faceCraftStation(ped, tableCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(760)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_SMOKE', 'WORLD_HUMAN_SMOKE_CIGAR', 'WORLD_HUMAN_WRITE_NOTEBOOK' }, -1, tableCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_rest@world_human_smoke@male_a@idle_a', anim = 'idle_a' },
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'medical' or category == 'medicine' or category == 'medic' then
        local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
        createRecipeProp('MedicalBag', -0.22, 1.02, -0.84, -18.0, nil, true)
        createRecipeProp('Bandage', 0.14, 1.00, -0.82, 12.0, nil, true)
        createRecipeProp('Syringe', 0.30, 1.02, -0.82, 30.0, nil, true)
        if tableCoords then faceCraftStation(ped, tableCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(760)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_WRITE_NOTEBOOK', 'WORLD_HUMAN_CROUCH_INSPECT' }, -1, tableCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                    { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'moonshine' or category == 'still' or category == 'distillery' then
        local stillObj, stillCoords = createRecipeProp('MoonshineStill', 0.0, 1.10, -0.98, 0.0, nil, true)
        createRecipeProp('StillBoiler', 0.28, 1.00, -0.84, 20.0, nil, true)
        createRecipeProp('StillCondenser', -0.28, 1.00, -0.84, -20.0, nil, true)
        createRecipeProp('StillBarrel', 0.0, 1.38, -0.98, 0.0, nil, true)
        attachRecipeTool(ped, 'RepairKit', { bone = 'SKEL_R_Hand', x = 0.04, y = -0.02, z = -0.02, rx = -70.0, ry = 10.0, rz = 5.0 })
        if stillCoords then faceCraftStation(ped, stillCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(800)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_HAMMER_TABLE', 'WORLD_HUMAN_REPAIR_WEAPON', 'WORLD_HUMAN_CROUCH_INSPECT' }, -1, stillCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
                    { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'weapons' or category == 'weapon' or category == 'guns' or category == 'ammo' then
        local bench, benchCoords = createRecipeProp('GunWorkbench', 0.0, 1.04, -0.98, 0.0, nil, true)
        if not bench then bench, benchCoords = createRecipeProp('GunBench', 0.0, 1.04, -0.98, 0.0, nil, true) end
        createRecipeProp('GunParts', 0.22, 1.0, -0.84, 25.0, nil, true)
        createRecipeProp('GunTool', -0.18, 1.06, -0.84, -20.0, nil, true)
        if benchCoords then faceCraftStation(ped, benchCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(850)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, {
                'WORLD_HUMAN_HAMMER_TABLE',
                'WORLD_HUMAN_CLEAN_GUN',
                'WORLD_HUMAN_REPAIR_WEAPON',
                'WORLD_HUMAN_WRITE_NOTEBOOK',
            }, -1, benchCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
                    { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'food' or category == 'cook' or category == 'cooking' then
        local fireCoords = ensureRecipeFire(1.18)
        local plate, plateCoords = createRecipeProp('FoodPrep', 0.0, 1.0, -0.90, 0.0, nil, true)
        createRecipeProp('StewPot', 0.22, 1.04, -0.88, 18.0, nil, true)
        attachRecipeTool(ped, 'Knife', { bone = 'SKEL_R_Hand', x = 0.035, y = 0.025, z = -0.018, rx = -96.0, ry = 6.0, rz = 84.0 })
        if plateCoords then faceCraftStation(ped, plateCoords, 400) elseif fireCoords then faceCraftStation(ped, fireCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(780)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_CAMP_FIRE_COOKING', 'WORLD_HUMAN_CAMP_FIRE', 'WORLD_HUMAN_CROUCH_INSPECT', 'WORLD_HUMAN_WRITE_NOTEBOOK' }, -1, fireCoords or plateCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                    { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'drinks' or category == 'drink' or category == 'water' then
        local fireCoords = ensureRecipeFire(1.20)
        local kettle, kettleCoords = createRecipeProp('Kettle', 0.0, 1.04, -0.86, 0.0, nil, true)
        createRecipeProp('Cup', 0.22, 1.0, -0.91, 0.0, nil, true)
        attachRecipeTool(ped, 'Bottle', { bone = 'SKEL_L_Hand', x = 0.035, y = 0.025, z = -0.012, rx = 78.0, ry = 8.0, rz = -18.0 })
        if kettleCoords then faceCraftStation(ped, kettleCoords, 400) elseif fireCoords then faceCraftStation(ped, fireCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(780)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_CAMP_FIRE_COOKING', 'WORLD_HUMAN_CAMP_FIRE', 'WORLD_HUMAN_CROUCH_INSPECT' }, -1, fireCoords or kettleCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_camp@world_camp_fire@male_a@idle_a', anim = 'idle_a' },
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'furniture' or category == 'woodwork' or category == 'woodworking' then
        local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
        createRecipeProp('CarpenterTools', 0.20, 1.02, -0.82, 25.0, nil, true)
        createRecipeProp('ChairPart', -0.25, 1.08, -0.92, -20.0, nil, true)
        if tableCoords then faceCraftStation(ped, tableCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(780)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_HAMMER_TABLE', 'WORLD_HUMAN_CARPENTER', 'WORLD_HUMAN_WRITE_NOTEBOOK' }, -1, tableCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
                    { dict = 'amb_work@world_human_repair@male_a@base', anim = 'base' },
                }, -1, 1)
            end
        end
        return
    end

    if category == 'survival' or category == 'tools' or category == 'tool' then
        local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
        createRecipeProp('CarpenterTools', 0.20, 1.02, -0.82, 25.0, nil, true)
        createRecipeProp('ForagePouch', -0.22, 1.03, -0.92, -15.0, nil, true)
        if tableCoords then faceCraftStation(ped, tableCoords, 400) end
        playShortCraftGesture(ped, 'thumbs')
        Wait(750)
        if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
            local played = startScenarioList(ped, { 'WORLD_HUMAN_HAMMER_TABLE', 'WORLD_HUMAN_CROUCH_INSPECT', 'WORLD_HUMAN_WRITE_NOTEBOOK' }, -1, tableCoords)
            if not played then
                playAnimCandidates(ped, {
                    { dict = 'amb_work@world_human_hammer@male_a@base', anim = 'base' },
                    { dict = 'amb_work@world_human_crouch_inspect@male_c@idle_a', anim = 'idle_a' },
                }, -1, 1)
            end
        end
        return
    end

    -- ALL/default uses a clean generic craft table instead of leaving the player doing nothing.
    local tableObj, tableCoords = createRecipeProp('WorkTable', 0.0, 1.05, -0.98, 0.0, nil, true)
    createRecipeProp('SortingItems', 0.20, 1.02, -0.88, 15.0, nil, true)
    if tableCoords then faceCraftStation(ped, tableCoords, 400) end
    playShortCraftGesture(ped, 'wave')
    Wait(700)
    if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
        startScenarioList(ped, { 'WORLD_HUMAN_WRITE_NOTEBOOK', 'WORLD_HUMAN_CROUCH_INSPECT', 'WORLD_HUMAN_STARE_STOIC' }, -1, tableCoords)
    end
end

local function setCraftUiCategory(category)
    RDRealCraft.currentCategory = tostring(category or 'all'):lower()
    RDRealCraft.categoryToken = (RDRealCraft.categoryToken or 0) + 1
    local tokenCategory = RDRealCraft.currentCategory
    CreateThread(function()
        playIdleSelectAnimation(tokenCategory)
    end)
end

local function beginRecipeCraftFromNui(recipeIndex)
    if RDRealCraft.recipeBusy then return end
    if not RDRealCraft.active or not RDRealCraft.uiOpen then return end

    local idx = tonumber(recipeIndex) or 0
    local recipes = RDRealCraft.data and RDRealCraft.data.recipes or {}
    local recipe = recipes[idx + 1]
    if not recipe then
        notify('Recipe nuk ekziston.', 2500)
        SendNUIMessage({ action = 'rdRealCraftResult', ok = false, message = 'Recipe nuk ekziston.', data = RDRealCraft.data or {} })
        return
    end
    if recipe.canCraft == false then
        notify('Nuk ke materialet e duhura.', 2500)
        SendNUIMessage({ action = 'rdRealCraftResult', ok = false, message = 'Nuk ke materialet e duhura.', data = RDRealCraft.data or {} })
        return
    end

    RDRealCraft.recipeBusy = true
    RDRealCraft.categoryToken = (RDRealCraft.categoryToken or 0) + 1 -- cancel any delayed category prop spawn
    cleanupRecipeStation() -- remove category preview props before spawning the real recipe scene
    ClearPedTasks(PlayerPedId())
    markCraftOrigin()
    TriggerServerEvent('rd_inventory:realCraft:prepare', idx)
    notify('Po përgatitet craft: '..tostring(recipe.label or 'Recipe'), 1800, 'inform')
    sendRecipeProgress(0, 'Duke u përgatitur...')
    startCraftCamera(recipe)

    CreateThread(function()
        local ok = playRecipeAnimation(recipe)
        playExitAnimation(RDRealCraft.currentRecipeKind)
        stopCraftCamera()
        -- Keep the world craft station visible after success; only remove hand-held tools.
        -- Full scene props are cleared when the UI closes, craft cancels, or category changes.
        cleanupRecipeHandProps()
        ClearPedTasks(PlayerPedId())

        if ok and RDRealCraft.active and RDRealCraft.uiOpen then
            sendRecipeProgress(100, 'Duke marrë item...')
            TriggerServerEvent('rd_inventory:realCraft:execute', idx)
        else
            RDRealCraft.recipeBusy = false
            sendRecipeProgress(0, 'Craft u anulua')
            local msg = RDRealCraft.cancelReason or 'Craft u anulua.'
            SendNUIMessage({ action = 'rdRealCraftResult', ok = false, message = msg, data = RDRealCraft.data or {} })
            notify(msg, 3000)
            RDRealCraft.uiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'rdRealCraftClose' })
            cleanupScene(false)
            TriggerEvent('vorp_inventory:blockInventory', false)
        end
    end)
end

local function disableCraftControls()
    DisableControlAction(0, `INPUT_ATTACK`, true)
    DisableControlAction(0, `INPUT_AIM`, true)
    DisableControlAction(0, `INPUT_MELEE_ATTACK`, true)
    DisableControlAction(0, `INPUT_CONTEXT`, true) -- block E during chop; LEFT CLICK is used
    DisableControlAction(0, `INPUT_JUMP`, true)
    DisableControlAction(0, `INPUT_SPRINT`, true)
end

local function openCraftNui()
    RDRealCraft.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'rdRealCraftOpenLoading' })
    if runtimeCampfireExists() then
        sendRuntimeCampfireState(false, false, nil)
    end
    TriggerServerEvent('rd_inventory:realCraft:requestData')
    if not RDRealCraft.refreshThread then
        RDRealCraft.refreshThread = true
        CreateThread(function()
            while RDRealCraft.active and RDRealCraft.uiOpen do
                Wait(tonumber((Config.RDRealisticCrafting or {}).InventoryRefreshMs) or 1200)
                if RDRealCraft.active and RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
                    local interrupted, reason = shouldInterruptCraft()
                    if interrupted then
                        setCraftCanceled(reason)
                        notify(reason, 3000)
                        RDRealCraft.uiOpen = false
                        SetNuiFocus(false, false)
                        SendNUIMessage({ action = 'rdRealCraftClose' })
                        cleanupScene(false)
                        TriggerEvent('vorp_inventory:blockInventory', false)
                        break
                    end
                    TriggerServerEvent('rd_inventory:realCraft:requestData', true)
                end
            end
            RDRealCraft.refreshThread = false
        end)
    end
end

local function beginRealisticCrafting()
    if RDRealCraft.active then return end
    if not Config.RDRealisticCrafting or Config.RDRealisticCrafting.Enabled == false then
        notify('Craft është i çaktivizuar.', 2500)
        return
    end

    -- Craft UI must always open, even if an active campfire is far away.
    -- Distance is checked only when adding wood/hwood to the fire.

    RDRealCraft.active = true
    RDRealCraft.intro = false
    RDRealCraft.uiOpen = false
    RDRealCraft.recipeBusy = false
    RDRealCraft.currentCategory = 'all'
    RDRealCraft.categoryToken = (RDRealCraft.categoryToken or 0) + 1
    markCraftOrigin()
    TriggerEvent('vorp_inventory:blockInventory', true)

    if InInventory and NUIService and NUIService.CloseInv then
        NUIService.CloseInv()
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'hide' })
    end

    CreateThread(function()
        Wait(250)
        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped, false) or IsPedInAnyVehicle(ped, false) then
            notify('Nuk mund të bësh craft tani.', 3000)
            RDRealCraft.active = false
            TriggerEvent('vorp_inventory:blockInventory', false)
            sendPrompt(false)
            return
        end

        ClearPedTasks(ped)
        pcall(function() SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true) end)
        -- Open NUI immediately for performance; props/idle animation start after UI is visible.
        notify('Craft UI u hap. Zgjidh category/weapon subcategory.', 1800)
        openCraftNui()
        -- No default prop/idle scene here. The player must click a category first.
    end)
end

RegisterNUICallback('rdRealCraftStart', function(_, cb)
    if cb then cb('ok') end
    beginRealisticCrafting()
end)

RegisterNUICallback('rdRealCraftRequestData', function(_, cb)
    if cb then cb('ok') end
    TriggerServerEvent('rd_inventory:realCraft:requestData')
end)

RegisterNUICallback('rdRealCraftBeginRecipe', function(data, cb)
    if cb then cb('ok') end
    beginRecipeCraftFromNui(tonumber(data and data.recipeIndex) or 0)
end)

RegisterNUICallback('rdRealCraftCampfireCreate', function(data, cb)
    if cb then cb('ok') end
    requestRuntimeCampfireStart(data and data.item or nil)
end)

RegisterNUICallback('rdRealCraftCampfireAddFuel', function(data, cb)
    if cb then cb('ok') end
    playAddWoodToRuntimeCampfire((data and data.item) or 'wood', tonumber(data and data.amount) or 1)
end)

-- Kept for compatibility with older NUI calls. It now plays the real recipe animation first,
-- then calls the original server craft event only after the animation finishes.
RegisterNUICallback('rdRealCraftExecute', function(data, cb)
    if cb then cb('ok') end
    beginRecipeCraftFromNui(tonumber(data and data.recipeIndex) or 0)
end)

RegisterNUICallback('rdRealCraftCategory', function(data, cb)
    if cb then cb('ok') end
    setCraftUiCategory(data and data.category or 'all')
end)

RegisterNUICallback('rdRealCraftNotify', function(data, cb)
    if cb then cb('ok') end
    notify(tostring((data and data.message) or 'Ju lutem kliko materialet poshtë.'), tonumber(data and data.ms) or 2600)
end)

RegisterNUICallback('rdRealCraftClose', function(_, cb)
    if cb then cb('ok') end
    setCraftCanceled('Craft u anulua.')
    RDRealCraft.intro = false
    RDRealCraft.uiOpen = false
    RDRealCraft.recipeBusy = false
    sendPrompt(false)
    SendNUIMessage({ action = 'rdRealCraftClose' })
    SetNuiFocus(false, false)
    playExitAnimation(RDRealCraft.currentRecipeKind)
    cleanupRecipeProps()
    cleanupScene(Config.RDRealisticCrafting and Config.RDRealisticCrafting.KeepFireAfterClose)
    ClearPedTasks(PlayerPedId())
    TriggerEvent('vorp_inventory:blockInventory', false)
    notify('Craft u anulua.', 1600)
end)

RegisterNetEvent('rd_inventory:realCraft:openData', function(data)
    if not RDRealCraft.active then return end
    RDRealCraft.data = data or {}
    RDRealCraft.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'rdRealCraftOpen', data = data or {} })
end)

RegisterNetEvent('rd_inventory:realCraft:updateData', function(data)
    if not RDRealCraft.uiOpen then return end
    RDRealCraft.data = data or RDRealCraft.data or {}
    SendNUIMessage({ action = 'rdRealCraftUpdate', data = data or {} })
end)

RegisterNetEvent('rd_inventory:realCraft:prepared', function(data)
    if data then RDRealCraft.data = data end
    -- Materials are now reserved server-side. Do not refresh the material grid during
    -- the animation, otherwise reserved items look missing even though craft is valid.
    if RDRealCraft.uiOpen and not RDRealCraft.recipeBusy then
        SendNUIMessage({ action = 'rdRealCraftUpdate', data = data or RDRealCraft.data or {} })
    end
end)

RegisterNetEvent('rd_inventory:realCraft:prepareFailed', function(message, data)
    RDRealCraft.recipeBusy = false
    RDRealCraft.active = false
    RDRealCraft.uiOpen = false
    if data then RDRealCraft.data = data end
    stopCraftCamera()
    cleanupRecipeProps()
    cleanupScene(false)
    ClearPedTasks(PlayerPedId())
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'rdRealCraftResult', ok = false, message = message or 'Craft u anulua.', data = data or RDRealCraft.data or {} })
    SendNUIMessage({ action = 'rdRealCraftClose' })
    TriggerEvent('vorp_inventory:blockInventory', false)
    notify(message or 'Craft u anulua.', 3500)
end)

RegisterNetEvent('rd_inventory:realCraft:result', function(ok, message, data)
    RDRealCraft.recipeBusy = false
    if data then RDRealCraft.data = data end
    if not RDRealCraft.uiOpen then return end
    SendNUIMessage({
        action = 'rdRealCraftResult',
        ok = ok and true or false,
        message = message or '',
        data = data or {}
    })
    if message and message ~= '' then notify(message, ok and 2200 or 3500, ok and 'success' or 'error') end
end)

RegisterNetEvent('rd_inventory:realCraft:campfireStartApproved', function(itemName, data)
    RDRealCraft.campfireAddBusy = false
    if data then RDRealCraft.data = data end
    spawnRuntimeCampfire()
end)

RegisterNetEvent('rd_inventory:realCraft:campfireStartFailed', function(message, data)
    RDRealCraft.campfireAddBusy = false
    if data then RDRealCraft.data = data end
    notify(message or 'Campfire nuk u ndez.', 3800, 'error')
    sendRuntimeCampfireState(runtimeCampfireExists(), false, RDRealCraft.data)
end)

RegisterNetEvent('rd_inventory:realCraft:campfireFuelAdded', function(itemName, amount, seconds, data)
    RDRealCraft.campfireAddBusy = false
    if data then RDRealCraft.data = data end
    if runtimeCampfireExists() then
        local now = GetGameTimer()
        local base = math.max(tonumber(RDRealCraft.campfireEndsAt) or 0, now)
        RDRealCraft.campfireEndsAt = base + ((tonumber(seconds) or 300) * 1000)
        RDRealCraft.campfireWarningSent = false
        notify(('U shtua %s. Campfire u zgjat +%s min.'):format(runtimeFuelLabel(itemName), math.floor((tonumber(seconds) or 300) / 60)), 4200, 'success')
        sendRuntimeCampfireState(true, false, RDRealCraft.data)
    else
        notify('Dru u hoq, por campfire nuk është më aktiv.', 3800, 'error')
        sendRuntimeCampfireState(false, false, RDRealCraft.data)
    end
end)

RegisterNetEvent('rd_inventory:realCraft:campfireFuelFailed', function(message, data)
    RDRealCraft.campfireAddBusy = false
    if data then RDRealCraft.data = data end
    notify(message or 'Dru nuk u shtua.', 3800, 'error')
    sendRuntimeCampfireState(true, false, RDRealCraft.data)
end)

AddEventHandler('onClientResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupRecipeProps()
    cleanupScene(false)
    deleteRuntimeCampfire(true)
    sendPrompt(false)
    SetNuiFocus(false, false)
    TriggerEvent('vorp_inventory:blockInventory', false)
end)

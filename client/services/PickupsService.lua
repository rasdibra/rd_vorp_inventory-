local PickupsService = {}
local T <const>      = TranslationInv.Langs[Lang]
local WorldPickups   = {}

local function RDInventoryIsLocalDropSource(data)
	if not data or not data.source then return false end
	return tonumber(data.source) == tonumber(GetPlayerServerId(PlayerId()))
end
local PickUpPrompt   = 0
local group <const>  = GetRandomIntInRange(0, 0xffffff)
local RD_NEXT_GROUND_NUI_UPDATE = 0

local function RDInventoryGroundImageName(pickup)
	if not pickup then return "placeholder" end
	if pickup.isMoney then return "money" end
	if pickup.isGold then return "goldbar" end
	return pickup.name or "placeholder"
end

local function RDInventoryBuildGroundDropList()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local list = {}
	for obj, pickup in pairs(WorldPickups) do
		if pickup and pickup.coords then
			local dist = #(playerCoords - pickup.coords)
			-- Keep the UI panel focused on nearby drops only. Original world prompt remains unchanged.
			if dist <= 4.0 then
				local count = pickup.amount or pickup.count or 1
				local label = pickup.cleanLabel or pickup.label or pickup.name or "Ground Drop"
				list[#list + 1] = {
					label = label,
					name = RDInventoryGroundImageName(pickup),
					item = RDInventoryGroundImageName(pickup),
					count = count,
					limit = -1,
					type = pickup.isMoney and "item_money" or (pickup.isGold and "item_gold" or (pickup.type or "item_standard")),
					group = pickup.type == "item_weapon" and 5 or 1,
					canUse = false,
					canRemove = false,
					metadata = pickup.metadata or {},
					degradation = pickup.degradation,
					uid = pickup.uid,
					obj = obj,
					uuid = pickup.uuid,
					isMoney = pickup.isMoney or false,
					isGold = pickup.isGold or false,
					groundDrop = true,
					distance = dist,
				}
			end
		end
	end
	table.sort(list, function(a, b) return (a.distance or 999.0) < (b.distance or 999.0) end)
	return list
end

function RDInventoryGetGroundDropsForNUI()
	return RDInventoryBuildGroundDropList()
end

function RDInventorySendGroundDropsToNUI()
	local list = RDInventoryBuildGroundDropList()
	SendNUIMessage({ action = "rdGroundDropsUpdate", itemList = list, current = #list, capacity = 25 })
end


-- RD FIX7: pick up from the right-side Ground Drops panel by using the SAME
-- original VORP server events as the world pickup prompt. The panel sometimes
-- sends only obj/uuid, so resolve the real pickup from the original local
-- WorldPickups table before firing the server event.
function RDInventoryTakeGroundDropFromNUI(data)
	data = data or {}
	local obj = data.obj
	if obj ~= nil and WorldPickups[obj] == nil then
		local objNum = tonumber(obj)
		if objNum and WorldPickups[objNum] then
			obj = objNum
		end
	end

	local pickup = obj ~= nil and WorldPickups[obj] or nil
	if not pickup then
		for key, value in pairs(WorldPickups) do
			if (data.uid ~= nil and value.uid == data.uid) or (data.uuid ~= nil and value.uuid == data.uuid) then
				obj = key
				pickup = value
				break
			end
		end
	end

	if not pickup then
		RDInventorySendGroundDropsToNUI()
		return false
	end

	local playerPed = PlayerPedId()
	if pickup.coords then
		local dist = #(GetEntityCoords(playerPed) - pickup.coords)
		if dist > 4.5 then
			RDInventorySendGroundDropsToNUI()
			return false
		end
	end

	if pickup.entityId and pickup.entityId ~= 0 and DoesEntityExist(pickup.entityId) then
		TaskLookAtEntity(playerPed, pickup.entityId, 1000, 2048, 3, 0)
	end

	if pickup.isMoney then
		TriggerServerEvent("vorpinventory:onPickupMoney", { obj = obj, uuid = pickup.uuid or data.uuid, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
	elseif Config.UseGoldItem and pickup.isGold then
		TriggerServerEvent("vorpinventory:onPickupGold", { obj = obj, uuid = pickup.uuid or data.uuid, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
	else
		TriggerServerEvent("vorpinventory:onPickup", { uid = pickup.uid or data.uid, obj = obj, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
	end

	-- Do not delete locally here. The original server event removes the pickup for everyone.
	-- These refreshes only keep the NUI from looking frozen while the server responds.
	SetTimeout(250, RDInventorySendGroundDropsToNUI)
	SetTimeout(700, function()
		if NUIService and NUIService.LoadInv then
			NUIService.LoadInv()
		end
		RDInventorySendGroundDropsToNUI()
		SendNUIMessage({ action = "rdResetValidation" })
	end)
	SetTimeout(1200, function()
		RDInventorySendGroundDropsToNUI()
		SendNUIMessage({ action = "rdResetValidation" })
	end)
	return true
end

function PickupsService.loadModel(model)
	if not IsModelValid(model) then return print(model, "not a valid model") end

	if not HasModelLoaded(model) then
		RequestModel(model, false)
		repeat Wait(0) until HasModelLoaded(model)
	end
end

function PickupsService.getUniqueId()
	local index = GetRandomIntInRange(0, 0xffffff)
	while WorldPickups[index] do
		index = GetRandomIntInRange(0, 0xffffff)
	end
	return index
end

local function createPrompt()
	PickUpPrompt = UiPromptRegisterBegin()
	UiPromptSetControlAction(PickUpPrompt, Config.PickupKey)
	UiPromptSetText(PickUpPrompt, VarString(10, "LITERAL_STRING", T.TakeFromFloor))
	UiPromptSetEnabled(PickUpPrompt, true)
	UiPromptSetVisible(PickUpPrompt, true)
	UiPromptSetHoldMode(PickUpPrompt, 1000)
	UiPromptSetGroup(PickUpPrompt, group, 0)
	UiPromptRegisterEnd(PickUpPrompt)
end

local function getRandomPositionAround(position, radius)
	local angle <const> = math.random() * 2 * math.pi -- Random angle in radians
	local dx = radius * math.cos(angle)
	local dy = radius * math.sin(angle)

	return vector3(position.x + dx, position.y + dy, position.z)
end

local function playAnim(AnimationConfig)
	if not AnimationConfig or not AnimationConfig.Enable then return end

	local playerPed <const> = PlayerPedId()
	local animDict <const> = AnimationConfig.AnimDict

	if not DoesAnimDictExist(animDict) then
		print("Animation dictionary is not exist: " .. animDict)
		return
	end

	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)
		repeat Wait(0) until HasAnimDictLoaded(animDict)
	end

	TaskPlayAnim(playerPed, animDict, AnimationConfig.AnimName, AnimationConfig.Speed or 1.0, AnimationConfig.SpeedMultiplier or 8.0, AnimationConfig.Duration or -1, AnimationConfig.Flag or 1, 0, false, false, false)

	Wait(AnimationConfig.ClearTaskTime or 1200)
	ClearPedTasks(playerPed, true, true)
end


function PickupsService.CreateObject(objectHash, position, itemType)
	if itemType == "item_standard" then
		local model <const> = Config.spawnableProps[objectHash] or Config.spawnableProps.default_box
		PickupsService.loadModel(model)
		local entityHandle <const> = CreateObject(joaat(model), position.x, position.y, position.z - 1, false, false, false, false)
		repeat Wait(0) until DoesEntityExist(entityHandle)

		PlaceObjectOnGroundProperly(entityHandle, false)
		FreezeEntityPosition(entityHandle, true)
		SetPickupLight(entityHandle, true)
		SetEntityCollision(entityHandle, false, true)
		SetModelAsNoLongerNeeded(model)

		return entityHandle
	else
		if not SharedData.Weapons[objectHash] then
			return PickupsService.CreateObject("default_box", position, "item_standard")
		end

		if not Config.UseWeaponModels then
			return PickupsService.CreateObject("default_box", position, "item_standard")
		end

		Citizen.InvokeNative(0x72D4CB5DB927009C, joaat(objectHash), 1, true) -- request weapon asset
		repeat Wait(0) until Citizen.InvokeNative(0xFF07CF465F48B830, joaat(objectHash))
		local object <const> = CreateWeaponObject(joaat(objectHash), 0, position.x, position.y, position.z, true, 1.0)
		repeat Wait(0) until DoesEntityExist(object)
		PlaceObjectOnGroundProperly(object, true)
		SetPickupLight(object, true)
		SetEntityVisible(object, true)
		if Config.weaponAdjustments[objectHash] then
			SetEntityRotation(object, Config.weaponAdjustments[objectHash], 0.0, 0.0, 0, true)
		end

		SetEntityCollision(object, false, false)
		SetEntityInvincible(object, true)
		SetEntityProofs(object, 1, true)
		FreezeEntityPosition(object, true)

		return object
	end
end

function PickupsService.createPickup(name, amount, metadata, weaponId, id, degradation)
	local playerPed <const> = PlayerPedId()
	local coords <const>    = GetEntityCoords(playerPed, true, true)
	local forward <const>   = GetEntityForwardVector(playerPed)
	local position          = vector3(coords.x + forward.x * 1.6, coords.y + forward.y * 1.6, coords.z + forward.z * 1.6)
	position                = getRandomPositionAround(position, 1)
	local index <const>     = PickupsService.getUniqueId()
	local data <const>      = { name = name, obj = index, amount = amount, metadata = metadata, weaponId = weaponId, position = position, id = id, degradation = degradation }
	if weaponId == 1 then
		CreateThread(function() playAnim(Config.Animation.Drop.Item) end)
		TriggerServerEvent("vorpinventory:sharePickupServerItem", data)
	else
		CreateThread(function() playAnim(Config.Animation.Drop.Weapon) end)
		TriggerServerEvent("vorpinventory:sharePickupServerWeapon", data)
	end
	if Config.SFX.ItemDrop then
		SetTimeout(120, function() PlaySoundFrontend("show_info", "Study_Sounds", true, 0) end)
	end
end

RegisterNetEvent("vorpInventory:createPickup", PickupsService.createPickup)

function PickupsService.createMoneyPickup(amount)
	local playerPed <const> = PlayerPedId()
	local coords <const>    = GetEntityCoords(playerPed, true, true)
	local forward <const>   = GetEntityForwardVector(playerPed)
	local position          = vector3(coords.x + forward.x * 1.6, coords.y + forward.y * 1.6, coords.z + forward.z * 1.6)
	position                = getRandomPositionAround(position, 1)
	local handle <const>    = PickupsService.getUniqueId()
	local data <const>      = { handle = handle, amount = amount, position = position }
	CreateThread(function() playAnim(Config.Animation.Drop.Money) end)
	TriggerServerEvent("vorpinventory:shareMoneyPickupServer", data)
	if Config.SFX.MoneyDrop then
		SetTimeout(120, function() PlaySoundFrontend("show_info", "Study_Sounds", true, 0) end)
	end
end

RegisterNetEvent("vorpInventory:createMoneyPickup", PickupsService.createMoneyPickup)

function PickupsService.createGoldPickup(amount)
	if not Config.UseGoldItem then return end

	local playerPed <const> = PlayerPedId()
	local coords <const>    = GetEntityCoords(playerPed, true, true)
	local forward <const>   = GetEntityForwardVector(playerPed)
	local position          = vector3(coords.x + forward.x * 1.6, coords.y + forward.y * 1.6, coords.z + forward.z * 1.6)
	position                = getRandomPositionAround(position, 1)
	local handle <const>    = PickupsService.getUniqueId()
	local data <const>      = { handle = handle, amount = amount, position = position }
	CreateThread(function() playAnim(Config.Animation.Drop.Gold) end)
	TriggerServerEvent("vorpinventory:shareGoldPickupServer", data)
	if Config.SFX.GoldDrop then
		SetTimeout(120, function() PlaySoundFrontend("show_info", "Study_Sounds", true, 0) end)
	end
end

RegisterNetEvent("vorpInventory:createGoldPickup", PickupsService.createGoldPickup)

function PickupsService.sharePickupClient(data, value)
	if value == 1 then
		if WorldPickups[data.obj] then return end
		local id = 1

		if data.type == "item_standard" then
			-- RD STABILITY: this event is broadcast to everyone.
			-- Only the dropper may subtract the item locally; other players only see the ground pickup.
			if RDInventoryIsLocalDropSource(data) then
				local item <const> = UserInventory[data.id]
				if item then
					item:quitCount(data.amount)
					if item:getCount() == 0 then
						UserInventory[data.id] = nil
					end
				end
			end
			id = 2
		end

		local label <const> = Utils.GetLabel(data.name, id, data.metadata)
		if not label then
			print(("label not found for %s %s"):format(data.name, id))
		end
		local pickup <const> = {
			label    = (label or data.name) .. " x " .. tostring(data.amount),
			cleanLabel = label or data.name,
			entityId = 0,
			coords   = data.position,
			uid      = data.uid,
			type     = data.type,
			name     = data.name,
			amount   = data.amount or 1,
			count    = data.amount or 1,
			metadata = data.metadata or {},
			degradation = data.degradation,
		}
		WorldPickups[data.obj] = pickup

		if (data.source == nil) or RDInventoryIsLocalDropSource(data) then
			NUIService.LoadInv()
			SendNUIMessage({ action = "rdResetValidation" })
		end
		SetTimeout(150, RDInventorySendGroundDropsToNUI)
	elseif value == 3 then
		local pickup = WorldPickups[data.obj]
		if pickup then
			local amount = data.amount or pickup.amount or 1
			pickup.amount = amount
			pickup.count = amount
			if data.metadata ~= nil then pickup.metadata = data.metadata end
			if data.degradation ~= nil then pickup.degradation = data.degradation end
			local label = pickup.cleanLabel or data.label or data.name or "Ground Drop"
			pickup.label = label .. " x " .. tostring(amount)
			if RDInventoryIsLocalDropSource(data) and NUIService and NUIService.LoadInv then
				NUIService.LoadInv()
				SendNUIMessage({ action = "rdResetValidation" })
			end
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	else
		local pickup <const> = WorldPickups[data.obj]
		if pickup then
			if pickup.entityId and DoesEntityExist(pickup.entityId) then
				DeleteEntity(pickup.entityId)
			end
			WorldPickups[data.obj] = nil
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	end
end

RegisterNetEvent("vorpInventory:sharePickupClient", PickupsService.sharePickupClient)

function PickupsService.shareMoneyPickupClient(handle, amount, position, uuid, value)
	if value == 1 then
		if WorldPickups[handle] == nil then
			local pickup <const> = {
				label = T.money .. " (" .. tostring(amount) .. ")",
				cleanLabel = T.money,
				entityId = 0,
				amount = amount,
				count = amount,
				isMoney = true,
				isGold = false,
				coords = position,
				uuid = uuid,
				type = "item_standard",
				name = "money"
			}
			WorldPickups[handle] = pickup
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	elseif value == 3 then
		local pickup = WorldPickups[handle]
		if pickup then
			pickup.amount = amount or pickup.amount or 1
			pickup.count = pickup.amount
			pickup.label = (pickup.cleanLabel or T.money) .. " (" .. tostring(pickup.amount) .. ")"
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	else
		local pickup <const> = WorldPickups[handle]
		if pickup then
			if pickup.entityId and DoesEntityExist(pickup.entityId) then
				DeleteEntity(pickup.entityId)
			end

			WorldPickups[handle] = nil
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	end
end

RegisterNetEvent("vorpInventory:shareMoneyPickupClient", PickupsService.shareMoneyPickupClient)

function PickupsService.shareGoldPickupClient(handle, amount, position, uuid, value)
	if value == 1 then
		if not WorldPickups[handle] then
			local pickup <const> = {
				label = T.gold .. " (" .. tostring(amount) .. ")",
				cleanLabel = T.gold,
				entityId = 0,
				amount = amount,
				count = amount,
				isMoney = false,
				isGold = true,
				coords = position,
				uuid = uuid,
				type = "item_standard",
				name = "goldbar"
			}

			WorldPickups[handle] = pickup
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	elseif value == 3 then
		local pickup = WorldPickups[handle]
		if pickup then
			pickup.amount = amount or pickup.amount or 1
			pickup.count = pickup.amount
			pickup.label = (pickup.cleanLabel or T.gold) .. " (" .. tostring(pickup.amount) .. ")"
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	else
		local pickup <const> = WorldPickups[handle]
		if pickup then
			if pickup.entityId and DoesEntityExist(pickup.entityId) then
				DeleteEntity(pickup.entityId)
			end

			WorldPickups[handle] = nil
			SetTimeout(150, RDInventorySendGroundDropsToNUI)
		end
	end
end

RegisterNetEvent("vorpInventory:shareGoldPickupClient", PickupsService.shareGoldPickupClient)


function PickupsService.playerPickUpAnim()
	playAnim(Config.Animation.PickUp)
	if Config.SFX.PickUp then
		PlaySoundFrontend("CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true, 1)
	end
end

RegisterNetEvent("vorpInventory:playerPickUpAnim", PickupsService.playerPickUpAnim)


CreateThread(function()
	local function isAnyPlayerNear()
		local playerPed <const>    = PlayerPedId()
		local playerCoords <const> = GetEntityCoords(playerPed, true, true)
		local players <const>      = GetActivePlayers()
		local count                = 0
		for _, player in ipairs(players) do
			local targetPed = GetPlayerPed(player)
			if player ~= PlayerId() then
				local targetCoords <const> = GetEntityCoords(targetPed, true, true)
				local distance <const> = #(playerCoords - targetCoords)
				if distance < 2.0 then
					count = count + 1
				end
			end
		end

		return count
	end

	repeat Wait(2000) until LocalPlayer.state.IsInSession
	createPrompt()
	local pressed = false
	while true do
		local sleep = 1000

		local playerPed <const> = PlayerPedId()
		local isDead <const> = IsEntityDead(playerPed)


		for key, pickup in pairs(WorldPickups) do
			local dist <const> = #(GetEntityCoords(playerPed) - pickup.coords)

			if dist < 80.0 then
				if pickup.entityId == 0 or not DoesEntityExist(pickup.entityId) then
					pickup.entityId = PickupsService.CreateObject(pickup.name, pickup.coords, pickup.type)
				end
			else
				if DoesEntityExist(pickup.entityId) then
					DeleteEntity(pickup.entityId)
					pickup.entityId = 0
				end
			end

			UiPromptSetVisible(PickUpPrompt, not isDead)

			if dist <= 1.0 and not InInventory then
				sleep = 0
				local label = VarString(10, "LITERAL_STRING", pickup.label)
				UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

				if UiPromptHasHoldModeCompleted(PickUpPrompt) then
					if pickup.entityId == WorldPickups[key].entityId then
						if not pressed then
							pressed = true

							if isAnyPlayerNear() == 0 then
								if pickup.isMoney then
									local data = { obj = key, uuid = pickup.uuid }
									TriggerServerEvent("vorpinventory:onPickupMoney", data)
								elseif Config.UseGoldItem and pickup.isGold then
									local data = { obj = key, uuid = pickup.uuid }
									TriggerServerEvent("vorpinventory:onPickupGold", data)
								else
									local data = { uid = pickup.uid, obj = key }
									TriggerServerEvent("vorpinventory:onPickup", data)
								end
								TaskLookAtEntity(playerPed, pickup.entityId, 1000, 2048, 3, 0)
							end

							SetTimeout(4000, function()
								pressed = false
							end)
						end
					end
				end
			end
		end

		if InInventory and GetGameTimer() > RD_NEXT_GROUND_NUI_UPDATE then
			RD_NEXT_GROUND_NUI_UPDATE = GetGameTimer() + 350
			RDInventorySendGroundDropsToNUI()
		end

		Wait(sleep)
	end
end)


-- for debug
AddEventHandler("onResourceStop", function(resourceName)
	if GetCurrentResourceName() ~= resourceName then return end
	if not Config.DevMode then return end
	--delete all entities
	for key, value in pairs(WorldPickups) do
		if DoesEntityExist(value.entityId) then
			DeleteEntity(value.entityId)
		end
	end
end)

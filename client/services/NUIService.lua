local isProcessingPay     = false
local timerUse            = 0
local candrop             = true
local cangive             = true
local InventoryIsDisabled = false
local T                   = TranslationInv.Langs[Lang]
local Core                = exports.vorp_core:GetCore()
StoreSynMenu              = false
GenSynInfo                = {}
InInventory               = false
NUIService                = {}
SynPending                = false

RegisterNetEvent('inv:dropstatus', function(x)
	candrop = x
end)

RegisterNetEvent('inv:givestatus')
AddEventHandler('inv:givestatus', function(x)
	cangive = x
end)

function ApplyPosfx()
	-- RD PERF: screen filter/blur is expensive in RedM NUI. Keep it optional from config.
	local perf = Config.UIPerformance or {}
	if Config.UseFilter and not perf.DisableScreenFilter then
		AnimpostfxPlay(Config.Filter)
		AnimpostfxSetStrength(Config.Filter, 0.5)
	end
end

function NUIService.ReloadInventory(inventory, packed)
	local payload = {}
	if packed then
		payload = msgpack.unpack(packed)
	else
		payload = json.decode(inventory)
	end

	if payload.itemList == '[]' then
		payload.itemList = {}
	end

	for _, item in pairs(payload.itemList) do
		if item.type == "item_weapon" then
			item.label = item.custom_label or Utils.GetWeaponDefaultLabel(item.name)

			if item.desc and item.custom_desc then
				item.desc = item.custom_desc
			end

			if not item.desc then
				item.desc = Utils.GetWeaponDefaultDesc(item.name)
			end
		else
			-- for syn scripts where description wasnt saved
			if not item.desc then
				if not ClientItems[item.name] then
					print("Item,", item.name, " no longer exist did you delete from database? or name was modified?")
				else
					item.desc = ClientItems[item.name].desc
				end
			end
		end
	end

	SendNUIMessage(payload)
	Wait(500)
	NUIService.LoadInv()
	SynPending = false
end

local inCustomInventory = false
function NUIService.OpenCustomInventory(name, id, capacity, weight)
	inCustomInventory = true
	ApplyPosfx()
	DisplayRadar(false)
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = "display",
		type = "custom",
		title = tostring(name),
		id = tostring(id),
		capacity = capacity,
		weight = weight,
	})
	InInventory = true
end

function NUIService.NUIMoveToCustom(obj)
	TriggerServerEvent("vorp_inventory:MoveToCustom", json.encode(obj))
end

function NUIService.NUITakeFromCustom(obj)
	TriggerServerEvent("vorp_inventory:TakeFromCustom", json.encode(obj))
end

function NUIService.OpenPlayerInventory(name, id, type)
	ApplyPosfx()
	DisplayRadar(false)
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = "display",
		type = type,
		title = name,
		id = id,
	})
	InInventory = true
end

function NUIService.NUIMoveToPlayer(obj)
	TriggerServerEvent("vorp_inventory:MoveToPlayer", json.encode(obj))
end

function NUIService.NUITakeFromPlayer(obj)
	TriggerServerEvent("vorp_inventory:TakeFromPlayer", json.encode(obj))
end

function NUIService.TransferLimitExceeded(maxValue)
	local message = string.format(T.MaxItemTransfer, maxValue.max)
	Core.NotifyRightTip(message, 4000)
end

-- was closed by the client
function NUIService.CloseInv()
	local perf = Config.UIPerformance or {}
	if Config.UseFilter and not perf.DisableScreenFilter then
		AnimpostfxStop(Config.Filter)
	end
	if StoreSynMenu then
		StoreSynMenu = false
		GenSynInfo = {}
		for _, item in pairs(UserInventory) do
			if item.metadata ~= nil and item.metadata.description ~= nil and (item.metadata.orgdescription ~= nil or item.metadata.orgdescription == "") then
				if item.metadata.orgdescription == "" then
					item.metadata.description = nil
				else
					item.metadata.description = item.metadata.orgdescription
				end
				item.metadata.orgdescription = nil
			end
		end
	end

	DisplayRadar(true)
	SetNuiFocus(false, false)
	SendNUIMessage({ action = "hide" })
	InInventory = false
	TriggerEvent("vorp_stables:setClosedInv", false)
	TriggerEvent("syn:closeinv")
	if inCustomInventory then
		inCustomInventory = false
		TriggerServerEvent("vorp_inventory:Server:CloseCustomInventory")
	end
end

function NUIService.setProcessingPayFalse()
	isProcessingPay = false
end

function NUIService.NUIUnequipWeapon(obj)
	local data = obj

	if UserWeapons[tonumber(data.id)] then
		UserWeapons[tonumber(data.id)]:UnequipWeapon()
	end

	NUIService.LoadInv()
end

function NUIService.NUIGetNearPlayers(obj)
	local nearestPlayers = Utils.getNearestPlayers()

	local playerIds = {}
	for _, player in ipairs(nearestPlayers) do
		if player ~= PlayerId() then
			local playerId = GetPlayerServerId(player)
			if Config.ShowCharacterNameOnGive then
				local name = Player(playerId).state.Character.FirstName .. " " .. Player(playerId).state.Character.LastName
				playerIds[#playerIds + 1] = { label = name, player = playerId }
			else
				playerIds[#playerIds + 1] = { label = playerId, player = playerId }
			end
		end
	end
	if #playerIds > 0 then
		NUIService.NUISetNearPlayers(obj, playerIds)
	else
		Core.NotifyRightTip(T.noplayersnearby, 5000)
	end
end

function NUIService.NUISetNearPlayers(obj, nearestPlayers)
	local nuiReturn = {}

	nuiReturn.action = "nearPlayers"
	nuiReturn.foundAny = true
	nuiReturn.players = nearestPlayers
	nuiReturn.item = obj.item
	nuiReturn.hash = obj.hash or 1
	nuiReturn.count = obj.count or 1
	nuiReturn.id = obj.id or 0
	nuiReturn.type = obj.type
	nuiReturn.what = obj.what
	SendNUIMessage(nuiReturn)
end

function NUIService.NUIGiveItem(obj)
	if not cangive then
		return Core.NotifyRightTip(T.cantgivehere, 5000)
	end

	local nearestPlayers = Utils.getNearestPlayers()
	local data = obj
	local data2 = data.data
	local isvalid = Validator.IsValidNuiCallback(data.hsn)

	if isvalid then
		local requestedTarget = tonumber(data.player)
		if not requestedTarget and nearestPlayers[1] then
			requestedTarget = GetPlayerServerId(nearestPlayers[1])
			data.player = requestedTarget
		end
		if not requestedTarget then
			return Core.NotifyRightTip(T.noplayersnearby, 5000)
		end

		for _, player in ipairs(nearestPlayers) do
			if GetPlayerServerId(player) == requestedTarget then
				local itemId = data2.id
				local target = requestedTarget

				if data2.type == "item_money" then
					if isProcessingPay then return end
					isProcessingPay = true
					TriggerServerEvent("vorpinventory:giveMoneyToPlayer", target, tonumber(data2.count))
				elseif Config.UseGoldItem and data2.type == "item_gold" then
					if isProcessingPay then return end
					isProcessingPay = true
					TriggerServerEvent("vorpinventory:giveGoldToPlayer", target, tonumber(data2.count))
				elseif data2.type == "item_ammo" then
					if isProcessingPay then return end
					isProcessingPay = true
					local amount = tonumber(data2.count)
					local ammotype = data2.item
					local maxcount = SharedData.MaxAmmo[ammotype]
					if amount > 0 and maxcount >= amount then
						TriggerServerEvent("vorpinventory:servergiveammo", ammotype, amount, target, maxcount)
					end
				elseif data2.type == "item_standard" then
					local amount = tonumber(data2.count)
					local item = UserInventory[itemId]

					if amount > 0 and item ~= nil and item:getCount() >= amount then
						TriggerServerEvent("vorpinventory:serverGiveItem", itemId, amount, target)
					end
				else
					TriggerServerEvent("vorpinventory:serverGiveWeapon", tonumber(itemId), target)
				end

				NUIService.LoadInv()
			end
		end
	end
end

function NUIService.NUIDropItem(obj)
	if not candrop then return Core.NotifyRightTip(T.cantdrophere, 5000) end

	local aux = Utils.expandoProcessing(obj)
	local isvalid = Validator.IsValidNuiCallback(aux.hsn)

	if isvalid then
		local itemName = aux.item
		local itemId = aux.id
		local metadata = aux.metadata
		local type = aux.type
		local qty = tonumber(aux.number)
		local degradation = aux.degradation
		if type == "item_money" then
			TriggerServerEvent("vorpinventory:serverDropMoney", qty)
		end

		if Config.UseGoldItem then
			if type == "item_gold" then
				TriggerServerEvent("vorpinventory:serverDropGold", qty)
			end
		end

		if type == "item_standard" then
			if aux.number ~= nil and aux.number ~= '' then
				local item = UserInventory[itemId]
				if not item then return end

				if qty <= 0 or qty > item:getCount() then return end

				TriggerServerEvent("vorpinventory:serverDropItem", itemName, itemId, qty, metadata, degradation)
			end
		end

		if type == "item_weapon" then
			TriggerServerEvent("vorpinventory:serverDropWeapon", aux.id)

			if UserWeapons[aux.id] then
				local weapon = UserWeapons[aux.id]

				if weapon:getUsed() then
					weapon:setUsed(false)
					weapon:UnequipWeapon()
				end

				UserWeapons[aux.id] = nil
			end
		end
		-- RD FIX: after a drop, refresh inventory/ground panel several times so the same slot can be dropped again
		-- without closing the inventory and without leaving the NUI validation locked.
		local function rdAfterDropRefresh()
			if NUIService and NUIService.LoadInv then
				NUIService.LoadInv()
			end
			if RDInventorySendGroundDropsToNUI then
				RDInventorySendGroundDropsToNUI()
			end
			SendNUIMessage({ action = "rdResetValidation" })
		end

		SetTimeout(40, rdAfterDropRefresh)
		SetTimeout(120, rdAfterDropRefresh)
		SetTimeout(260, rdAfterDropRefresh)
		SetTimeout(600, rdAfterDropRefresh)
		SetTimeout(1000, rdAfterDropRefresh)
		SetTimeout(1500, function()
			if RDInventorySendGroundDropsToNUI then
				RDInventorySendGroundDropsToNUI()
			end
			SendNUIMessage({ action = "rdResetValidation" })
		end)
	end
end

local function getGuidFromItemId(inventoryId, itemData, category, slotId)
	local outItem = DataView.ArrayBuffer(8 * 13)

	if not itemData then
		itemData = 0
	end
	--InventoryGetGuidFromItemid
	local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData, category, slotId, outItem:Buffer())
	if success then
		return outItem:Buffer() --Seems to not return anythign diff. May need to pull from native above
	else
		return nil
	end
end

local function addWardrobeInventoryItem(itemName, slotHash)
	local itemHash    = joaat(itemName)
	local addReason   = joaat("ADD_REASON_DEFAULT")
	local inventoryId = 1

	-- _ITEMDATABASE_IS_KEY_VALID
	local isValid     = Citizen.InvokeNative(0x6D5D51B188333FD1, itemHash, 0) --ItemdatabaseIsKeyValid
	if not isValid then
		return false
	end

	local characterItem = getGuidFromItemId(inventoryId, nil, joaat("CHARACTER"), 0xA1212100)
	if not characterItem then
		return false
	end

	local wardrobeItem = getGuidFromItemId(inventoryId, characterItem, joaat("WARDROBE"), 0x3DABBFA7)
	if not wardrobeItem then
		return false
	end

	local itemData = DataView.ArrayBuffer(8 * 13)

	-- _INVENTORY_ADD_ITEM_WITH_GUID
	local isAdded = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData:Buffer(), wardrobeItem, itemHash, slotHash, 1, addReason)
	if not isAdded then
		return false
	end

	-- _INVENTORY_EQUIP_ITEM_WITH_GUID
	local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemData:Buffer(), true)
	return equipped;
end

local function useWeapon(data)
	data.type = data.type or "item_weapon"
	local ped = PlayerPedId()
	local _, weaponHash = GetCurrentPedWeapon(ped, false, 0, false)
	local weaponId = tonumber(data.id)
	if weaponId and not UserWeapons[weaponId] then
		return print("Weapon not found")
	end
	local weapName = joaat(UserWeapons[weaponId]:getName())
	local isWeaponAGun = Citizen.InvokeNative(0x705BE297EEBDB95D, weapName)
	local isWeaponOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, weapName)
	local isArmed = Citizen.InvokeNative(0xCB690F680A3EA971, ped, 4)
	local notdual = false
	if (isWeaponAGun and isWeaponOneHanded) and isArmed and not Config.DuelWield then
		return
	elseif (isWeaponAGun and isWeaponOneHanded) and isArmed and Config.DuelWield then
		addWardrobeInventoryItem("CLOTHING_ITEM_M_OFFHAND_000_TINT_004", 0xF20B6B4A)
		addWardrobeInventoryItem("UPGRADE_OFFHAND_HOLSTER", 0x39E57B01)
		UserWeapons[weaponId]:setUsed2(true)
		if weaponHash == weapName then
			UserWeapons[weaponId]:equipwep(true)
		else
			UserWeapons[weaponId]:equipwep()
		end
		UserWeapons[weaponId]:loadComponents()
		UserWeapons[weaponId]:setUsed(true)
		TriggerServerEvent("syn_weapons:weaponused", data)
	elseif not UserWeapons[weaponId]:getUsed() and not Citizen.InvokeNative(0x8DECB02F88F428BC, ped, weapName, 0, true) or Citizen.InvokeNative(0x30E7C16B12DA8211, weapName) then
		notdual = true
	end

	if notdual then
		UserWeapons[weaponId]:equipwep()
		UserWeapons[weaponId]:loadComponents()
		UserWeapons[weaponId]:setUsed(true)
		TriggerServerEvent("syn_weapons:weaponused", data)
	end
	if UserWeapons[weaponId]:getUsed() then
		local serial = UserWeapons[weaponId]:getSerialNumber()
		local info = { weaponId = weaponId, serialNumber = serial }
		local key = string.format("GetEquippedWeaponData_%d", weapName)
		LocalPlayer.state:set(key, info, true)
	end
	TriggerServerEvent("vorpinventory:setUsedWeapon", weaponId, UserWeapons[weaponId]:getUsed(), UserWeapons[weaponId]:getUsed2())

	NUIService.LoadInv()
end

exports("useWeapon", useWeapon)

local function useItem(data)
	if timerUse <= 0 then
		TriggerServerEvent("vorp_inventory:useItem", data)
		timerUse = Config.SpamDelay
	else
		Core.NotifyRightTip(T.slow, 5000)
	end
end

function NUIService.NUIUseItem(data)
	if data.type == "item_standard" then
		useItem(data)
	elseif data.type == "item_weapon" then
		useWeapon(data)
	end
end

exports("useItem", useItem) -- not tested yet


function NUIService.NUISound()
	if Config.SFX.ItemHover then
		PlaySoundFrontend("BACK", "RDRO_Character_Creator_Sounds", true, 0)
	end
end

function NUIService.NUIFocusOff()
	local perf = Config.UIPerformance or {}
	if Config.UseFilter and not perf.DisableScreenFilter then
		AnimpostfxStop(Config.Filter)
	end
	DisplayRadar(true)
	if Config.SFX.CloseInventory then
		PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
	end
	NUIService.CloseInv()
end


--==============================================================
-- RD UI compatibility layer
-- Keeps original VORP/server/store events, but accepts callbacks
-- used by the newer NUI drag/drop/hotbar/clothes/settings UI.
--==============================================================
local RD_HOTBAR_CONFIG = Config.Hotbar or Config.HOTBAR or {}
local function RDConfigBool(value, fallback)
	if value == nil then return fallback end
	return value == true
end
local function RDControlHash(value, fallback)
	if type(value) == "number" then return value end
	if type(value) == "string" then return GetHashKey(value) end
	return fallback
end

local function RDConfigValue(primary, fallback)
	if primary ~= nil then return primary end
	return fallback
end

local RD_HOTBAR_ENABLED = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.Enable, RD_HOTBAR_CONFIG.ENABLE), true)
local RD_HOTBAR_COUNT = tonumber(RDConfigValue(RD_HOTBAR_CONFIG.Slots, RD_HOTBAR_CONFIG.SLOT_COUNT)) or 5
local RD_MAIN_SLOT_COUNT = 25
local RD_HOTBAR_VISIBLE = false
local RD_HOTBAR_MODIFIER_CONTROL = RDControlHash(RDConfigValue(RD_HOTBAR_CONFIG.ModifierControl, RD_HOTBAR_CONFIG.HOLD_KEY), `INPUT_SELECT_RADAR_MODE`)
local RD_HOTBAR_USE_ONLY = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.UseOnly, RD_HOTBAR_CONFIG.USE_ONLY), true)
local RD_HOTBAR_DISABLE_NATIVE = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.DisableNativeQuickSelect, RD_HOTBAR_CONFIG.DISABLE_NATIVE_QUICKSELECT), true)
local RD_HOTBAR_SHOW_ON_ALT = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.ShowWhileHoldingAlt, RD_HOTBAR_CONFIG.SHOW_WHEN_HOLD), true)
local RD_HOTBAR_ALLOW_IN_INV = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.AllowWhenInventoryOpen, RD_HOTBAR_CONFIG.ALLOW_WHEN_INVENTORY_OPEN), false)
local RD_HOTBAR_COOLDOWN = tonumber(RDConfigValue(RD_HOTBAR_CONFIG.UseCooldown, RD_HOTBAR_CONFIG.USE_COOLDOWN)) or 180

local function RDCharKeyPrefix(prefix)
	local charId = nil
	if LocalPlayer and LocalPlayer.state and LocalPlayer.state.Character then
		local char = LocalPlayer.state.Character
		charId = char.CharIdentifier or char.charIdentifier or char.charidentifier or char.identifier or char.id
	end
	charId = charId or GetPlayerServerId(PlayerId()) or "player"
	return (prefix or "rdinv") .. ":" .. tostring(charId)
end

local function RDDecodeJson(raw, fallback)
	if not raw or raw == "" then return fallback end
	local ok, decoded = pcall(json.decode, raw)
	if ok and decoded then return decoded end
	return fallback
end

local function RDMakeItemDropPayload(data, itemType)
	data = data or {}
	if data.item and type(data.item) == "table" then
		local item = data.item
		return {
			hsn = data.hsn,
			item = item.name or item.item or data.name,
			id = item.id or data.id,
			number = data.number or data.amount or item.count or 1,
			metadata = item.metadata or data.metadata,
			degradation = item.degradation or data.degradation,
			type = itemType or data.type or item.type or "item_standard",
		}
	end
	return {
		hsn = data.hsn,
		item = data.item or data.name,
		id = data.id,
		number = data.number or data.amount or data.count or 1,
		metadata = data.metadata,
		degradation = data.degradation,
		type = itemType or data.type or "item_standard",
	}
end

local function RDCurrentInventoryEntry(entry)
	if type(entry) ~= "table" then return nil end
	local id = tonumber(entry.id)
	local typ = tostring(entry.type or "")
	if typ == "item_weapon" and id and UserWeapons[id] then
		local currentWeapon = UserWeapons[id]
		return {
			count = currentWeapon:getTotalAmmoCount(),
			limit = -1,
			label = currentWeapon:getLabel(),
			name = currentWeapon:getName(),
			item = currentWeapon:getName(),
			metadata = {},
			hash = GetHashKey(currentWeapon:getName()),
			type = "item_weapon",
			canUse = true,
			canRemove = true,
			id = currentWeapon:getId(),
			used = currentWeapon:getUsed(),
			used2 = currentWeapon:getUsed2(),
			desc = currentWeapon:getDesc(),
			group = 5,
			serial_number = currentWeapon:getSerialNumber(),
			custom_label = currentWeapon:getCustomLabel(),
			custom_desc = currentWeapon:getCustomDesc(),
			weight = currentWeapon:getWeight(),
		}
	end
	if typ == "item_standard" and id and UserInventory[id] then
		local source = UserInventory[id]
		local item = {}
		for k, v in pairs(source) do item[k] = v end
		item.item = item.name
		return item
	end
	return nil
end

function NUIService.RDLoadInventoryLayout()
	local raw = GetResourceKvpString(RDCharKeyPrefix("rdinv:layout"))
	local saved = RDDecodeJson(raw, nil)
	if type(saved) == "table" then
		if type(saved.slots) == "table" then return saved.slots end
		if type(saved.order) == "table" then return saved.order end
		return saved
	end
	return nil
end

local function RDHotbarEntryKey(entry)
	if type(entry) ~= "table" or entry.id == nil or entry.type == nil then return nil end
	return tostring(entry.type) .. ":" .. tostring(entry.id)
end

function NUIService.RDBuildHotbarSlots()
	local raw = GetResourceKvpString(RDCharKeyPrefix("rdinv:hotbar"))
	local saved = RDDecodeJson(raw, {})
	local slots = {}
	local seen = {}
	for i = 1, RD_HOTBAR_COUNT do
		local entry = nil
		if type(saved) == "table" then
			-- Do not fallback to neighbouring indexes: that caused the same weapon to clone into empty hotbar slots.
			entry = saved[i] or saved[tostring(i)]
		end
		local key = RDHotbarEntryKey(entry)
		local current = (key and not seen[key]) and RDCurrentInventoryEntry(entry) or nil
		if current then
			seen[key] = true
			local cell = {}
			for k, v in pairs(current) do cell[k] = v end
			cell.occupied = true
			cell.index = i - 1
			slots[i] = cell
		else
			slots[i] = { occupied = false, index = i - 1 }
		end
	end
	return slots
end

function NUIService.RDSendHotbarUpdate()
	SendNUIMessage({ action = "hotbarSync", slots = NUIService.RDBuildHotbarSlots() })
end

function NUIService.RDSetHotbarVisible(show)
	show = show == true
	if show then
		NUIService.RDSendHotbarUpdate()
	end
	SendNUIMessage({ action = "hotbarGame", visible = show })
end

function NUIService.RDSaveInventoryLayout(data, cb)
	if type(data) == "table" then
		SetResourceKvp(RDCharKeyPrefix("rdinv:layout"), json.encode(data))
	end
	if cb then cb("ok") end
end

function NUIService.RDSaveHotbar(data, cb)
	local slots = {}
	if type(data) == "table" and type(data.slots) == "table" then
		local seen = {}
		for i = 1, RD_HOTBAR_COUNT do
			-- JSON arrays arrive 1-based in Lua. Keep empty slots as false so indexes do not collapse.
			local e = data.slots[i] or data.slots[tostring(i)]
			local key = RDHotbarEntryKey(e)
			if key and not seen[key] then
				seen[key] = true
				slots[i] = { id = e.id, type = e.type, name = e.name or e.item, hash = e.hash or 0 }
			else
				slots[i] = false
			end
		end
		SetResourceKvp(RDCharKeyPrefix("rdinv:hotbar"), json.encode(slots))
	end
	NUIService.RDSendHotbarUpdate()
	if cb then cb("ok") end
end

function NUIService.RDSaveHotbarPosition(data, cb)
	if type(data) == "table" then
		SetResourceKvp(RDCharKeyPrefix("rdinv:hotbarpos"), json.encode({ left = data.left, top = data.top }))
	end
	if cb then cb("ok") end
end

function NUIService.RDLoadHotbarPosition()
	return RDDecodeJson(GetResourceKvpString(RDCharKeyPrefix("rdinv:hotbarpos")), nil)
end

function NUIService.RDDropMoney(data, cb)
	data = data or {}; data.type = "item_money"
	NUIService.NUIDropItem(data)
	if cb then cb("ok") end
end

function NUIService.RDDropGold(data, cb)
	data = data or {}; data.type = "item_gold"
	NUIService.NUIDropItem(data)
	if cb then cb("ok") end
end

function NUIService.RDDropRoll(data, cb)
	-- Original VORP inventory has no separate roll drop event; keep callback safe.
	if Core and Core.NotifyRightTip then Core.NotifyRightTip("Roll drop is not enabled in this original VORP core.", 3000) end
	if cb then cb("ok") end
end

function NUIService.RDDropStandard(data, cb)
	NUIService.NUIDropItem(RDMakeItemDropPayload(data, "item_standard"))
	if cb then cb("ok") end
end

function NUIService.RDDropWeapon(data, cb)
	NUIService.NUIDropItem(RDMakeItemDropPayload(data, "item_weapon"))
	if cb then cb("ok") end
end

function NUIService.RDDropAdvanced(data, cb)
	local typ = data and data.type or nil
	if typ == "item_money" then
		NUIService.RDDropMoney(data, cb); return
	elseif typ == "item_gold" then
		NUIService.RDDropGold(data, cb); return
	elseif typ == "item_weapon" then
		NUIService.RDDropWeapon(data, cb); return
	end
	NUIService.RDDropStandard(data, cb)
end

function NUIService.RDRequestGroundDrops(_, cb)
	-- Keep the original VORP pickup/server events, but mirror nearby ground drops
	-- into the new right-side UI panel so dropped items are visible/takeable.
	local itemList = {}
	if RDInventoryGetGroundDropsForNUI then
		local ok, result = pcall(RDInventoryGetGroundDropsForNUI)
		if ok and type(result) == "table" then itemList = result end
	end
	SendNUIMessage({ action = "rdGroundDropsUpdate", itemList = itemList, current = #itemList, capacity = 25 })
	if cb then cb("ok") end
end

function NUIService.RDTakeFromGroundDrop(data, cb)
	-- RD FIX7: use the original VORP pickup events, but resolve the pickup from
	-- the original PickupsService WorldPickups table so the panel cannot send a
	-- bad/incomplete payload and freeze the UI.
	data = data or {}
	local handled = false
	if RDInventoryTakeGroundDropFromNUI then
		local ok, result = pcall(RDInventoryTakeGroundDropFromNUI, data)
		handled = ok and result == true
	end

	if not handled then
		-- Safe fallback, still original VORP events.
		if data.isMoney and data.obj ~= nil and data.uuid ~= nil then
			TriggerServerEvent("vorpinventory:onPickupMoney", { obj = data.obj, uuid = data.uuid, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
		elseif Config.UseGoldItem and data.isGold and data.obj ~= nil and data.uuid ~= nil then
			TriggerServerEvent("vorpinventory:onPickupGold", { obj = data.obj, uuid = data.uuid, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
		elseif data.uid ~= nil and data.obj ~= nil then
			TriggerServerEvent("vorpinventory:onPickup", { uid = data.uid, obj = data.obj, amount = data.amount or data.pickupAmount, fromNui = true, keepInventoryOpen = true })
		end
		SetTimeout(700, function()
			NUIService.LoadInv()
			if RDInventorySendGroundDropsToNUI then RDInventorySendGroundDropsToNUI() end
			SendNUIMessage({ action = "rdResetValidation" })
		end)
	end

	-- RD FIX14: always unlock the NUI after a ground pickup attempt, even if the
	-- original server rejects the item. This keeps USE/right-click/drag from staying blocked.
	local function rdUnlockGroundUi()
		SendNUIMessage({ action = "rdResetValidation" })
		if RDInventorySendGroundDropsToNUI then RDInventorySendGroundDropsToNUI() end
	end
	rdUnlockGroundUi()
	SetTimeout(50, rdUnlockGroundUi)
	SetTimeout(150, rdUnlockGroundUi)
	SetTimeout(450, function() if NUIService.LoadInv then NUIService.LoadInv() end rdUnlockGroundUi() end)
	SetTimeout(950, rdUnlockGroundUi)
	SetTimeout(1600, rdUnlockGroundUi)
	SetTimeout(2600, rdUnlockGroundUi)
	if cb then cb({ ok = true }) end
end

function NUIService.RDRequestHandCraftingRecipes(_, cb)
	local recipes = {}
	local src = Config.HandCrafting or Config.RDHandCrafting or {}
	for i, r in ipairs(src) do
		recipes[#recipes + 1] = {
			label = r.LABEL or r.label or r.name or ("Recipe " .. tostring(i)),
			desc = r.DESC or r.desc or "",
			needed = r.NEEDED or r.needed or {},
			reward = r.REWARD or r.reward or {},
		}
	end
	SendNUIMessage({ action = "handCraftingRecipes", recipes = recipes })
	if cb then cb("ok") end
end

function NUIService.RDHandCraftingExecute(data, cb)
	if cb then cb("ok") end
	local idx = tonumber(data and data.recipeIndex)
	if not idx then return end
	-- Hook for servers that want to add hand-crafting without replacing original inventory events.
	TriggerEvent("rd_inventory:client:handCraftingExecute", idx, data)
	TriggerServerEvent("rd_inventory:server:handCraftingExecute", idx, data)
end

function NUIService.RDInventorySaddle(_, cb)
	if cb then cb("ok") end
	local ped = PlayerPedId()
	local mount = GetMount(ped)
	if mount and mount > 0 then
		-- Compatibility hook only; original VORP stable/saddle resources keep their own events.
		TriggerEvent("rd_inventory:client:openSaddle", NetworkGetNetworkIdFromEntity(mount))
	else
		if Core and Core.NotifyRightTip then Core.NotifyRightTip("You are not on a horse", 3000) end
	end
end

function NUIService.RDClothesOpen(_, cb)
	if cb then cb("ok") end
	TriggerEvent("rd_inventory:client:clothesPanelOpen")
end

local function RDRestorePlayerClothes()
	TriggerEvent("vorpcharacter:reloadafterdeath")
	TriggerEvent("vorpcharacter:reloadskin")
	TriggerEvent("vorpcharacter:reloadSkin")
	TriggerEvent("vorp_character:reloadSkin")
	TriggerEvent("vorp:reloadSkin")
	TriggerEvent("vorp_skin:reloadSkin")
	TriggerEvent("vorp_clothing:client:reloadClothes")
	TriggerEvent("vorp_clothing:reloadClothes")
	local ped = PlayerPedId()
	if ped and ped ~= 0 then
		Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
	end
end

function NUIService.RDClothesAction(data, cb)
	if cb then cb("ok") end
	local slot = tostring(data and data.slot or "")
	local action = tostring(data and data.action or "remove")
	TriggerEvent("rd_inventory:client:clothesAction", slot, action, data)
	TriggerEvent("vorp_inventory:client:clothesAction", slot, action, data)
	TriggerEvent("vorp_clothing:client:clothesAction", slot, action, data)
	if action == "restoreAll" or action == "restore_all" or slot == "all" or action == "restore" then
		RDRestorePlayerClothes()
		return
	end
	if action ~= "remove" and action ~= "toggle" then return end
	local tags = {
		hat = "HATS", mask = "MASKS", neckwear = "NECKWEAR", shirt = "SHIRTS_FULL", vest = "VESTS",
		coat = "COATS", poncho = "PONCHOS", gloves = "GLOVES", pants = "PANTS", boots = "BOOTS",
		spurs = "SPURS", gunbelt = "GUNBELTS", holster = "HOLSTERS_LEFT", offhand = "HOLSTERS_RIGHT",
		satchel = "SATCHELS", belt_buckle = "BELT_BUCKLES", accessory = "ACCESSORIES", cloak = "CLOAKS",
		eyewear = "EYEWEAR", loadout = "LOADOUTS"
	}
	local tag = tags[slot]
	if tag then
		local ped = PlayerPedId()
		Citizen.InvokeNative(0xD710A5007C2AC539, ped, joaat(tag), 0)
		Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
	end
end

function NUIService.RDUiNotify(data, cb)
	if data and data.text and Core and Core.NotifyRightTip then
		Core.NotifyRightTip(tostring(data.text), 1800)
	end
	if cb then cb("ok") end
end

function NUIService.RDAddWeaponAttachment(data, cb)
	if cb then cb("ok") end
	TriggerEvent("rd_inventory:client:addWeaponAttachment", data)
end

function NUIService.RDRemoveWeaponAttachment(data, cb)
	if cb then cb("ok") end
	TriggerEvent("rd_inventory:client:removeWeaponAttachment", data)
end

function NUIService.RDWeaponInspect(data, cb)
	if cb then cb("ok") end
	if data and data.id and UserWeapons[tonumber(data.id)] then
		if Core and Core.NotifyRightTip then Core.NotifyRightTip("Weapon inspect UI is not part of this original VORP core.", 2500) end
	end
end

function NUIService.RDRemoveBullets(_, cb) if cb then cb("ok") end end
function NUIService.RDSetWeaponAmmoType(_, cb) if cb then cb("ok") end end
function NUIService.RDReloadWeapon(_, cb) if cb then cb("ok") end end

local function RDHotbarForceUseWeapon(entry)
	entry = entry or {}
	entry.type = "item_weapon"
	entry.item = entry.item or entry.name

	local weaponId = tonumber(entry.id)
	local weapon = weaponId and UserWeapons[weaponId]
	if not weapon then return false end

	local ped = PlayerPedId()
	local weaponName = weapon:getName()
	local weaponHash = joaat(weaponName)
	local hasWeapon = Citizen.InvokeNative(0x8DECB02F88F428BC, ped, weaponHash, 0, true)
	local isThrowable = Citizen.InvokeNative(0x30E7C16B12DA8211, weaponHash)

	-- First hotbar press must USE/EQUIP. If the weapon is already marked used
	-- but is only on the belt/holster, force it back in hand instead of toggling
	-- unequip or doing nothing. This keeps ALT+1-5 fast like original VORP.
	if not weapon:getUsed() or (not hasWeapon and not isThrowable) then
		useWeapon(entry)
	else
		weapon:loadComponents()
		SetCurrentPedWeapon(ped, weaponHash, true, 0, false, false)
		-- Gunsmith/syn_weapons often reapplies tints/colors/components on this event.
		TriggerServerEvent("syn_weapons:weaponused", entry)
		TriggerServerEvent("vorpinventory:setUsedWeapon", weaponId, weapon:getUsed(), weapon:getUsed2())
		NUIService.LoadInv()
	end

	return true
end

function NUIService.RDUseHotbarSlot(slot)
	if not RD_HOTBAR_ENABLED then return end
	if InventoryIsDisabled then return end
	local allowInInventory = RDConfigBool(RDConfigValue(RD_HOTBAR_CONFIG.AllowWhenInventoryOpen, RD_HOTBAR_CONFIG.ALLOW_WHEN_INVENTORY_OPEN), false)
	if InInventory and not allowInInventory then return end
	local slots = NUIService.RDBuildHotbarSlots()
	local cell = slots[slot]
	if not cell or not cell.occupied then return end
	local entry = RDCurrentInventoryEntry(cell)
	if not entry then
		NUIService.RDSendHotbarUpdate()
		return
	end
	entry.item = entry.name

	if entry.type == "item_weapon" then
		RDHotbarForceUseWeapon(entry)
	else
		NUIService.NUIUseItem(entry)
	end

	SetTimeout(150, function()
		NUIService.RDSendHotbarUpdate()
	end)
end

local function RDHotbarSlotControl(index)
	local slotControls = RD_HOTBAR_CONFIG.SlotControls or RD_HOTBAR_CONFIG.SLOT_KEYS or RD_HOTBAR_CONFIG.Controls
	if type(slotControls) == "table" then
		local configured = slotControls[index] or slotControls[tostring(index)]
		if configured ~= nil then
			return RDControlHash(configured, nil)
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

local RDHotbarLastUse = 0

local function RDHotbarAltHeld()
	return IsControlPressed(0, RD_HOTBAR_MODIFIER_CONTROL) or IsDisabledControlPressed(0, RD_HOTBAR_MODIFIER_CONTROL)
end

local function RDHotbarSetVisible(state)
	state = state == true
	if RD_HOTBAR_VISIBLE == state then return end
	RD_HOTBAR_VISIBLE = state
	SendNUIMessage({ action = "hotbarGame", visible = state })
	if state then
		NUIService.RDSendHotbarUpdate()
	end
end

local function RDHotbarUseFromKey(slot)
	slot = tonumber(slot)
	if not RD_HOTBAR_ENABLED then return end
	if not slot or slot < 1 or slot > RD_HOTBAR_COUNT then return end
	if InventoryIsDisabled then return end
	if InInventory and not RD_HOTBAR_ALLOW_IN_INV then return end
	if not RDHotbarAltHeld() then return end

	local now = GetGameTimer()
	if now - RDHotbarLastUse < RD_HOTBAR_COOLDOWN then return end
	RDHotbarLastUse = now

	RDHotbarSetVisible(true)
	NUIService.RDUseHotbarSlot(slot)
end

-- RD HOTBAR V2 PORT: the live ALT+1-5 control loop is now in client/client.lua,
-- copied/adapted from the working V2 hotbar. Keeping it there avoids RedM
-- RegisterKeyMapping issues and prevents duplicate hotbar use threads.
RegisterCommand("hotbarpos", function()
	SetNuiFocus(true, true)
	SendNUIMessage({ action = "hotbarEditPos" })
end, false)

local function loadItems()
	local items = {}
	if not StoreSynMenu then
		for id, item in pairs(UserInventory) do
			table.insert(items, item)
		end
	elseif StoreSynMenu then
		for _, item in pairs(UserInventory) do
			if item.metadata ~= nil and item.metadata.orgdescription ~= nil then
				item.metadata.description = item.metadata.orgdescription
				item.metadata.orgdescription = nil
			end
		end


		local buyitems = GenSynInfo.buyitems
		if buyitems and next(buyitems) then
			for _, item in pairs(UserInventory) do
				for k, v in ipairs(buyitems) do
					if item.name == v.name then
						item.metadata = item.metadata or {}
						if item.metadata.orgdescription == nil then
							if item.metadata.description ~= nil then
								item.metadata.orgdescription = item.metadata.description
							else
								item.metadata.orgdescription = ""
							end
						end
						item.metadata.description = T.cansell .. "<span style=color:Green;>" .. v.price .. "</span>"
					end
				end
				table.insert(items, item)
			end
		else
			for _, item in pairs(UserInventory) do
				table.insert(items, item)
			end
		end
	end
	return items
end

local function loadWeapons()
	local weapons = {}
	for _, currentWeapon in pairs(UserWeapons) do
		local weapon = {}
		weapon.count = currentWeapon:getTotalAmmoCount()
		weapon.limit = -1
		weapon.label = currentWeapon:getLabel()
		weapon.name = currentWeapon:getName()
		weapon.metadata = {}
		weapon.hash = GetHashKey(currentWeapon:getName())
		weapon.type = "item_weapon"
		weapon.canUse = true
		weapon.canRemove = true
		weapon.id = currentWeapon:getId()
		weapon.used = currentWeapon:getUsed()
		weapon.used2 = currentWeapon:getUsed2()
		weapon.desc = currentWeapon:getDesc()
		weapon.group = 5
		weapon.serial_number = currentWeapon:getSerialNumber()
		weapon.custom_label = currentWeapon:getCustomLabel()
		weapon.custom_desc = currentWeapon:getCustomDesc()
		weapon.weight = currentWeapon:getWeight()
		table.insert(weapons, weapon)
	end
	return weapons
end


local function loadItemsAndWeapons()
	local itemsToSend = {}
	local items = loadItems()
	local weapons = loadWeapons()

	-- merged items with weapons
	if Config.InventoryOrder == "items" then
		for _, item in pairs(items) do
			table.insert(itemsToSend, item)
		end
		for _, weapon in pairs(weapons) do
			table.insert(itemsToSend, weapon)
		end
	else
		for _, weapon in pairs(weapons) do
			table.insert(itemsToSend, weapon)
		end
		for _, item in pairs(items) do
			table.insert(itemsToSend, item)
		end
	end

	return itemsToSend
end

function NUIService.LoadInv()
	local payload <const> = {}

	Core.Callback.TriggerAsync("vorpinventory:get_slots", function(result)
		if not result then return end

		SendNUIMessage({ action = "changecheck", check = string.format("%.1f", (result.totalInvWeight or 0)), info = string.format("%.1f", (result.slots or 0)) })
		SendNUIMessage({
			action = "updateStatusHud",
			show   = not IsRadarHidden(),
			money  = result.money,
			gold   = result.gold,
			rol    = result.rol,
			id     = GetPlayerServerId(PlayerId()),
		})
	end)

	local itemsAndWeapons = loadItemsAndWeapons()
	payload.action = "setItems"
	payload.itemList = itemsAndWeapons
	payload.timenow = GlobalState.TimeNow
	payload.slotLayout = NUIService.RDLoadInventoryLayout and NUIService.RDLoadInventoryLayout() or nil
	payload.slotCount = RD_MAIN_SLOT_COUNT or 25
	payload.hotbarSlots = NUIService.RDBuildHotbarSlots and NUIService.RDBuildHotbarSlots() or nil
	SendNUIMessage(payload)
end

function NUIService.OpenInv()
	ApplyPosfx()
	DisplayRadar(false)
	if Config.SFX.OpenInventory then
		PlaySoundFrontend("SELECT", "RDRO_Character_Creator_Sounds", true, 0)
	end
	SetNuiFocus(true, true)
	SendNUIMessage({
		action = "display",
		type = "main",
		search = Config.InventorySearchable,
		autofocus = Config.InventorySearchAutoFocus
	})
	InInventory = true -- internal
	NUIService.LoadInv()
end

function NUIService.TransactionStarted()
	-- Keep mouse focus when the inventory is already open; ground-panel pickup starts a server transaction.
	SetNuiFocus(true, InInventory == true)
	SendNUIMessage({ action = "transaction", type = "started", text = T.TransactionLoading })
end

function NUIService.TransactionComplete(keepInventoryOpen)
	keepInventoryOpen = keepInventoryOpen == nil and true or keepInventoryOpen
	SetNuiFocus(keepInventoryOpen, keepInventoryOpen)
	SendNUIMessage({ action = "transaction", type = "completed" })
end

function NUIService.initiateData()
	-- Add Locales
	SendNUIMessage({
		action = "initiate",
		language = {
			empty = T.emptyammo,
			prompttitle = T.prompttitle,
			prompttitle2 = T.prompttitle2,
			promptaccept = T.promptaccept,
			inventoryclose = T.inventoryclose,
			inventorysearch = T.inventorysearch,
			toplayerpromptitle = T.toplayerpromptitle,
			toplaterpromptaccept = T.toplaterpromptaccept,
			gunbeltlabel = T.gunbeltlabel,
			gunbeltdescription = T.gunbeltdescription,
			inventorymoneylabel = T.inventorymoneylabel,
			inventorymoneydescription = T.inventorymoneydescription,
			givemoney = T.givemoney,
			dropmoney = T.dropmoney,
			inventorygoldlabel = T.inventorygoldlabel,
			inventorygolddescription = T.inventorygolddescription,
			givegold = T.givegold,
			dropgold = T.dropgold,
			unequip = T.unequip,
			equip = T.equip,
			use = T.use,
			give = T.give,
			drop = T.drop,
			copyserial = T.copyserial,
			labels = T.labels
		},
		config = {
			UseGoldItem = Config.UseGoldItem,
			AddGoldItem = Config.AddGoldItem,
			AddDollarItem = Config.AddDollarItem,
			AddAmmoItem = Config.AddAmmoItem,
			DoubleClickToUse = Config.DoubleClickToUse,
			UseRolItem = Config.UseRolItem,
			AddRollItem = Config.AddRollItem or false,
			WeightMeasure = Config.WeightMeasure or "Kg",
			EnableHotbar = RD_HOTBAR_ENABLED,
			HotbarAllow = "all",
			EnableHandCraftButton = true,
			EnableSaddleButton = true,
			ItemRaritySlotStyle = "background-img",
			TooltipPlacement = "hover",
			MainInventoryFixedSlotCount = RD_MAIN_SLOT_COUNT or 25,
			UIPerformance = Config.UIPerformance or {},
		},
		hotbarPos = NUIService.RDLoadHotbarPosition and NUIService.RDLoadHotbarPosition() or nil
	})
end

local blockInventory = false
local isWalking = false

CreateThread(function()
	local controlVar = false -- best to use variable than to check statebag every frame

	repeat Wait(2000) until LocalPlayer.state.IsInSession
	NUIService.initiateData()

	while true do
		local sleep = 1000
		if not InInventory and not blockInventory then
			sleep = 0
			if IsControlJustReleased(1, Config.OpenKey) then
				local player = PlayerPedId()
				local hogtied = IsPedHogtied(player) == 1
				local cuffed = IsPedCuffed(player)
				if not hogtied and not cuffed and not InventoryIsDisabled then
					if Config.AllowWalkingWhileInventoryOpen then
						if IsControlPressed(1, `INPUT_MOVE_UP_ONLY`) == 1 and not isWalking then
							isWalking = true
							local _isWalking = IsPedWalking(player)
							local isRunning = IsPedRunning(player)
							local isSprinting = IsPedSprinting(player)
							local speed = _isWalking and 1.0 or isRunning and 2.0 or isSprinting and 3.0 or 0.0
							local heading = GetEntityHeading(player)
							CreateThread(function()
								repeat Wait(0) until IsNuiFocused()
								SimulatePlayerInputGait(PlayerId(), speed, -1, heading, false, false)
								repeat Wait(0) until not IsNuiFocused()
								isWalking = false
								if GetMount(player) > 0 or IsPedInAnyVehicle(player, false) then
									ResetPlayerInputGait(PlayerId()) -- needs to reset on vehcicles or mount or only works for the first time for walking no need pressing the W key will reset it it seems
								end
							end)
						end
					end
					NUIService.OpenInv()
				end
			end
		end

		if Config.DisableDeathInventory then
			if InInventory and IsPedDeadOrDying(PlayerPedId(), false) then
				NUIService.CloseInv()
			end
		end

		if InInventory then
			if not controlVar then
				controlVar = true
				LocalPlayer.state:set("IsInvActive", true, true) -- can also listen for statebag change
				TriggerEvent("vorp_inventory:Client:OnInvStateChange", true)
			end
		else
			if controlVar then
				controlVar = false
				LocalPlayer.state:set("IsInvActive", false, true)
				TriggerEvent("vorp_inventory:Client:OnInvStateChange", false)
			end
		end

		Wait(sleep)
	end
end)

-- prevent player from opening inventory from server or client
RegisterNetEvent("vorp_inventory:blockInventory")
AddEventHandler("vorp_inventory:blockInventory", function(state)
	blockInventory = state
	if InInventory then
		NUIService.CloseInv()
	end
end)

-- Prevent Spam
CreateThread(function()
	repeat Wait(2000) until LocalPlayer.state.IsInSession
	while true do
		Wait(1000)
		if timerUse > 0 then
			timerUse = timerUse - 1000
		end
	end
end)

function NUIService.ChangeClothing(item)
	if item then
		ExecuteCommand(tostring(item))
	end
end

function NUIService.DisableInventory(param)
	InventoryIsDisabled = param
end

function NUIService.getActionsConfig(_, cb)
	cb(Actions)
end

function NUIService.CacheImages(info)
	local unpack = msgpack.unpack(info)
	SendNUIMessage({ action = "cacheImages", info = unpack })
end

function NUIService.ContextMenu(data)
	if not data then return end

	if data.close then
		NUIService.CloseInv()
	end

	if data.event?.client then
		TriggerEvent(data.event.client, data.event?.arguments, data.itemid)
	elseif data.event?.server then
		TriggerServerEvent("vorpinventory:validateContextMenuEvent", data)
	end
end

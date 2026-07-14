

-- RD SYN_STORE HARD FIX:
-- syn_store is encrypted on many servers, so the safest fix is to send it the
-- exact original payload shape, but never let item.name/store/geninfo arrive nil.
-- This fixes sell/buy "nil" messages when custom UI drag data loses the DB item name.
SynStoreLastStoreId = SynStoreLastStoreId or nil

local function RD_IsBadSynValue(v)
    if v == nil then return true end
    if type(v) ~= "string" then return false end
    local x = v:gsub("^%s+", ""):gsub("%s+$", "")
    if x == "" then return true end
    local l = string.lower(x)
    return l == "nil" or l == "nill" or l == "undefined" or l == "null" or l == "[object object]" or string.sub(l, 1, 6) == "table:"
end

local function RD_CleanSynString(v)
    if RD_IsBadSynValue(v) then return nil end
    if type(v) == "string" then return v:gsub("^%s+", ""):gsub("%s+$", "") end
    return v
end

local function RD_Lower(v)
    v = RD_CleanSynString(v)
    if type(v) ~= "string" then return nil end
    return string.lower(v)
end

local function RD_FirstGoodName(...)
    for i = 1, select("#", ...) do
        local clean = RD_CleanSynString(select(i, ...))
        if clean ~= nil then return clean end
    end
    return nil
end

local function RD_SetSynItemName(item, name)
    name = RD_CleanSynString(name)
    if not name or type(item) ~= "table" then return end
    item.name = name
    item.item = name
    item.itemName = name
    item.itemname = name
    item.item_name = name
end

local function RD_CopySafeItemFields(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    local name = RD_FirstGoodName(src.name, src.item, src.itemName, src.itemname, src.item_name)
    if name then RD_SetSynItemName(dst, name) end
    if RD_IsBadSynValue(dst.label) and not RD_IsBadSynValue(src.label) then dst.label = src.label end
    if RD_IsBadSynValue(dst.custom_label) and not RD_IsBadSynValue(src.custom_label) then dst.custom_label = src.custom_label end
    if RD_IsBadSynValue(dst.type) and not RD_IsBadSynValue(src.type) then dst.type = src.type end
    if dst.id == nil and src.id ~= nil then dst.id = src.id end
    if dst.count == nil and src.count ~= nil then dst.count = src.count end
    if dst.metadata == nil and src.metadata ~= nil then dst.metadata = src.metadata end
    if dst.limit == nil and src.limit ~= nil then dst.limit = src.limit end
    if dst.weight == nil and src.weight ~= nil then dst.weight = src.weight end
    if dst.canRemove == nil and src.canRemove ~= nil then dst.canRemove = src.canRemove end
end

local function RD_ItemCandidateKeys(item)
    local keys = {}
    if type(item) ~= "table" then return keys end
    local fields = { item.name, item.item, item.itemName, item.itemname, item.item_name, item.label, item.custom_label, item.displayLabel }
    for _, v in pairs(fields) do
        local x = RD_Lower(v)
        if x then keys[x] = true end
    end
    return keys
end

local function RD_RowMatchesItem(row, item)
    if type(row) ~= "table" or type(item) ~= "table" then return false end
    local candidates = RD_ItemCandidateKeys(item)
    if next(candidates) == nil then return false end
    local rowFields = { row.name, row.item, row.itemName, row.itemname, row.item_name, row.label, row.custom_label, row.displayLabel }
    for _, v in pairs(rowFields) do
        local key = RD_Lower(v)
        if key and candidates[key] then return true end
    end
    return false
end

local function RD_FindInventoryItem(payloadItem)
    if type(payloadItem) ~= "table" or type(UserInventory) ~= "table" then return nil end

    local pid = tonumber(payloadItem.id)
    if pid and UserInventory[pid] then return UserInventory[pid] end

    local wantedName = RD_Lower(RD_FirstGoodName(payloadItem.name, payloadItem.item, payloadItem.itemName, payloadItem.itemname, payloadItem.item_name))
    local wantedLabel = RD_Lower(RD_FirstGoodName(payloadItem.label, payloadItem.custom_label, payloadItem.displayLabel))

    if wantedName then
        for _, invItem in pairs(UserInventory) do
            local n = RD_Lower(RD_FirstGoodName(invItem.name, invItem.item, invItem.itemName, invItem.itemname, invItem.item_name))
            if n and n == wantedName then return invItem end
        end
    end

    if wantedLabel then
        for _, invItem in pairs(UserInventory) do
            local l = RD_Lower(RD_FirstGoodName(invItem.label, invItem.custom_label, invItem.displayLabel))
            if l and l == wantedLabel then return invItem end
        end
    end

    return nil
end

local function RD_FindClientItemNameByLabel(label)
    local wantedLabel = RD_Lower(label)
    if not wantedLabel or type(ClientItems) ~= "table" then return nil end
    for name, info in pairs(ClientItems) do
        if type(info) == "table" and RD_Lower(info.label) == wantedLabel then
            return name, info
        end
    end
    return nil
end

local function RD_ForEachGenInfoList(gen, fn)
    if type(gen) ~= "table" then return nil end
    local lists = { gen.buyitems, gen.sellitems, gen.items }
    for _, list in pairs(lists) do
        if type(list) == "table" then
            for _, row in pairs(list) do
                local result = fn(row)
                if result ~= nil then return result end
            end
        end
    end
    return nil
end

local function RD_FindSynStoreRow(gen, item)
    return RD_ForEachGenInfoList(gen, function(row)
        if RD_RowMatchesItem(row, item) then return row end
        return nil
    end)
end

local function RD_NormalizeSynStorePayload(obj, direction)
    if type(obj) ~= "table" then obj = {} end
    if type(obj.item) ~= "table" then obj.item = {} end

    if (obj.store == nil or obj.store == "" or obj.store == false) and SynStoreLastStoreId ~= nil then
        obj.store = SynStoreLastStoreId
    end
    if type(obj.geninfo) ~= "table" or next(obj.geninfo) == nil then
        obj.geninfo = GenSynInfo or {}
    end

    local item = obj.item
    local invItem = RD_FindInventoryItem(item)
    local row = RD_FindSynStoreRow(obj.geninfo, item)

    if direction == "move" and invItem then
        RD_CopySafeItemFields(item, invItem)
    end

    if row then
        local rowName = RD_FirstGoodName(row.name, row.item, row.itemName, row.itemname, row.item_name)
        if rowName and RD_IsBadSynValue(item.name) then RD_SetSynItemName(item, rowName) end
        if RD_IsBadSynValue(item.label) and not RD_IsBadSynValue(row.label) then item.label = row.label end
        if RD_IsBadSynValue(item.type) and not RD_IsBadSynValue(row.type) then item.type = row.type end
        if item.price == nil and row.price ~= nil then item.price = row.price end
        if obj.price == nil and row.price ~= nil and direction == "take" then obj.price = row.price end
    end

    if (not row) and direction == "take" then
        -- Buying from the store: find the exact row by label/name from the shop lists.
        row = RD_ForEachGenInfoList(obj.geninfo, function(r)
            if RD_RowMatchesItem(r, item) then return r end
            return nil
        end)
        if row then
            local rowName = RD_FirstGoodName(row.name, row.item, row.itemName, row.itemname, row.item_name)
            if rowName then RD_SetSynItemName(item, rowName) end
            if RD_IsBadSynValue(item.label) and not RD_IsBadSynValue(row.label) then item.label = row.label end
            if RD_IsBadSynValue(item.type) and not RD_IsBadSynValue(row.type) then item.type = row.type end
            if item.price == nil and row.price ~= nil then item.price = row.price end
            if obj.price == nil and row.price ~= nil then obj.price = row.price end
        end
    end

    if not invItem and RD_IsBadSynValue(item.name) then
        local foundName, foundInfo = RD_FindClientItemNameByLabel(RD_FirstGoodName(item.label, item.custom_label, item.displayLabel))
        if foundName then
            RD_SetSynItemName(item, foundName)
            if RD_IsBadSynValue(item.type) and type(foundInfo) == "table" and not RD_IsBadSynValue(foundInfo.type) then item.type = foundInfo.type end
        end
    end

    -- Last safe aliases. Never let syn_store receive item.name as nil.
    local finalName = RD_FirstGoodName(item.name, item.item, item.itemName, item.itemname, item.item_name)
    if not finalName then
        finalName = RD_FirstGoodName(item.label, item.custom_label, item.displayLabel)
    end
    if finalName then RD_SetSynItemName(item, finalName) end

    if RD_IsBadSynValue(item.type) then item.type = obj.type or "item_standard" end
    obj.type = item.type

    local n = tonumber(obj.number or obj.amount or obj.count)
    if n == nil or n <= 0 then n = 1 end
    obj.number = n

    return obj
end

function NUIService.OpenClanInventory(clanName, clanId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "clan",
        title = "" .. clanName .. "",
        clanid = clanId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
end

function NUIService.NUIMoveToClan(obj)
    TriggerServerEvent("syn_clan:MoveToClan", json.encode(obj))
end

function NUIService.NUITakeFromClan(obj)
    if not SynPending then
        SynPending = true
        TriggerServerEvent("syn_clan:TakeFromClan", json.encode(obj))
    end
end

function NUIService.OpenContainerInventory(ContainerName, Containerid, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "Container",
        title = "" .. ContainerName .. "",
        Containerid = Containerid,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
end

function NUIService.NUIMoveToContainer(obj)
    TriggerServerEvent("syn_Container:MoveToContainer", json.encode(obj))
end

function NUIService.NUITakeFromContainer(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("syn_Container:TakeFromContainer", json.encode(obj))
    end
end

function NUIService.OpenHorseInventory(horseTitle, horseId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "horse",
        title = horseTitle,
        horseid = horseId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
    TriggerEvent("vorp_stables:setClosedInv", true)
end

function NUIService.NUIMoveToHorse(obj)
    TriggerServerEvent("vorp_stables:MoveToHorse", json.encode(obj))
end

function NUIService.NUITakeFromHorse(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("vorp_stables:TakeFromHorse", json.encode(obj))
    end
end

function NUIService.NUIMoveToStore(obj)
    obj = RD_NormalizeSynStorePayload(obj, "move")
    TriggerServerEvent("syn_store:MoveToStore", json.encode(obj))
end

function NUIService.NUITakeFromStore(obj)
    if not SynPending then
        SynPending = true

        obj = RD_NormalizeSynStorePayload(obj, "take")
        TriggerServerEvent("syn_store:TakeFromStore", json.encode(obj))
    end
end

function NUIService.OpenStoreInventory(StoreName, StoreId, capacity, geninfox)
    StoreSynMenu = true
    SynStoreLastStoreId = StoreId
    GenSynInfo   = geninfox or {}
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "store",
        title = StoreName,
        StoreId = StoreId,
        capacity = capacity,
        geninfo = GenSynInfo,
        search = Config.InventorySearchable
    })
    InInventory = true
    TriggerEvent("syn_store:setClosedInv", true)
end

function NUIService.OpenstealInventory(stealName, stealId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "steal",
        title = stealName,
        stealId = stealId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
    TriggerEvent("vorp_stables:setClosedInv", true)
end

function NUIService.NUIMoveTosteal(obj)
    TriggerServerEvent("syn_search:MoveTosteal", json.encode(obj))
end

function NUIService.NUITakeFromsteal(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("syn_search:TakeFromsteal", json.encode(obj))
    end
end

function NUIService.OpenCartInventory(cartName, wagonId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "cart",
        title = cartName,
        wagonid = wagonId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true

    TriggerEvent("vorp_stables:setClosedInv", true)
end

function NUIService.NUIMoveToCart(obj)
    TriggerServerEvent("vorp_stables:MoveToCart", json.encode(obj))
end

function NUIService.NUITakeFromCart(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("vorp_stables:TakeFromCart", json.encode(obj))
    end
end

function NUIService.OpenHouseInventory(houseName, houseId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "house",
        title = houseName,
        houseId = houseId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
end

function NUIService.NUIMoveToHouse(obj)
    TriggerServerEvent("vorp_housing:MoveToHouse", json.encode(obj))
end

function NUIService.NUITakeFromHouse(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("vorp_housing:TakeFromHouse", json.encode(obj))
    end
end

function NUIService.OpenHideoutInventory(hideoutName, hideoutId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "hideout",
        title = hideoutName,
        hideoutId = hideoutId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
end

function NUIService.NUIMoveToHideout(obj)
    TriggerServerEvent("syn_underground:MoveToHideout", json.encode(obj))
end

function NUIService.NUITakeFromHideout(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("syn_underground:TakeFromHideout", json.encode(obj))
    end
end

function NUIService.OpenBankInventory(bankName, bankId, capacity)
    ApplyPosfx()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "display",
        type = "bank",
        title = bankName,
        bankId = bankId,
        capacity = capacity,
        search = Config.InventorySearchable
    })
    InInventory = true
end

function NUIService.NUIMoveToBank(obj)
    TriggerServerEvent("vorp_bank:MoveToBank", json.encode(obj))
end

function NUIService.NUITakeFromBank(obj)
    if not SynPending then
        SynPending = true

        TriggerServerEvent("vorp_bank:TakeFromBank", json.encode(obj))
    end
end

Lang = "English"

Config = {

	EnablePushToTalk               = true, -- If true, the player can use push to talk to talk to other players while inventory is open

	-- ======================= DEVELOPMENT ============================== --
	Debug                          = false, -- If your server is live set this to false.  to true only if you are testing things

	InventoryOrder                 = "weapons", -- Items or weapons what should should first in inventory

	DevMode                        = false, -- If your server is live set this to false.  to true only if you are testing things (auto load inventory when script restart and before character selection. Alos add /getInv command)

	dbupdater                      = true,
	-- ======================= CONFIGURATION ============================= --
	AllowWalkingWhileInventoryOpen = true, -- If true, the player can walk while the inventory is open as ong they press and hold W key and press I to open inventory

	ShowCharacterNameOnGive        = true, -- When giving an item, show the character name of nearby players instead of their player ID. if set to false, show the player ID

	DoubleClickToUse               = false, -- If toggled to false, items in inventory will right click then left click "use"

	NewPlayers                     = false, -- If you dont want new players to give money or items then set to true. this can avoid cheaters giving stuff on first join

	CoolDownNewPlayer              = 120, -- In seconds how long they have to wait before they can give items or money

	-- GOLD ITEM LIKE DOLLARS
	UseRolItem                     = true, -- To show rol in inventory

	UseGoldItem                    = true,

	AddGoldItem                    = false,   -- Should there be an item in inventory to represent gold

	AddDollarItem                  = true,    -- Should there be an item in inventory to represent dollars

	AddAmmoItem                    = true,    -- Should there be an item in inventory to represent the gun belt

	InventorySearchable            = false,    -- Should the search bar appear in inventories

	InventorySearchAutoFocus       = false,    -- Search autoofocuses when you type

	DisableDeathInventory          = true,    -- Prevent the ability to access inventory while dead

	OpenKey                        = 0xC1989F95, -- I

	UseFilter                      = true,    -- If true then will use the filter opening inventory

	Filter                         = "OJDominoBlur",

	PickupKey                      = 0x760A9C6F, -- G key PROMPT PICKUP

	discordid                      = true,    -- Turn to true if ur using discord whitelist

	DeleteOnlyDontDrop             = false,   -- If true then dropping items only deletes from inventory and box on the floor is not created

	UseLanternPutOnBelt            = true,    -- If true then lanterns will be put on belt

	WeightMeasure                  = "kg",    -- Weight measure (kg, lbs, etc)

	DeleteItemOnUseWhenExpired     = false,   -- if true items on use that are expired will be deleted

	DeletePickups                  = {
		Enable = true, -- if true it will add timer to delete pickups
		Time = 5, -- after this time pick up wll be deleted, IN MINUTES
	},

	DuelWield                      = true, -- If true duel wielding will be allowed.

	SpamDelay                      = 2000, -- ms | The minimum time that must elapse between using one item and being able to use another item in the inventory.

	-- ==================== RD HOTBAR V2 PORT CONFIGURATION ==================== --
	-- ALT + 1/2/3/4/5 perdor slotet e hotbar-it. Kjo eshte portuar nga V2 qe punon mire.
	-- Nuk perdor RegisterKeyMapping ne RedM, ndaj nuk ben crash ne build-et ku mungon.
	Hotbar                         = {
		Enable = true,
		ENABLE = true,
		Slots = 5,
		SLOT_COUNT = 5,

		-- ALT hold key
		ModifierControl = `INPUT_SELECT_RADAR_MODE`,
		HOLD_KEY = `INPUT_SELECT_RADAR_MODE`,

		-- Si V2: hotbar del kur mban ALT dhe fshihet vet mbas pak sekondash.
		ShowWhileHoldingAlt = true,
		SHOW_WHEN_HOLD = true,

		-- Optional show/hide toggle, si V2. Lere nil nese s'e do.
		ToggleControl = `INPUT_EMOTE_GREET`, -- X
		TOGGLE_KEY = `INPUT_EMOTE_GREET`,
		EDIT_COMMAND = "hotbarpos",

		Allow = "all",
		ALLOW = "all",
		Keys = { "1", "2", "3", "4", "5" },
		SlotControls = {
			[1] = `INPUT_SELECT_QUICKSELECT_SIDEARMS_LEFT`,
			[2] = `INPUT_SELECT_QUICKSELECT_DUALWIELD`,
			[3] = `INPUT_SELECT_QUICKSELECT_SIDEARMS_RIGHT`,
			[4] = `INPUT_SELECT_QUICKSELECT_UNARMED`,
			[5] = `INPUT_SELECT_QUICKSELECT_MELEE_NO_UNARMED`,
		},
		SLOT_KEYS = {
			[1] = `INPUT_SELECT_QUICKSELECT_SIDEARMS_LEFT`,
			[2] = `INPUT_SELECT_QUICKSELECT_DUALWIELD`,
			[3] = `INPUT_SELECT_QUICKSELECT_SIDEARMS_RIGHT`,
			[4] = `INPUT_SELECT_QUICKSELECT_UNARMED`,
			[5] = `INPUT_SELECT_QUICKSELECT_MELEE_NO_UNARMED`,
		},

		UseOnly = true, -- hotbar nuk therret UnequipWeapon; ALT+1-5 eshte USE path
		USE_ONLY = true,
		DisableNativeQuickSelect = true, -- bllokon quick-select native kur mbahet ALT
		DISABLE_NATIVE_QUICKSELECT = true,
		UseCooldown = 180,
		USE_COOLDOWN = 180,
		AllowWhenInventoryOpen = false,
		ALLOW_WHEN_INVENTORY_OPEN = false,

		-- V2 option kept only for compatibility; hotbar path nuk perdor UnequipWeapon.
		HOSTER_WEAPONS_ON_UNEQUIP = false,
	},

	-- ==================== RD UI PERFORMANCE CONFIGURATION ==================== --
	UIPerformance                  = {
		Enable = true, -- true = hap/mbyll UI shpejt dhe ul efektet e renda pa prekur sistemin
		FastOpenClose = true, -- heq fade 200ms, inventory hapet direkt
		DisableJqueryAnimations = true, -- ndalon animacionet e panevojshme ne NUI
		FastFxDuration = 0, -- 0 = instant; vendose 80/120 nese do pak fade
		LightGlass = true, -- ul blur-in e rende glass per me shume FPS
		MaxBlur = 6, -- blur maksimal kur LightGlass eshte true
		DisableScreenFilter = true, -- fik OJDominoBlur/Animpostfx qe e ngadaleson hapjen
		DeferDragInit = true, -- render UI fillimisht, drag/drop ndizet pak ms me vone
		DragInitDelay = 35, -- ms; 20-60 eshte safe
		FitSlotExtraPasses = false, -- heq pass-et extra 80/220ms per slot-fit
	},

	-- ==================== SOUND CONFIGURATION ==================== --
	SFX                            = { -- Inventory Sound Effects
		OpenInventory = true,       -- The sound effect when open the inventory
		CloseInventory = true,      -- The sound effect when close the inventory
		ItemHover = true,           -- The sound effect when hovering the mouse cursor over an item/choose the item in the inventory

		ItemDrop = true,            -- The sound effect when drop the item
		MoneyDrop = true,           -- The sound effect when drop the money
		GoldDrop = true,            -- The sound effect when drop the gold
		PickUp = true,              -- The sound effect when pick up the item
	},

	-- ==================== ANIMATION CONFIGURATION ==================== --
	-- Animation configuration for different actions
	-- NOTE: Before adding animation test for female ped
	Animation = {
		Drop = {
			Item = {Enable = true, AnimDict = "amb_player@world_player_chore@bucket_put_down@male_a@base", AnimName = "base", Speed = 1.0, SpeedMultiplier = 8.0, Duration = -1, Flag = 1, ClearTaskTime = 1000},
			Weapon = {Enable = true, AnimDict = "amb_player@world_player_chore@box_put_down@male_a@base", AnimName = "base", Speed = 1.0, SpeedMultiplier = 8.0, Duration = -1, Flag = 1, ClearTaskTime = 1200},
			Money = {Enable = true, AnimDict = "mech_pickup@money@coins@table", AnimName = "2h_long_enter", Speed = 1.0, SpeedMultiplier = 8.0, Duration = -1, Flag = 1, ClearTaskTime = 500},
			Gold = {Enable = true, AnimDict = "mech_pickup@plant@gold_currant", AnimName = "enter_rf", Speed = 1.0, SpeedMultiplier = 8.0, Duration = -1, Flag = 1, ClearTaskTime = 1000},
		},
		PickUp = {Enable = true, AnimDict = "amb_work@world_human_box_pickup@1@male_a@stand_exit_withprop", AnimName = "exit_front", Speed = 1.0, SpeedMultiplier = 8.0, Duration = -1, Flag = 1, ClearTaskTime = 1200},
		-- TODO: Give/Take Item/Weapon(both user and target)
	},

	-- =================== CLEAR ITEMS WEAPONS MONEY GOLD ===================== --

	UseClearAll                    = false, -- If you want to use the clear item function

	OnPlayerRespawn                = {
		Money = {
			JobLock         = { "police", "doctor" }, -- Wont remove from these jobs
			ClearMoney      = true,          -- If true then removes all money from player
			MoneyPercentage = false,         -- If false wont use percentage if you add number   0.1 = 10% of money user have instead of all
		},
		Items = {
			JobLock       = { "police", "doctor" },
			itemWhiteList = { "consumable_raspberrywater", "ammorevolvernormal" }, -- Dont delete these items
			AllItems      = true,                                         -- If true then removes all items from player
		},
		Weapons = {
			JobLock           = { "police", "doctor" },
			WeaponWhitelisted = { "WEAPON_MELEE_KNIFE", "WEAPON_BOW" }, -- Dont delete these weapons
			AllWeapons        = true,                          -- If true then removes all weapons from player
		},
		Ammo = {
			JobLock = { "police", "doctor" }, -- Wont remove from these jobs
			AllAmmo = true,          -- If true then removes all ammo from player
		},
		Gold = {
			JobLock        = { "police", "doctor" },
			ClearGold      = false,
			GoldPercentage = false,
		}
	},

	-- HOW MANY WEAPONS ALLOWED PER PLAYER FOR ITEMS IS IN VORP CORE CONFIG
	MaxItemsInInventory            = {
		Weapons = 6,
	},

	-- HERE YOU CAN SET THE MAX AMOUNT OF WEAPONS PER JOB (IF YOU WANT)
	JobsAllowed                    = {
		police = 10 -- Job name and max weapons allowed dont allow less than the above
	},

	-- FIRST JOIN
	startItems                     = {
		consumable_raspberrywater = 2, -- ITEMS SAME NAME AS IN DATABASE
		ammorevolvernormal = 1   -- AMMO SAME NAME AS IN THE DATABASE
	},

	startWeapons                   = {
		"WEAPON_MELEE_KNIFE" -- WEAPON HASH NAME
	},

	-- Items that dont get added up torwards your max weapon count
	notweapons                     = {
		WEAPON_KIT_BINOCULARS_IMPROVED = true,
		WEAPON_KIT_BINOCULARS = true,
		WEAPON_FISHINGROD = true,
		WEAPON_KIT_CAMERA = true,
		WEAPON_KIT_CAMERA_ADVANCED = true,
		WEAPON_MELEE_LANTERN = true,
		WEAPON_MELEE_DAVY_LANTERN = true,
		WEAPON_MELEE_LANTERN_HALLOWEEN = true,
		WEAPON_KIT_METAL_DETECTOR = true,
		WEAPON_MELEE_HAMMER = true,
		WEAPON_MELEE_KNIFE = true,
	},

	-- Weapons that are considered non throwables
	nonAmmoThrowables              = {
		WEAPON_MELEE_CLEAVER = true,
		WEAPON_MELEE_HATCHET = true,
		WEAPON_MELEE_HATCHET_HUNTER = true
	},

	-- Weapons that dont need serial numbers
	noSerialNumber                 = {
		WEAPON_MELEE_KNIFE = true,
		WEAPON_MELEE_KNIFE_JAWBONE = true,
		WEAPON_MELEE_KNIFE_TRADER = true,
		WEAPON_MELEE_KNIFE_CIVIL_WAR = true,
		WEAPON_MELEE_KNIFE_HORROR = true,
		WEAPON_MELEE_KNIFE_MINER = true,
		WEAPON_MELEE_KNIFE_RUSTIC = true,
		WEAPON_MELEE_KNIFE_VAMPIRE = true,
		WEAPON_MELEE_MACHETE = true,
		WEAPON_MELEE_MACHETE_COLLECTOR = true,
		WEAPON_MELEE_HAMMER = true,
		WEAPON_MELEE_TORCH = true,
		WEAPON_MELEE_CLEAVER = true,
		WEAPON_MELEE_HATCHET = true,
		WEAPON_MELEE_HATCHET_HUNTER = true,
		WEAPON_MELEE_HATCHET_DOUBLE_BIT = true,
		WEAPON_KIT_BINOCULARS_IMPROVED = true,
		WEAPON_KIT_BINOCULARS = true,
		WEAPON_KIT_CAMERA = true,
		WEAPON_KIT_CAMERA_ADVANCED = true,
		WEAPON_KIT_METAL_DETECTOR = true,
		WEAPON_MELEE_LANTERN = true,
		WEAPON_MELEE_DAVY_LANTERN = true,
		WEAPON_MELEE_LANTERN_HALLOWEEN = true,
		WEAPON_FISHINGROD = true,
		WEAPON_BOW = true,
		WEAPON_BOW_IMPROVED = true,
		WEAPON_LASSO = true,
		WEAPON_LASSO_REINFORCED = true,
		WEAPON_MOONSHINEJUG_MP = true,
	},

	UseWeaponModels                = true, -- If true, weapons will spawn with a model other wise they default to the default_box prop
	-- for dropped weapons , some will spawn standing so we modify their rotation
	weaponAdjustments              = {
		WEAPON_MELEE_KNIFE = 90.0,
		WEAPON_BOW = 90.0,
		WEAPON_BOW_IMPROVED = 90.0,
		WEAPON_MELEE_KNIFE_RUSTIC = 90.0,
		WEAPON_MELEE_KNIFE_HORROR = 90.0,
		WEAPON_MELEE_KNIFE_CIVIL_WAR = 90.0,
		WEAPON_MELEE_KNIFE_JAWBONE = 90.0,
		WEAPON_MELEE_KNIFE_MINER = 90.0,
		WEAPON_MELEE_KNIFE_VAMPIRE = 90.0,
		WEAPON_MELEE_HATCHET = 90.0,
		WEAPON_MELEE_HATCHET_HUNTER = 90.0,
		WEAPON_MELEE_HATCHET_DOUBLE_BIT = 90.0,
		WEAPON_MELEE_MACHETE_COLLECTOR = 90.0,
		WEAPON_MELEE_MACHETE = 90.0,
		WEAPON_MELEE_CLEAVER = 90.0,
		WEAPON_MELEE_HAMMER = 90.0,
		WEAPON_FISHINGROD = 90.0,
		-- add here if more need to change rotation
	},

	-- dropp items can have a diferent model added them here item name and object
	spawnableProps                 = {
		default_box = "p_cottonbox01x", -- default when object is not found will always spawn this object for weapon or items
		money_bag = "p_moneybag02x", -- prop for the money pickup
		gold_bag = "s_pickup_goldbar01x", -- prop for the gold pickup
		-- add more here
	}
}


--==============================================================
-- RD storage/drop stability
--==============================================================
Config.RDStorageCleanStack = {
    Enabled = true,
    -- true = stash/storage limit counts occupied slots, not every item count.
    -- Same item + same metadata stacks into one slot and can be moved 1-by-1 without fake limit.
    SlotLimitInsteadOfItemCount = true,
    IgnoreStackLimitInStorage = true,
}


--==============================================================
-- RD item movement notifications (OX_LIB ONLY, top-center, item icon)
--==============================================================
Config.RDItemNotifications = {
    Enabled = true,
    Duration = 3200,
    MaxVisible = 4,
    Position = 'top',
    DedupeMs = 1200,
    -- OX ONLY: no custom NUI, no VORP black/right-tip duplicate.
    UseOxLibTextBackup = false,
    -- true = mos nxirr njoftimet e vjetra VORP për levizje item/give/storage
    -- sepse dalin duplicate me njoftimin e ri me PNG.
    DisableLegacyMovementSuccess = true,
    -- old custom NUI style disabled; ox_lib controls the final look.
    GlassStyle = false,
}

fx_version 'cerulean'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
author 'VORP'
name 'vorp inventory'
description 'Inventory System for RedM VORPCore framework'

lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  "config/config.lua",
  "config/rd_realistic_crafting.lua",
  "config/rd_craft_animations.lua",
  "config/groups.lua",
  "config/weapons.lua",
  "config/ammo.lua",
  "config/rd_custom_weapons.lua",
  "config/rd_custom_ammo.lua",
  "languages/*.lua",
  "shared/models/*.lua",
  'shared/handler/*.lua',
  "shared/services/*.lua",
  "shared/services/Regex.js",
}

client_scripts {
  'client/exports.lua',
  'client/client.lua',
  'client/rd_item_notifications.lua',
  'client/models/*.lua',
  'client/services/*.lua',
  'client/controllers/*.lua',
  'client/rd_realistic_crafting.lua',
  '@vorp_core/client/dataview.lua',
}

server_scripts {
  "config/logs.lua",
  '@oxmysql/lib/MySQL.lua',
  'server/vorpInventoryApi.lua',
  'server/server.lua',
  'server/models/*.lua',
  'server/rd_item_notifications.lua',
  'server/services/*.lua',
  'server/controllers/*.lua',
  'server/respawn.lua',
  'server/rd_realistic_crafting.lua',

}

files { 'html/**/*' }
ui_page 'html/ui.html'

---@deprecated
server_exports { 'vorp_inventoryApi' }


version '4.5'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'
vorp_github 'https://github.com/VORPCORE/vorp_inventory-lua'

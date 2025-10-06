ROOT_PATH = require('/download_files.lua').ROOT_PATH
inv = require(ROOT_PATH .. '/src/turtle/inv')

local itemName = 'minecraft:spruce_sampling'

print(inv.findItem(itemName))
print(inv.findEmptySlot())
print(inv.ensureAttached('computercraft:wireless_modem_normal', 'right'))
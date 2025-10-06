inv = require('/src/utils/inv')

local itemName = 'minecraft:spruce_sampling'

print(inv.findItem(itemName))
print(inv.findEmptySlot())
print(inv.ensureAttached('computercraft:wireless_modem_normal'))
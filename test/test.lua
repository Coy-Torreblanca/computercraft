inv = require('/repo/src/turtle/inv')

local itemName = 'minecraft:spruce_sampling'

print(inv.find_item(itemName))
print(inv.find_empty_slot())
print(inv.ensure_attached('computercraft:wireless_modem_normal', 'right'))
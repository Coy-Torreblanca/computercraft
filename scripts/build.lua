local start_coords = {x=16508, y=163, z=15790}
local end_coords = {x=16525, y=163, z=15770}

local inv = require('/repo/src/turtle/inv')
local shapes = require('/repo/src/move/shapes')

local function build(x, y, z, nav)

    local slot = inv.find_item('minecraft:cobblestone')

    if not slot then
        print("Add cobblestone to inventory and press enter to continue")
        read()
        slot = inv.find_item('minecraft:cobblestone')

        if not slot then
            error("Cobblestone not found in inventory")
        end

    end
    turtle.select(slot)

    turtle.placeDown()

end

shapes.rectangle(start_coords, end_coords, build)
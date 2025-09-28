
local function findItem(item_name)
    -- check current item slot.

    local item = turtle.getItemDetail()

    if (item and item.name == item_name) then
        return turtle.getSelectedSlot()
    end

    for i = 1, 16 do

        item = turtle.getItemDetail(i)

        if (item and item.name == item_name) then
            return turtle.getSelectedSlot()
        end
    end
end

# Chest Module

Interact with chests using CC: Tweaked's peripheral inventory API.

## Quick Start

```lua
local chest = require('/repo/src/chest/chest')

-- Get items (auto-detects chest)
local success, count = chest.get_item("minecraft:cobblestone", 32)

-- Deposit items (auto-detects chest)
chest.deposit_item("minecraft:dirt", 16)

-- Empty entire inventory (auto-detects chest)
chest.deposit_all()

-- Or specify explicit direction if needed
chest.get_item("minecraft:stone", 64, "bottom")
```

## Requirements

- Chest must be wrapped as a peripheral (adjacent or on wired network)
- Direction can be: `"front"`, `"back"`, `"left"`, `"right"`, `"top"`, `"bottom"`
- Or use peripheral names like `"minecraft:chest_0"` for networked chests
- If direction is `nil`, automatically finds any adjacent chest

## Module Integration

This module integrates with the `inv` module for inventory management:
- **`chest` module**: Chest interactions (get/deposit items from/to chests)
- **`inv` module**: Inventory queries (count, has, find slots)

This separation of concerns keeps code clean and avoids duplication.

```lua
local chest = require('/repo/src/chest/chest')
local inv = require('/repo/src/turtle/inv')

-- Check inventory using inv module
if inv.count_item("minecraft:coal") < 10 then
    -- Restock from chest using chest module
    chest.get_item("minecraft:coal", 32)
end

-- Find items and manage slots
local cobble_slot = inv.find_item("minecraft:cobblestone")
local empty_slot = inv.find_empty_slot()
local space_slot = inv.find_space_for_item("minecraft:dirt")
```

## API Reference

Uses CC: Tweaked's modern peripheral API ([Documentation](https://tweaked.cc/generic_peripheral/inventory.html))

### `chest.get_item(item_name, count, direction)`

Retrieve a specific item from a chest into turtle's inventory using `pushItems`.

**Parameters:**
- `item_name`: String - Full item name (e.g., `"minecraft:cobblestone"`)
- `count`: Number - How many items to get (default: 64)
- `direction`: String - Peripheral direction or name (default: `"front"`)
  - Directions: `"front"`, `"back"`, `"left"`, `"right"`, `"top"`, `"bottom"`
  - Or peripheral name: `"minecraft:chest_0"` for networked chests

**Returns:**
- `success`: Boolean - true if got all requested items
- `actual_count`: Number - How many items actually retrieved

**Example:**
```lua
-- Get 32 oak logs from chest in front
local success, count = chest.get_item("minecraft:oak_log", 32, "front")
if success then
    print("Got all 32 logs!")
else
    print("Only got " .. count .. " logs")
end
```

### `chest.deposit_item(item_name, count, direction)`

Deposit a specific item from turtle's inventory into a chest using `pullItems`.

**Parameters:**
- `item_name`: String - Full item name (required)
- `count`: Number - How many to deposit (optional, default: all available)
- `direction`: String or nil - Peripheral direction/name or nil for auto-detect
  - Directions: `"front"`, `"back"`, `"left"`, `"right"`, `"top"`, `"bottom"`
  - Peripheral name: `"minecraft:chest_0"`
  - `nil`: Auto-detect any adjacent chest

**Returns:**
- `success`: Boolean - true if deposited all requested items
- `actual_count`: Number - How many items actually deposited

**Examples:**
```lua
-- Deposit 64 cobblestone into any adjacent chest (auto-detect)
chest.deposit_item("minecraft:cobblestone", 64)

-- Deposit all dirt (no count specified)
chest.deposit_item("minecraft:dirt")

-- Deposit to specific direction
chest.deposit_item("minecraft:gravel", 32, "bottom")
```

### `chest.deposit_all(direction)`

Empty the entire turtle inventory into a chest using `pullItems`.

**Parameters:**
- `direction`: String or nil - Peripheral direction/name or nil for auto-detect
  - Directions: `"front"`, `"back"`, `"left"`, `"right"`, `"top"`, `"bottom"`
  - Peripheral name: `"minecraft:chest_0"`
  - `nil`: Auto-detect any adjacent chest

**Returns:**
- `total_deposited`: Number - How many slots were deposited

**Examples:**
```lua
-- Empty everything into any adjacent chest (auto-detect)
local slots = chest.deposit_all()
print("Emptied " .. slots .. " slots")

-- Or specify direction
chest.deposit_all("bottom")
```

### Inventory Helper Functions

For counting and checking items in turtle's inventory, use the `inv` module:

```lua
local inv = require('/repo/src/turtle/inv')

-- Count items in inventory
local cobble_count = inv.count_item("minecraft:cobblestone")

-- Check if turtle has enough
local has_fuel, count = inv.has_item("minecraft:coal", 10)

-- Find item slots
local slot = inv.find_item("minecraft:diamond")
local empty_slot = inv.find_empty_slot()
local space_slot = inv.find_space_for_item("minecraft:cobblestone")
```

See the `inv` module documentation for full inventory management API.

## Common Use Cases

### Restocking from a Supply Chest

```lua
local chest = require('/repo/src/chest/chest')
local inv = require('/repo/src/turtle/inv')

-- Check if we need torches
local torch_count = inv.count_item("minecraft:torch")
if torch_count < 64 then
    print("Need more torches, only have " .. torch_count)
    chest.get_item("minecraft:torch", 64)  -- Auto-detect chest
end
```

### Sorting Items

```lua
-- Deposit specific items into designated chests
chest.deposit_item("minecraft:cobblestone", nil, "bottom")  -- All cobble down
chest.deposit_item("minecraft:dirt", nil, "top")            -- All dirt up
chest.deposit_item("minecraft:gravel", nil, "front")        -- All gravel front
```

### Mining Operation with Auto-Deposit

```lua
local chest = require('/repo/src/chest/chest')
local inv = require('/repo/src/turtle/inv')

-- Mine until inventory full
while true do
    turtle.dig()
    turtle.forward()
    
    -- Check if inventory getting full
    if inv.get_empty_slots() < 3 then
        -- Return to chest and deposit
        print("Inventory full, returning to deposit")
        -- ... navigation code to return to base ...
        
        -- Deposit everything except tools
        chest.deposit_item("minecraft:cobblestone", nil, "front")
        chest.deposit_item("minecraft:dirt", nil, "front")
        -- Keep pickaxe, etc.
        
        -- ... navigation back to mining ...
    end
end
```

### Crafting with Precise Amounts

```lua
-- Get exact materials for crafting
chest.get_item("minecraft:stick", 2, "front")
chest.get_item("minecraft:diamond", 3, "front")

-- Craft diamond pickaxe
-- ... crafting code ...

-- Deposit the result
chest.deposit_item("minecraft:diamond_pickaxe", 1, "front")
```

### Fuel Management

```lua
local chest = require('/repo/src/chest/chest')

-- Check fuel level
if turtle.getFuelLevel() < 1000 then
    print("Low on fuel, restocking")
    
    -- Get coal from fuel chest
    local success, count = chest.get_item("minecraft:coal", 16, "bottom")
    
    if success then
        -- Refuel from inventory
        local inv = require('/repo/src/turtle/inv')
        inv.refuel(true)
    end
end
```

### Item Exchange Station

```lua
-- Take items from input chest, process, deposit to output chest

-- Get raw materials from input (below)
local got_iron, iron_count = chest.get_item("minecraft:raw_iron", 64, "bottom")

if got_iron then
    -- Smelt or process items
    -- ... processing code ...
    
    -- Deposit finished product to output (above)
    chest.deposit_item("minecraft:iron_ingot", iron_count, "top")
end
```

## Item Name Reference

Common item names (use F3+H in Minecraft to see full names):

**Blocks:**
- `minecraft:cobblestone`
- `minecraft:stone`
- `minecraft:dirt`
- `minecraft:sand`
- `minecraft:gravel`

**Ores:**
- `minecraft:coal`
- `minecraft:iron_ore`
- `minecraft:gold_ore`
- `minecraft:diamond`

**Wood:**
- `minecraft:oak_log`
- `minecraft:oak_planks`
- `minecraft:stick`

**Tools:**
- `minecraft:diamond_pickaxe`
- `minecraft:iron_shovel`

**Other:**
- `minecraft:torch`
- `minecraft:chest`
- `minecraft:crafting_table`

## Error Handling

All functions handle errors gracefully:
- Return `false` and actual count if operation fails
- Print helpful error messages
- Won't crash if chest is empty or full
- Safe to call repeatedly

## Pros & Cons

**Pros:**
- ✅ Uses modern CC: Tweaked peripheral API (v1.94.0+)
- ✅ Auto-detect feature for convenience (no direction needed)
- ✅ Precise item control by name and count
- ✅ Works with networked chests via wired modems
- ✅ Handles partial success gracefully
- ✅ Automatic slot management via `inv` module integration
- ✅ Respects stack limits and available space
- ✅ Simple, production-ready API

**Cons:**
- ❌ Requires knowing exact item names
- ❌ Chest must be accessible as a peripheral
- ❌ Limited by turtle's 16-slot inventory
- ❌ One chest operation at a time

## Tips

1. **Use F3+H** in Minecraft to see full item IDs
2. **Auto-detect is convenient** - omit direction parameter to find any adjacent chest
3. **Use inv module** for inventory queries (`count_item`, `has_item`, `find_item`)
4. **Check return values** - operations may partially succeed (returns actual count)
5. **No count = all** - omit count parameter to get/deposit all available
6. **Networked chests** - can access chests on wired network using peripheral names
7. **Stack limits respected** - automatically handles max stack sizes and slot space


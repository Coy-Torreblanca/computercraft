# Shapes Module

Move turtles through geometric areas and execute functions at each position.

## Quick Start

```lua
local shapes = require('/repo/src/move/shapes')

-- Simple: Just specify size from current position
shapes.rectangle_sized(16, 16, 1, function(x, y, z, nav)
    turtle.digDown()  -- Mine 16x16 area
    return true
end)

-- Or use the examples module for common tasks
local examples = require('/repo/src/move/shapes_examples')
examples.mine_area_sized(16, 16, 3)  -- Mine 16x16, 3 layers deep
```

## API Reference

### Simple Size-Based API (Recommended)

#### `shapes.rectangle_sized(width, depth, height, func, direction_x, direction_z, direction_y)`

The easiest way to work with shapes - just specify dimensions from current position.

**Parameters:**
- `width`: Blocks in X direction
- `depth`: Blocks in Z direction  
- `height`: Layers in Y direction
- `func`: Function called at each position
- `direction_x`: Optional, "positive" or "negative" (default: "positive")
- `direction_z`: Optional, "positive" or "negative" (default: "positive")
- `direction_y`: Optional, "positive" (up) or "negative" (down) (default: "positive")

**Example:**
```lua
-- Mine a 16x16 area, 3 layers UPWARD from current position
shapes.rectangle_sized(16, 16, 3, function(x, y, z, nav)
    turtle.digDown()
    return true
end, "positive", "positive", "positive")

-- Mine 16x16 area, 5 layers DOWNWARD (quarry style)
shapes.rectangle_sized(16, 16, 5, function(x, y, z, nav)
    turtle.digDown()
    return true
end, "positive", "positive", "negative")

-- Build going negative directions in all axes
shapes.rectangle_sized(10, 10, 3, function(x, y, z, nav)
    turtle.placeDown()
    return true
end, "negative", "negative", "negative")
```

#### `shapes.rectangle_at(x, y, z, width, depth, height, func, direction_x, direction_z, direction_y)`

Same as `rectangle_sized` but specify starting position instead of using current location.

**Example:**
```lua
-- Build at specific coordinates, going UP 5 layers
shapes.rectangle_at(100, 64, 200, 20, 20, 5, function(x, y, z, nav)
    turtle.placeDown()
    return true
end, "positive", "positive", "positive")

-- Mine downward from specific coordinates
shapes.rectangle_at(100, 70, 200, 16, 16, 10, function(x, y, z, nav)
    turtle.digDown()
    return true
end, "positive", "positive", "negative")
```

#### `shapes.hollow_rectangle_sized(width, depth, height, func, direction_x, direction_z, direction_y)`

Only visits perimeter/edges. Same parameters as `rectangle_sized`.

**Example:**
```lua
-- Build 30x30 walls, 10 blocks tall, going UP
shapes.hollow_rectangle_sized(30, 30, 10, function(x, y, z, nav)
    turtle.placeDown()
    return true
end, "positive", "positive", "positive")

-- Build walls going DOWN (foundation walls)
shapes.hollow_rectangle_sized(20, 20, 5, function(x, y, z, nav)
    turtle.placeDown()
    return true
end, "positive", "positive", "negative")
```

#### `shapes.hollow_rectangle_at(x, y, z, width, depth, height, func, direction_x, direction_z, direction_y)`

Hollow rectangle starting at specific position with direction control.

---

### Advanced Corner-Based API

#### `shapes.rectangle(corner1, corner2, func)`

Move through every position in a rectangular volume.

**Movement Pattern:**
- Layer by layer (Y axis)
- Serpentine/zigzag pattern (minimizes turns)
- Efficient fuel usage

**Parameters:**
- `corner1`: Table `{x, y, z}` - first corner
- `corner2`: Table `{x, y, z}` - opposite corner (order doesn't matter)
- `func`: Function called at each position

**Function Signature:**
```lua
function my_func(x, y, z, turtle_nav)
    -- x, y, z: Current position coordinates
    -- turtle_nav: Reference to nav module for advanced usage
    
    -- Your code here
    
    return true  -- Continue (false = abort)
end
```

**Returns:**
- `success`: Boolean - true if completed all positions
- `positions_visited`: Number of positions visited
- `total_positions`: Total positions in rectangle

**Example:**
```lua
local corner1 = {x = 0, y = 64, z = 0}
local corner2 = {x = 5, y = 67, z = 5}  -- 6x4x6 = 144 blocks

local function count(x, y, z, nav)
    print("At: " .. x .. "," .. y .. "," .. z)
    return true
end

local success, visited, total = shapes.rectangle(corner1, corner2, count)
print("Visited " .. visited .. "/" .. total)
```

### `shapes.hollow_rectangle(corner1, corner2, func)`

Move through only the perimeter/edges of a rectangular volume.

**Use Cases:**
- Building walls/frames
- Creating boundaries
- Scanning perimeters

**Parameters:** Same as `rectangle()`

**Returns:**
- `success`: Boolean
- `positions_visited`: Number of edge positions visited
- `total_positions`: Total edge positions

## Ready-to-Use Examples

The `shapes_examples.lua` module provides common use cases:

### Mining

```lua
local examples = require('/repo/src/move/shapes_examples')

-- Simple: Mine from current position
examples.mine_area_sized(16, 16, 3)  -- 16x16 area, 3 layers deep

-- Advanced: Using specific corners
local c1 = {x = 0, y = 64, z = 0}
local c2 = {x = 16, y = 64, z = 16}
examples.mine_area(c1, c2)
```

### Building

```lua
-- Build a 20x20 floor from current position
examples.build_floor_sized(20, 20, 1)  -- Use blocks from slot 1

-- Build 30x30 walls, 10 blocks tall
examples.build_walls_sized(30, 30, 10, 1)
```

### Farming

```lua
-- Harvest crops and replant
examples.harvest_crops(c1, c2)
```

### Lighting

```lua
-- Place torches in grid pattern
examples.light_area(c1, c2, 1, 8)  -- Slot 1, 8-block spacing
```

### Scanning

```lua
-- Detect all blocks in area
local blocks = examples.scan_area(c1, c2)
for _, block in ipairs(blocks) do
    print(block.x, block.y, block.z, block.name)
end
```

## Advanced Usage

### Early Abort

Return `false` from your function to stop iteration:

```lua
local found = false

local function find_diamond(x, y, z, nav)
    local has_block, data = turtle.inspectDown()
    
    if has_block and data.name == "minecraft:diamond_ore" then
        print("Found diamond at " .. x .. "," .. y .. "," .. z)
        found = true
        return false  -- Stop searching
    end
    
    return true  -- Keep going
end

shapes.rectangle(c1, c2, find_diamond)
```

### Using Navigation Module

Access `turtle_nav` functions within your callback:

```lua
local function complex_action(x, y, z, nav)
    -- Move to specific sub-position
    nav.move_up()
    turtle.dig()
    nav.move_down()
    
    return true
end
```

### Tracking Progress

```lua
local total = (c2.x - c1.x + 1) * (c2.y - c1.y + 1) * (c2.z - c1.z + 1)
local count = 0

local function with_progress(x, y, z, nav)
    count = count + 1
    local percent = math.floor((count / total) * 100)
    
    if count % 10 == 0 then
        print("Progress: " .. percent .. "% (" .. count .. "/" .. total .. ")")
    end
    
    -- Your actual work here
    turtle.digDown()
    
    return true
end
```

## Pattern Visualization

For a 4x2x3 rectangle, the movement pattern is:

```
Layer Y=0:
  →→→
  ←←←
  →→→
  ←←←

Layer Y=1:
  →→→
  ←←←
  →→→
  ←←←
```

This serpentine pattern:
- Minimizes turns (more efficient)
- Reduces fuel usage
- Faster completion time

## Error Handling

If the turtle gets blocked:

```lua
local success, visited, total = shapes.rectangle(c1, c2, my_func)

if not success then
    print("Failed! Only completed " .. visited .. "/" .. total .. " positions")
    -- Handle partial completion
end
```

## Pro Tips

1. **Fuel Management**: The turtle refuels automatically (via `turtle_nav`), but ensure adequate fuel is available
2. **Inventory Space**: For mining/harvesting, ensure empty slots or use `inv.dump_to_chest()`
3. **GPS Required**: All movement uses GPS-based navigation
4. **Clear Paths**: Pathfinding will fail if all axes are blocked
5. **Save State**: For large operations, periodically save progress in case of crashes

## Performance

- **Small areas** (< 100 blocks): Instant
- **Medium areas** (< 1000 blocks): Minutes
- **Large areas** (> 10,000 blocks): May take hours

For very large operations, consider breaking into chunks and resuming if interrupted.


Add a new consumable item to the game: $ARGUMENTS

## Prerequisites
- Know the item's name, effects, and logical category

## Steps

### 1. Create the item resource file

Create `resources/items/<item-name>.tres`:

```tres
[gd_resource type="Resource" script_class="Item" load_steps=2 format=3 uid="uid://unique_id"]

[ext_resource type="Script" path="res://scripts/item.gd" id="1"]

[resource]
script = ExtResource("1")
name = "Item Name"
description = "What this item does"
belly_restore = 0
hydration_restore = 0
sobriety_change = 0
vitamin_c = 0
value = 5
weight = 1.0
```

### 2. Configure item effects

| Property | Purpose | Example values |
|----------|---------|----------------|
| `belly_restore` | Hunger restored | 10-50 for food |
| `hydration_restore` | Thirst restored | 10-30 for drinks |
| `sobriety_change` | -N = more drunk | -20 for rum |
| `vitamin_c` | Scurvy prevention | 10-30 for citrus |
| `value` | Silver worth | 1-100 |
| `weight` | Carry burden | 0.1-5.0 |

### 3. Add icon (optional)

Place icon in `sprites/items/<item-name>.png` and set path in resource.

### 4. Test in-game

1. Add item to player inventory manually or via debug
2. Use item and verify survival stats change
3. Check that item is consumed properly

## Example: Adding Citrus Fruit

```tres
[gd_resource type="Resource" script_class="Item" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/item.gd" id="1"]

[resource]
script = ExtResource("1")
name = "Lime"
description = "Fresh citrus. Prevents scurvy."
belly_restore = 5
hydration_restore = 5
vitamin_c = 25
value = 8
weight = 0.2
```

## Validation Checklist

- [ ] `.tres` file created with correct script reference
- [ ] All relevant properties filled
- [ ] Item appears in inventory when added
- [ ] Consuming item modifies correct survival stats
- [ ] Item removed from inventory after consumption

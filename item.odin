package Atalay

import rl "vendor:raylib"

Item_Data :: struct {
	title: cstring,
	sprite_dir: vec2i,
	description: cstring
}

Item :: struct {
	id: u32,
	item_data: ^Item_Data,

	name: cstring,
	
	// stack_count: u32
}

valid_item_id: u32 = 0
get_item_id :: proc() -> u32 {
	valid_item_id += 1
	return valid_item_id
}

draw_item :: proc(pos: vec3i, sprite_dir: vec2i) {
	source: rl.Rectangle = {
		f32(sprite_dir.x), f32(sprite_dir.y),
		item_pixel_size, item_pixel_size
	}

	dest: rl.Rectangle = {
		f32(pos.x) * tile_pixel_size, f32(pos.z) * tile_pixel_size,
		item_pixel_size, item_pixel_size
	}

	rl.DrawTexturePro(item_atlas, source, dest, {0, 0}, 0, rl.WHITE)
}

place_item_in_world :: proc(item: Item, pos: vec3i) -> bool {
	if pos not_in terrain_world {
		return false
	}

	terrain_cell := &terrain_world[pos]
	append(&terrain_cell.items, item)

	return true
}

// Return true if free slot, false if full of items
check_empty_slot :: proc(inventory: ^[dynamic]Slot) -> bool {
	for slot in inventory {
		switch item_type in slot.item_type {
			case Item:
			case Null_Item:
				return true
			}	
	}

	return false
}

place_item_in_inventory :: proc(item: Item, inventory: ^[dynamic]Slot) {
	for &slot in inventory {
		switch item_type in slot.item_type {
			case Item:
			case Null_Item:
				slot.item_type = item
				return 
			}	
	}
}

remove_item_from_terrain :: proc(item_id: u32, pos: vec3i) {
	terrain_cell := &terrain_world[pos]

	for item, i in terrain_cell.items {
		if item.id == item_id {
			ordered_remove(&terrain_cell.items, i)
			return
		}
	}
}

// Inventory
Slot :: struct {
	name: cstring,

	item_type: union {
		Item,
		Null_Item
	}
}

Null_Item :: struct { }

//// Items Datas
rock_item_data: Item_Data = {
	title = "Rock",
	sprite_dir = rock,
	description = "Blueish Stone."
}
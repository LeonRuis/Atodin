package Atalay

import fmt "core:fmt"
import rl "vendor:raylib"

items: map[u32]Item

Item_Data :: struct {
	title: cstring,
	sprite_dir: vec2i,
	description: cstring,

	type: union {
		Item_Misc,
		Item_Food
	}
}

Item :: struct {
	id: u32,
	sprite_dir: ^vec2i,

	name: cstring,

	type: union {
		Item_Misc,
		Item_Food
	}
}

// Items Types
Item_Misc :: struct { }
Item_Food :: struct { 
	calories: f32,
	max_calories: f32,
	vitamin: cstring
}

//

valid_item_id: u32 = 0
get_item_id :: proc() -> u32 {
	valid_item_id += 1
	return valid_item_id
}

create_item_from_item_data :: proc(item_data: ^Item_Data) -> u32 {
	ID := get_item_id()
	new_item: Item = {
		id = ID,
		sprite_dir = &item_data.sprite_dir,

		name = item_data.title,

		type = item_data.type
	}

	items[ID] = new_item
	return ID
}

draw_item :: proc(pos: vec3i, sprite_dir: vec2i) {
	source: rl.Rectangle = {
		f32(sprite_dir.x) * item_pixel_size, f32(sprite_dir.y) * item_pixel_size,
		item_pixel_size, item_pixel_size
	}

	dest: rl.Rectangle = {
		f32(pos.x) * tile_pixel_size, f32(pos.z) * tile_pixel_size,
		item_pixel_size, item_pixel_size
	}

	rl.DrawTexturePro(item_atlas, source, dest, {0, 0}, 0, rl.WHITE)
}

place_item_in_world :: proc(item_id: u32, pos: vec3i) -> bool {
	if pos not_in terrain_world {
		return false
	}

	terrain_cell := &terrain_world[pos]
	append(&terrain_cell.items, item_id)

	return true
}

// Return true if free slot, false if full of items
check_empty_slot :: proc(inventory: ^[dynamic]Slot) -> bool {
	for slot in inventory {
		switch item_type in slot.item_type {
			case u32:
			case Null_Item:
				return true
		}	
	}

	return false
}

// Return true if item is in inventory 
check_item_in_inventory :: proc(item_id: u32, inventory: ^[dynamic]Slot) -> bool {
	for slot in inventory {
		switch item_type in slot.item_type {
			case Null_Item:
			case u32:
				if item_id == item_type {
					return true
				}
		}	
	}

	return false
}

place_item_in_inventory :: proc(item_id: u32, inventory: ^[dynamic]Slot) {
	for &slot in inventory {
		switch item_type in slot.item_type {
			case u32:
			case Null_Item:
				slot.item_type = item_id
				return 
			}	
	}
}

remove_item_from_inventory :: proc(item_id: u32, inventory: ^[dynamic]Slot) {
	for &slot in inventory {
		switch item_type in slot.item_type {
			case Null_Item:
			case u32:
				if item_type == item_id {
					slot.item_type = Null_Item {}
				}
			}	
	}
}

remove_item_from_terrain :: proc(item_id: u32, pos: vec3i) {
	terrain_cell := &terrain_world[pos]

	for item_id, i in terrain_cell.items {
		if item_id == item_id {
			ordered_remove(&terrain_cell.items, i)
			return
		}
	}
}

// Inventory
Slot :: struct {
	name: cstring,

	item_type: union {
		u32,
		Null_Item
	}
}

Null_Item :: struct { }

//// Items Datas
rock_item_data: Item_Data = {
	title = "Rock",
	sprite_dir = rock,
	description = "Blueish Stone.",

	type = Item_Misc { }
}

stick_item_data: Item_Data = {
	title = "Stick",
	sprite_dir = stick,
	description = "The wooden primary.",

	type = Item_Misc { }
}

carrot_item_data: Item_Data = {
	title = "Carrot",
	sprite_dir = carrot_item,
	description = "Basic Veggie.",

	type = Item_Food { 50, 50, "C" }
}
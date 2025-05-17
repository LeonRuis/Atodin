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
	item_data: ^Item_Data,

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
	vitamin: cstring
}

//

valid_item_id: u32 = 0
get_item_id :: proc() -> u32 {
	valid_item_id += 1
	return valid_item_id
}

get_item_from_item_data :: proc(item_data: ^Item_Data) -> Item {
	new_item: Item = {
		id = get_item_id(),
		item_data = item_data,

		name = item_data.title,

		type = item_data.type
	}

	return new_item
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

// Return true if item is in inventory 
check_item_in_inventory :: proc(item: Item, inventory: ^[dynamic]Slot) -> bool {
	for slot in inventory {
		switch item_type in slot.item_type {
			case Null_Item:
			case Item:
				if item.id == item_type.id {
					return true
				}
		}	
	}

	return false
}

bite_item_food :: proc(item: Item) -> Item {
	#partial switch &data_type in item.type {
		case Item_Food:
			data_type.calories -= 10
	}

	return item
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

remove_item_from_inventory :: proc(item: Item, inventory: ^[dynamic]Slot) {
	for &slot in inventory {
		switch item_type in slot.item_type {
			case Null_Item:
			case Item:
				if item_type.id == item.id {
					slot.item_type = Null_Item {}
				}
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

	type = Item_Food { 40, "C" }
}
package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import strings "core:strings"
import rl "vendor:raylib"

plants_order: [dynamic]u32
plants: map[u32]Plant

Plant :: struct {
	id: u32,
	pos: vec3i,
	plant_data: ^Plant_Data,

	items_to_give: u32,
}

Plant_Data :: struct {
	title: cstring,
	sprite_dir: vec2i,

	item_data: ^Item_Data
}

valid_plant_id: u32 = 0
get_plant_id :: proc() -> u32 {
	valid_plant_id += 1
	return valid_plant_id
}

plants_update :: proc() {
	for id in plants_order {
		plant := &plants[id]

		update_plant(plant)
	}
}

update_plant :: proc(plant: ^Plant) {

}

create_plant :: proc(plant_data: ^Plant_Data, pos: vec3i) {
	ID := get_plant_id()
	new_plant: Plant = {
		id = ID,
		pos = pos,
		plant_data = plant_data,

		items_to_give = 4,
	}

	place_plant_in_world(ID, pos)

	plants[ID] = new_plant
	append(&plants_order, ID)
}

remove_plant :: proc(plant_id: u32) {
	if plant_id not_in plants {
		return
	}

	terrain_cell := &terrain_world[plants[plant_id].pos]
	terrain_cell.plant = null_id 

	delete_key(&plants, plant_id)

	for p_id, i in plants_order {
		if p_id == plant_id {
			ordered_remove(&plants_order, i)
			return
		}
	}
}

place_plant_in_world :: proc(plant_id: u32, pos: vec3i) {
	if pos not_in terrain_world {
		return
	}

	if terrain_world[pos].plant != null_id {
		return
	}

	terrain_cell := &terrain_world[pos]
	terrain_cell.plant = plant_id
}

// Datas
carrot_plant_data: Plant_Data = {
	title = "Carrots",
	sprite_dir = carrot_plant,
	item_data = &carrot_item_data
}

//
draw_plant :: proc(sprite_dir: vec2i, world_pos: vec3i) {
	source: rl.Rectangle = {
		f32(sprite_dir.x) * plant_pixel_size, f32(sprite_dir.y) * plant_pixel_size,
		plant_pixel_size, plant_pixel_size	
	}	

	dest: rl.Rectangle = {
		f32(world_pos.x) * tile_pixel_size, f32(world_pos.z) * tile_pixel_size,
		tile_pixel_size, tile_pixel_size
	}

	rl.DrawTexturePro(plant_atlas, source, dest, {0, 0}, 0, rl.WHITE)

}
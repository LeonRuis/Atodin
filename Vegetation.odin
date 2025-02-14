package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"

Plant_Data :: struct {
	max_grow: int,

	min_temp: int,
	max_temp: int,

	min_moist: int,
	max_moist: int,

	model: rl.Model,
	calories: int
}

Plant_World :: struct {
	grow: int,
	calories: int,
	seeding: bool,

	data: Plant_Data,
}

carrot_data: Plant_Data = {
	max_grow = 1000,

	min_temp = -45,
	max_temp = 20,

	min_moist = 15,
	max_moist = 50,

	model = {},

	calories = 1000
}

plants: map[vec3i]Plant_World
edible_plants: [dynamic]vec3i

// Directions for seeding 
seeding_dirs: [8]vec3i = {
	N + E,
	N + W,
	N,

	S + E,
	S + W,
	S,

	E,
	W
}

update_plants :: proc() {
	for key_pos, &plant in plants {
		plant.grow += 1 

		if plant.grow > 0 && plant.grow < 100 {
			// fmt.println("Seed state")
		} else if plant.grow > 100 && plant.grow < 200 {
			// fmt.println("Sprout State")
		} else if plant.grow >= 200 && plant.grow < 300 {
			// fmt.println("Veggie State")
			if plant.grow == 200 {
				append(&edible_plants, key_pos)
			}
		} else if plant.grow > 300 && plant.grow < plant.data.max_grow {
			if plant.grow == 301 {
				plant.seeding = true
			}

			// fmt.println("Seeding State")
			for dir in seeding_dirs {
				this_pos := key_pos + dir
				this_pos_2d: vec2i = {this_pos.x, this_pos.z}

				if this_pos_2d in terrain && this_pos not_in plants && plant.seeding && get_validation_plant_in_pos(plant.data, this_pos) {
					plant.seeding = false
					patch_behavior(this_pos, plant.data, 5)
					// create_plant_world(this_pos, plant.data)
					fmt.println("Vegetation/85: Planted")
					return
				}
			}
		} else if plant.grow > plant.data.max_grow{
			delete_plant_world(key_pos)
		}
	}
}

repel_plant :: proc(radius: f32, plant_pos: vec3i) -> bool {
	circle_center: vec3 = to_v3(plant_pos) 

	for x in -radius + 1..< radius {
		for z in -radius + 1..< radius {
			radius_pos: vec3 = {f32(x), 0, f32(z)}
			this_pos: vec3i = {int(x), 0, int(z)} + plant_pos

			if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (radius * radius) {
				if this_pos in plants {
					return false
				}
			}
		}
	}

	return true
}

patch_behavior :: proc(center: vec3i, p_data: Plant_Data, limit: int) {
	if center in plants || !get_validation_plant_in_pos(p_data, center) {
		fmt.println("not_valid")
		return
	}

	visited_pos: map[vec3i]bool

	repel_radius: f32 = 25
	plant_radius: f32 =	7 

	patch_limit: int = limit // if want 3, place a 4

	count: int = 0

	for r in 0..<repel_radius {
		for x in -r + 1..< r {
			for z in -r + 1..< r {
				radius_pos: vec3 = {f32(x), 0, f32(z)}
				this_pos: vec3i = {int(x), 0, int(z)} + center 

				if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (r * r) {
					if this_pos == center || this_pos in visited_pos {
						continue
					}

					visited_pos[this_pos] = true

					if this_pos in plants {
						count += 1
						fmt.println(this_pos)
					}

					if count >= patch_limit {
						fmt.println(count)
						return
					}
				}
			}
		}
	}

	create_plant_world(center, p_data)
	count += 1

	for r in 0..<plant_radius {
		for x in -r + 1..< r {
			for z in -r + 1..< r {
				radius_pos: vec3 = {f32(x), 0, f32(z)}
				this_pos: vec3i = {int(x), 0, int(z)} + center 

				if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (r * r) {
					if this_pos == center {
						continue
					}

					if count >= patch_limit {
						fmt.println(count)
						return
					}

					if get_validation_plant_in_pos(p_data, this_pos) {
						count += 1
						create_plant_world(this_pos, p_data)
					}
				}
			}
		}
	}
}


get_validation_plant_in_pos :: proc(plant_data: Plant_Data, pos: vec3i) -> bool {
	pos2d: vec2i = {pos.x, pos.z}
	if pos2d not_in terrain {
		return false
	}

	temp: bool = false
	moist: bool = false

	cell := &terrain[{pos.x, pos.z}]

	if cell.temp > plant_data.min_temp && cell.temp < plant_data.max_temp {
		temp = true
	}

	if cell.moist > plant_data.min_moist && cell.moist < plant_data.max_moist {
		moist = true
	}		

	if temp && moist {
		return true
	}

	return false
}

// init plants in world
init_some_plants :: proc() {
	//  Init Plants Datas Models
	carrot_data.model = carrots_model

	positions: int = 1 
	count: int = 0

	plant_data: Plant_Data = carrot_data

	for key_pos, cell in terrain {
		pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

		if get_validation_plant_in_pos(plant_data, pos) && count < positions{

			patch_behavior(pos, plant_data, 3)
			count += 1
		}
	}	
}

draw_plants :: proc() {
	for key_pos, plant in plants {
		rl.DrawModelEx(
			plant.data.model,
			to_v3(to_visual_world(key_pos)) + {0.5, 0, 0.5}, 
			{0, 0, 0},
			0,
			1,
			rl.WHITE
		)	

		rl.DrawCubeWiresV(to_v3(to_visual_world(key_pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.ORANGE)	
	}
}

// --------------- Plant Actions ----------------------------
delete_plant_world :: proc(pos: vec3i) {
	fmt.println("Delete Plant")
	delete_key(&plants, pos)

	for ed_plnt, i in edible_plants {
		if ed_plnt == pos {
			unordered_remove(&edible_plants, i)
		}
	}
}


create_plant_world :: proc(pos: vec3i, plant_data: Plant_Data) {

	new_plant: Plant_World = {
		grow = rand.int_max(199), 
		calories = 1000,
		seeding = false,
		data = plant_data
	}

	plants[pos] = new_plant
}
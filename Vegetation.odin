package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

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
	data: Plant_Data
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

update_plants :: proc() {
	for key_pos, &plant in plants {
		plant.grow += 1 

		if plant.grow > 0 && plant.grow < 100 {
			fmt.println("Seed state")
		} else if plant.grow > 100 && plant.grow < 200 {
			fmt.println("Sprout State")
		} else if plant.grow >= 200 && plant.grow < 500 {
			fmt.println("Veggie State")
			if plant.grow == 200 {
				append(&edible_plants, key_pos)
			}
		} else if plant.grow > 500 && plant.grow < plant.data.max_grow {
			fmt.println("Seeding State")
		}

		// switch plant.grow {
		// 	case plant.grow < 100:
		// 		fmt.println("Seed state")

		// 	case plant.grow < 200:
		// 		fmt.println("Sprout State")

		// 	case plant.grow < 300: 
		// 		fmt.println("Veggie State")

		// 		if plant.grow == 299 {
		// 			append(&edible_plants, key_pos)
		// 		}

		// 	case plant.grow < 500: 
		// 		fmt.println("Seeding State")

		// 	case plant.grow > plant.data.max_grow: 
		// 		fmt.println("Plant Dead")
		// 		delete_key(&plants, key_pos)
		// 		for ed_plnt, i in edible_plants {
		// 			unordered_remove(&edible_plants, i)
		// 		}
		// }
	}
}

repel_plant_cactus :: proc(radius: f32, plant_pos: vec3i) -> bool {
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

// plant_patch_carrot :: proc(plant_data: ^Plant_Data) {
// 	group_size: int = 4
// 	current_count: int = 0
// 	radius: f32 = 4

// 	for key_pos, cell in terrain {
// 		for x in -radius + 1..< radius {
// 			for z in -radius + 1..< radius {
// 				radius_pos: vec3 = {f32(x), 0, f32(z)}
// 				this_pos: vec3i = {int(x), 0, int(z)} + {key_pos.x, cell.floor_height, key_pos.y} 

// 				if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (radius * radius) {
// 					if this_pos in world && {this_pos.x, this_pos.z} in terrain && this_pos not_in plants {
// 						if get_validation_plant_in_pos(&carrot_data, this_pos) {
// 							if current_count <= group_size {
// 								new_plant: Plant_World = {
// 									0, 
// 									plant_data.model,
// 									plant_data.calories_per_tic,
// 									plant_data.tics_to_end
// 								}

// 								plants[this_pos] = new_plant

// 								current_count += 1
// 							} else {
// 								return
// 							}
// 						}
// 					}
// 				}
// 			}
// 		}
// 	}
// }

get_validation_plant_in_pos :: proc(plant_data: ^Plant_Data, pos: vec3i) -> bool {
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
	// plants_to_init: int = 1	
	carrot_data.model = carrots_model

	plant_data: Plant_Data = carrot_data

	for key_pos, cell in terrain {
		pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

		no_plant := repel_plant_cactus(35, pos)

		if get_validation_plant_in_pos(&plant_data, pos) && no_plant{
			new_plant: Plant_World = {
				0, 
				1000,
				plant_data
			}

			plants[pos] = new_plant
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

// la funcion no tiene un buen nombre
// init_plant_in_world :: proc(plant: ^Plant) {
// 	for key_pos, cell in terrain {
// 		temp: bool = false
// 		moist: bool = false

// 		if cell.temp > plant.min_temp && cell.temp < plant.max_temp {
// 			temp = true
// 		}

// 		if cell.moist > plant.min_moist && cell.moist < plant.max_moist {
// 			moist = true
// 		}

// 		if temp && moist {
// 			plants[{key_pos.x, cell.floor_height, key_pos.y}] = 1
// 		}
// 	}
// }

// draw_plants :: proc() {
// 	for key_pos, value in plants {

// 		if value == 1 {
// 			rl.DrawCubeV(
// 				to_v3(to_visual_world(key_pos)) + {0.5, 0.5, 0.5} , 
// 				{1, 1, 1},
// 				rl.ORANGE
// 				)	
// 		}
// 	}
// }



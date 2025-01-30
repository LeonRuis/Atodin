package Atalay

import rl "vendor:raylib"

Plant_Data :: struct {
	max_grow: int,

	min_temp: int,
	max_temp: int,

	min_moist: int,
	max_moist: int,

	color: rl.Color,
	type: Plant_Types
}

Plant_World :: struct {
	grow: int,
	color: rl.Color,
	type: Plant_Types
}

Plant_Types :: enum {
	CARROT,
	CACTUS,
}

carrot_data: Plant_Data = {
	1000,

	-45,
	20,

	15,
	50,

	rl.ORANGE,
	.CARROT
}

cactus_data: Plant_Data = {
	1000,

	1,
	100,

	-70,
	10,

	rl.GREEN,
	.CACTUS
}

plants: map[vec3i]Plant_World

plants_datas: [2]Plant_Data = {
	carrot_data,
	cactus_data,
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

plant_patch_carrot :: proc(plant_data: ^Plant_Data) {
	group_size: int = 4
	current_count: int = 0
	radius: f32 = 4

	for key_pos, cell in terrain {
		for x in -radius + 1..< radius {
			for z in -radius + 1..< radius {
				radius_pos: vec3 = {f32(x), 0, f32(z)}
				this_pos: vec3i = {int(x), 0, int(z)} + {key_pos.x, cell.floor_height, key_pos.y} 

				if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (radius * radius) {
					if this_pos in world && {this_pos.x, this_pos.z} in terrain && this_pos not_in plants {
						if get_validation_plant_in_pos(&carrot_data, this_pos) {
							if current_count <= group_size {
								new_plant: Plant_World = {
								0, 
								plant_data.color,
								plant_data.type
								}

								plants[this_pos] = new_plant

								current_count += 1
							} else {
								return
							}
						}
					}
				}
			}
		}
	}
}

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
	plant_data: ^Plant_Data = &carrot_data

	for key_pos, cell in terrain {
		pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

		no_plant := repel_plant_cactus(35, pos)

		if get_validation_plant_in_pos(plant_data, pos) && no_plant{
			new_plant: Plant_World = {
				0, 
				plant_data.color,
				plant_data.type
			}

			plants[pos] = new_plant
		}
	}	
}

draw_plants :: proc() {
	for key_pos, plant in plants {
		rl.DrawCubeV(
			to_v3(to_visual_world(key_pos)) + {0.5, 0.5, 0.5} , 
			{1, 1, 1},
			plant.color,
		)	
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



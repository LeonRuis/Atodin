package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"

PlantData :: struct {
	conditions: [dynamic]proc(pos: vec3i) -> bool,

	low_temp: int,
	high_temp: int,

	low_moist: int,
	high_moist: int,

	game_model: ^GameModel,
	stages: [dynamic]Stage
}

PlantInstance :: struct {
	visual_instance: VisualInstance,

	calories: int,
	seeding: bool,

	data: ^PlantData,

	grow: int,
	stages: [dynamic]Stage
}

// 
carrot_data: PlantData = {
	conditions = {},

	low_temp = -45,
	high_temp = 20,

	low_moist = 15,
	high_moist = 50,

	game_model = &Carrots_GameModel,

	stages = {
		{stage_type=SeedStage{}, init=false, calories=0, to_end_stage=100},
		{stage_type=SproutStage{}, init=false, calories=0, to_end_stage=50},
		{stage_type=VeggieStage{0, 200}, init=false, calories=400, to_end_stage=1000},
	}
}

foliage_data: PlantData = {
	conditions = {
		condition_in_grass	
	},

	low_temp = -70,
	high_temp = 70,

	low_moist = -20,
	high_moist = 70,

	game_model = &Long_Grass_GameModel,

	stages = {
		{stage_type=SeedStage{}, init=false, calories=0, to_end_stage=100},
		{stage_type=LongStage{}, init=false, calories=10, to_end_stage=10000},
	}
}

Stage :: struct {
	stage_type: union {
		SeedStage,
		SproutStage,
		VeggieStage,
		LongStage
	},

	init: bool,

	calories: int,
	to_end_stage: int,
}

SeedStage :: struct {}
SproutStage :: struct {}
VeggieStage :: struct {
	veggie_grow: int,
	to_grow_veggie: int 
}
LongStage :: struct {}


plants: map[vec3i]PlantInstance
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
		control_plant_stages(&plant)
		// plant.grow += 1 

		// if plant.grow > 0 && plant.grow < 100 {
		// 	// fmt.println("Seed state")
		// } else if plant.grow > 100 && plant.grow < 200 {
		// 	// fmt.println("Sprout State")
		// } else if plant.grow >= 200 && plant.grow < 300 {
		// 	// fmt.println("Veggie State")
		// 	if plant.grow == 200 {
		// 		append(&edible_plants, key_pos)
		// 	}
		// } else if plant.grow > 300 && plant.grow < plant.data.max_grow {
		// 	if plant.grow == 301 {
		// 		plant.seeding = true
		// 	}

		// 	// fmt.println("Seeding State")
		// 	for dir in seeding_dirs {
		// 		this_pos := key_pos + dir
		// 		this_pos_2d: vec2i = {this_pos.x, this_pos.z}

		// 		if this_pos_2d in terrain && this_pos not_in plants && plant.seeding && get_validation_plant_in_pos(plant.data, this_pos) {
		// 			plant.seeding = false
		// 			patch_behavior(this_pos, plant.data, 5)
		// 			// create_plant_world(this_pos, plant.data)
		// 			fmt.println("Vegetation/85: Planted")
		// 			return
		// 		}
		// 	}
		// } else if plant.grow > plant.data.max_grow{
		// 	delete_plant_world(key_pos)
		// }
	}
}

control_plant_stages :: proc(plant: ^PlantInstance) {
	plant.grow += 1

	// Forward Stage
	if plant.grow >= plant.stages[0].to_end_stage {
		plant.grow = 0
		ordered_remove(&plant.stages, 0)
	}

	#partial switch stage in plant.stages[0].stage_type {
		case SeedStage:
			fmt.println("I am on Seed Stage")

		case SproutStage:
			fmt.println("I am on Sprout Stage")

		case VeggieStage:
			fmt.println("I am on Veggie Stage")

		case:
			break
	}

	fmt.println("========================================================")
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

patch_behavior :: proc(center: vec3i, p_data: ^PlantData, limit: int, repel_radius, plant_radius: f32) {
	if center in plants || !get_validation_plant_in_pos(p_data, center) {
		fmt.println("not_valid")
		return
	}

	visited_pos: map[vec3i]bool

	// repel_radius: f32 = 25
	// plant_radius: f32 =	7 

	patch_limit: int = limit // if want 3, place a 4

	count: int = 0

	for r in 0..<repel_radius {
		for x in -r + 1..< r {
			for z in -r + 1..< r {
				radius_pos: vec3 = {f32(x), 0, f32(z)}
				this_pos: vec3i = {int(x), 0, int(z)} + center 

				if (radius_pos.x * radius_pos.x + radius_pos.z * radius_pos.z) <= (r * r) {
					if this_pos == center || this_pos in visited_pos  {
						continue
					}

					visited_pos[this_pos] = true

					if this_pos in plants {
						count += 1
					}

					if count >= patch_limit {
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

get_validation_plant_in_pos :: proc(plant_data: ^PlantData, pos: vec3i) -> bool {
	pos2d: vec2i = {pos.x, pos.z}
	if pos2d not_in terrain {
		return false
	}

	if terrain[pos2d].floor_height != pos.y {
		return false
	}

	if pos in plants {
		return false
	}

	for condition in plant_data.conditions {
		if !condition(pos) {
			return false
		}
	}

	temp: bool = false
	moist: bool = false

	cell := &terrain[{pos.x, pos.z}]

	if cell.temp > plant_data.low_temp && cell.temp < plant_data.high_temp {
		temp = true
	}

	if cell.moist > plant_data.low_moist && cell.moist < plant_data.high_moist {
		moist = true
	}		

	if temp && moist {
		return true
	}

	return false
}

// init plants in world
init_some_plants :: proc() {
	positions: int = 1 
	count: int = 0

	// plant some Carrots
	for key_pos, cell in terrain {
		pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

		if get_validation_plant_in_pos(&carrot_data, pos) && count < positions {

			patch_behavior(pos, &carrot_data, 2, 25, 7)
			count += 1
		}
	}	

	positions = 3
	count = 0

	// plant some Long Grass
	for key_pos, cell in terrain {
		pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

		if cell.tile != grass_model {
			continue
		}

		if get_validation_plant_in_pos(&foliage_data, pos) && count < positions {

			patch_behavior(pos, &foliage_data, 100, 1, 50)
			count += 1
		}
	}	

}

draw_plants :: proc() {
	for key_pos, &plant in plants {
		draw_visual_instance(&plant.visual_instance, key_pos)

		rl.DrawCubeWiresV(to_v3(to_visual_world(key_pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.ORANGE)	
	}
}

// --------------- Plant Actions ----------------------------
delete_plant_world :: proc(pos: vec3i) {
	delete_key(&plants, pos)

	for ed_plnt, i in edible_plants {
		if ed_plnt == pos {
			unordered_remove(&edible_plants, i)
		}
	}
}


create_plant_world :: proc(pos: vec3i, plant_data: ^PlantData) {
	new_visual_instance: VisualInstance = {
		game_model = plant_data.game_model,
		rot = f32(rand.int_max(359))
	}

	new_plant: PlantInstance = {
		visual_instance = new_visual_instance,

		grow = 0, //rand.int_max(199), 
		calories = 1000,
		seeding = false,

		data = plant_data,
		stages = get_stages_from_plant_data(plant_data.stages),
	}

	plants[pos] = new_plant
}

get_stages_from_plant_data :: proc(stages: [dynamic]Stage) -> [dynamic]Stage {
	new_stages: [dynamic]Stage

	for stage in stages {
		append(&new_stages, stage)
	}

	return new_stages
}

// Plant Data Conditions
condition_in_grass :: proc(pos: vec3i) -> bool {
	pos2d: vec2i = {pos.x, pos.z}	
	cell := terrain[pos2d]

	if cell.tile == grass_model {
		return true	
	}

	return false
}
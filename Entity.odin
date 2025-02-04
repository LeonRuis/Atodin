package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"

Entity :: struct {
	pos: vec3i,
	target_pos: vec3i,
	path: [dynamic]vec3i,
	color: rl.Color,

	name: cstring,
	model: rl.Model,
	tasks: [dynamic]Task,

	water_max: int,
	water: f32,

	food_max: int,
	food: f32,

	sleep_max: int,
	sleep: f32,

	idle_tick_count: int
}

//##
rand_ :: proc() -> vec3i {
	x: int = int(rand.int31_max(i32(CHUNK_SIZE.x)))
	z: int = int(rand.int31_max(i32(CHUNK_SIZE.z)))
	y := terrain[{x, z}].floor_height

	return {int(x), int(y), int(z)}
}

gray_rat: Entity = {
	{0, 0, 0},
	{0, 0, 0},
	{},
	rl.LIGHTGRAY,

	"Gray Rat",
	{},
	{},

	500,
	100,

	500,
	400,

	1000,
	250,

	0
}

orange_rat: Entity = {
	{0, 0, 0},
	{0, 0, 0},
	{},
	rl.MAROON,

	"Orange",
	{},
	{},

	500,
	400,

	400,
	0,

	1000,
	800,

	0
}

entities: [dynamic]^Entity

test_init_rats :: proc() {
	gray_rat.pos = rand_()
	cell := &world[gray_rat.pos] 
	cell.entity = &gray_rat

	orange_rat.pos = rand_()
	cell = &world[orange_rat.pos] 
	cell.entity = &orange_rat

	gray_rat.model = rat_blue_model
	orange_rat.model = rat_orange_model 

	append(&entities, &gray_rat)
	append(&entities, &orange_rat)
}

draw_rat :: proc() {
	for ent in entities {
		rl.DrawCubeWiresV(to_v3(to_visual_world(ent.pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, ent.color)

		direction: vec3i 
		rot: f32 

		if len(ent.path) > 0 {
			rl.DrawCubeWiresV(to_v3(to_visual_world(ent.path[0])) + {0.5, 0.5, 0.5}, {1, 1, 1}, ent.color)
			direction = (ent.pos - ent.path[0])
		}

		switch direction {
			case N:
				rot = 90 

			case W:
				rot = 180

			case S: 
				rot = -90

			case: 
				rot = 0
		}

		rl.DrawModelEx(
				ent.model, 
				to_v3(to_visual_world(ent.pos)) + {0.5, 0, 0.5},
				{0, 1, 0},
				rot,
				0.5,
				rl.WHITE
			)
	}
}

update_entity :: proc(ent: ^Entity) {
	if ent.water > 0 {
		ent.water -= 1
	}

	if ent.food > 0 {
		ent.food -= 1
	}

	if ent.sleep > 0 {
		ent.sleep -= 1
	}

	// Task Flow Control
	if len(ent.tasks) > 0 {
		execute_task(ent, ent.tasks[0])
	} else { 
		ent.idle_tick_count += 1
	}

	if ent.idle_tick_count == 3 {
		add_task(ent, Move_To{rand_(), false, true})
		ent.idle_tick_count = 0
	}

	// Auto food
	if ent.food <= f32(ent.food_max) / 3 {
		// Vision food
		cost: int = 9999
		pos: vec3i

		for task in ent.tasks {
			#partial switch t in task {
				case Eat_Plant:
					return	
			}
		} 

		for key_pos in edible_plants {
			current_cost := get_heuclidean(ent.pos, key_pos)

			if current_cost < cost {
				cost = current_cost
				pos = key_pos
			}
		}

		if cost < 35 {
			add_task(ent, Eat_Plant{false, pos})
		}
	}

	// Auto water
	dirs: [4]vec3i = {
		N,
		S,
		W,
		E
	}

	if ent.water <= f32(ent.water_max) / 3 {
		// Vision water 
		cost: int = 9999
		pos: vec3i

		for task in ent.tasks {
			#partial switch t in task {
				case Drink_World:
					return
			}
		} 

		for key_pos, cell in terrain {
			cell_pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}
			current_cost := get_heuclidean(ent.pos, cell_pos)

			if current_cost < 35 && cell.water_source {
				for dir in neighbor_dirs {
					this_neighbor := cell_pos + dir

					if !terrain[{this_neighbor.x, this_neighbor.z}].water_source {
						if current_cost < cost {
							cost = current_cost
							pos = cell_pos 
						}
					}
				}
			}
		}

		if cost < 35 {
			add_task(ent, Drink_World{false, pos})
		}
	}

	// Auto Sleep
	for task in ent.tasks {
		#partial switch t in task {
			case Sleep:
				return
		}
	} 

	if ent.sleep <= f32(ent.sleep_max) / 4 {
		add_task(ent, Sleep{})
	}
}

set_entity_target_pos :: proc(ent: ^Entity, tar: vec3i, adyacent: bool) {
	ent.target_pos = tar
	ent.path = path(ent.pos, ent.target_pos) 
	if len(ent.path) > 0 {
		ordered_remove(&ent.path, 0)

		if adyacent {
			ordered_remove(&ent.path, len(ent.path) - 1)
		}
	}
}

walk_entity :: proc(ent: ^Entity) -> bool { // Return true when full path is walked
	if ent.pos == ent.target_pos {
		fmt.println("Target Reached")
		return true 
	}
	
	if len(ent.path) == 0 {
		fmt.println("Not moving, no path assigned")
		return true 
	} 

	cell := &world[ent.pos] 
	cell.entity = {}

	ent.pos = ent.path[0]

	cell = &world[ent.pos] 
	cell.entity = ent

	ordered_remove(&ent.path, 0)
	return false 
}

//--------------------- Task System -------------------------
Task :: union {
	Move_To,
	Eat_Plant,
	Drink_World,
	Sleep
}

Move_To :: struct {
	target_pos: vec3i,
	init: bool,
	is_auto: bool 
}

Eat_Plant :: struct {
	init: bool,
	target_pos: vec3i,
}

Drink_World :: struct {
	init: bool,
	target_pos: vec3i
}

Sleep :: struct {}
// sleep cannot be canceled, the entity should be awakened for world activity (loud sounds, other entity, etc)

add_task :: proc(ent: ^Entity, task: Task) {
	for task in ent.tasks {
		#partial switch t in task {
			case Move_To:
				if t.is_auto {
					ordered_remove(&ent.tasks, 0)
					fmt.println("Auto Task Erased")
				}
		}
	}

	append(&ent.tasks, task)
}


init_task :: proc(ent: ^Entity, task: Task) {
	#partial switch &t in task {
		case Move_To:
			set_entity_target_pos(ent, t.target_pos, false)
			t.init = true

		case Eat_Plant: 
			set_entity_target_pos(ent, t.target_pos, false)
			t.init = true

		case Drink_World: 
			// Check for tile adyacent to water source
			adyacent_pos: vec3i

			if world[t.target_pos + N].walkable {
				adyacent_pos = t.target_pos + N
			} else if world[t.target_pos + S].walkable {
				adyacent_pos = t.target_pos + S 
			} else if world[t.target_pos + E].walkable{
				adyacent_pos = t.target_pos + E
			} else if world[t.target_pos + W].walkable{
				adyacent_pos = t.target_pos + W
			}

			set_entity_target_pos(ent, adyacent_pos, false)
			t.init = true
	}
}

execute_task :: proc(ent: ^Entity, task: Task) {
	switch t in task {
		case Move_To:
			if t.init == false {
				init_task(ent, task)
			}

			if walk_entity(ent) {
				ordered_remove(&ent.tasks, 0)
			}

		case Eat_Plant: 
			if t.init == false {
				init_task(ent, task)
			}

			if walk_entity(ent) {
				// Eat Plant
				plant: ^Plant_World = &plants[t.target_pos]

				plant.calories -= 200

				if plant.calories == 0 {
					for ed_plnt, i in edible_plants {
						unordered_remove(&edible_plants, i)
					}
					delete_key(&plants, t.target_pos)
					ordered_remove(&ent.tasks, 0)

				} else if ent.food > f32(ent.food_max) {
					for ed_plnt, i in edible_plants {
						unordered_remove(&edible_plants, i)
					}

					ordered_remove(&ent.tasks, 0)
				}
			}

		case Drink_World:
			if t.init == false {
				init_task(ent, task)
			}

			if walk_entity(ent) {
				ent.water += 100

				if ent.water >= f32(ent.water_max) {
					ordered_remove(&ent.tasks, 0)
				}
			}

		case Sleep:
			ent.sleep += 10

			if ent.sleep >= f32(ent.sleep_max) {
				ent.sleep = f32(ent.sleep_max)
				ordered_remove(&ent.tasks, 0)
			}

	}
}


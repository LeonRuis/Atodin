package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"
import strconv "core:strconv"
import strings "core:strings"

//##
name_pull: [dynamic]string = {
	"Rose",
	"Leaf",
	"Apple"
}

pick_rand_name_in_pull :: proc() -> string {
	str: string = "Valid name"
	// if len(name_pull) > 0 {
	// 	index: int = rand.int_max(len(name_pull) - 1)
	// 	str: string = name_pull[index]

	// 	unordered_remove(&name_pull, index)
	// }
	return str
}
//##

Entity :: struct {
	pos: vec3i,
	target_pos: vec3i,
	path: [dynamic]vec3i,
	color: rl.Color,

	name: string,
	model: rl.Model,
	tasks: [dynamic]Task,

	water_max: int,
	water: int,

	food_max: int,
	food: int,

	sleep_max: int,
	sleep: int,

	idle_tick_count: int,

	gender: bool, // false = female, true = male
	dob: Time,
	age: Time,

	id: int,

	mating_max: int,
	mating: int,

	social_max: int,
	social: int
}

entities: map[int]Entity

//##
rand_ :: proc() -> vec3i {
	x: int = int(rand.int31_max(i32(CHUNK_SIZE.x)))
	z: int = int(rand.int31_max(i32(CHUNK_SIZE.z)))
	y := terrain[{x, z}].floor_height

	return {int(x), int(y), int(z)}
}

test_init_rats :: proc() {
	spawn_entity(rand_(), true, rl.BLUE, rat_blue_model, "Pinnaple")
	spawn_entity(rand_(), false, rl.ORANGE, rat_orange_model, "Carrot")
}

draw_rat :: proc() {
	for id, ent in entities {
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

update_entities :: proc() {
	for id, &ent in entities {
		update_entity(&ent)
	}	
}

update_entity :: proc(ent: ^Entity) {
	//#
	ent.age = calculate_age(ent.dob)
	//#

		// Deaths
	// Age
	if ent.age[5] >= 1 {
		despawn_entity(ent)
	}

	if ent.water == 0 || ent.food == 0 || ent.sleep == 0 { // Me gustaria hacer algo mas interesante con las entidades cuando sleep llegue a 0
		despawn_entity(ent)
	}

	if ent.water > 0 {
		ent.water -= 1
	}

	if ent.food > 0 {
		ent.food -= 1 
	}

	if ent.sleep > 0 {
		ent.sleep -= 1
	}

	if ent.social > 0 {
		ent.social -= 1
	}

	// Task Flow Control
	if len(ent.tasks) > 0 {
		execute_task(ent, ent.tasks[0])
	} else { 
		ent.idle_tick_count += 1
	}

	if ent.idle_tick_count == 2 {
		add_task(ent, Move_To{rand_(), false, true})
		ent.idle_tick_count = 0
	}

	// Auto food
	if ent.food <= ent.food_max / 3 {

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

		if cost < 50 {
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

	if ent.water <= ent.water_max / 3 {
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

	if ent.sleep <= ent.sleep_max / 4 {
		add_task(ent, Sleep{})
	}

	// Auto Social
	for task in ent.tasks {
		#partial switch t in task {
			case Social_Positive:
				return
		}
	} 

	if ent.social < ent.social_max / 2 {
		if len(entities) > 1 {
			for ind, social_ent in entities {
				if social_ent.id == ent.id {
					continue
				}

				add_task(ent, Social_Positive{social_ent.id, false, false, 10})
				return
			}
		}
	}
}

set_entity_target_pos :: proc(ent: ^Entity, tar: vec3i, adyacent: bool) {
	ent.target_pos = tar
	ent.path = path(ent.pos, ent.target_pos) 
	if len(ent.path) > 0 {
		ordered_remove(&ent.path, 0)

		if adyacent && len(ent.path) != 0 {
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

	control_entity_exit_pos(ent)

	ent.pos = ent.path[0]

	control_entity_enter_pos(ent)

	ordered_remove(&ent.path, 0)
	return false 
}

//--------------------- Task System -------------------------
Task :: union {
	Move_To,
	Eat_Plant,
	Drink_World,
	Sleep,
	Social_Positive
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

Social_Positive :: struct {
	entity_id: int,
	init: bool,
	is_auto: bool,
	ticks_to_end: int,
}

add_task :: proc(ent: ^Entity, task: Task) {
	// Remove auto moves
	for task in ent.tasks {
		#partial switch t in task {
			case Move_To:
				if t.is_auto {
					ordered_remove(&ent.tasks, 0)
					fmt.println("Auto Task Erased")
				}
		}
	}

	#partial switch t in task {
		case Social_Positive:
			if !t.is_auto {
				add_task(get_entity_from_id(t.entity_id), Social_Positive{ent.id, true, true, 10})
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
	switch &t in task {
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
				if t.target_pos not_in plants {
					ordered_remove(&ent.tasks, 0)
					return
				}

				plant: ^Plant_World = &plants[t.target_pos]

				plant.calories -= 200
				ent.food += 200

				if plant.calories == 0 {
					delete_plant_world(t.target_pos)
					ordered_remove(&ent.tasks, 0)

				} else if ent.food >= ent.food_max {
					ordered_remove(&ent.tasks, 0)
				}
			}

		case Drink_World:
			if t.init == false {
				init_task(ent, task)
			}

			if walk_entity(ent) {
				ent.water += 100

				if ent.water >= ent.water_max {
					ordered_remove(&ent.tasks, 0)
				}
			}

		case Sleep:
			ent.sleep += 10

			if ent.sleep >= ent.sleep_max {
				ent.sleep = ent.sleep_max
				ordered_remove(&ent.tasks, 0)
			}

		case Social_Positive:
			if !t.is_auto {
				#partial switch &t_social in get_entity_from_id(t.entity_id).tasks[0] {
					case Social_Positive:
						if t_social.entity_id != ent.id {
							return
						}

						if !t.init {
							init_task(ent, task)
							set_entity_target_pos(
								ent,
								get_entity_from_id(t.entity_id).pos,
								true
							)
							t.init = true
						}

						if walk_entity(ent) {
							if t.ticks_to_end > 0 {

								ent.social += 120 
								ent.mating += 1 

								get_entity_from_id(t.entity_id).social += 120 
								get_entity_from_id(t.entity_id).mating += 2 

								t.ticks_to_end -= 2 
							}

							if t.ticks_to_end == 0 {
								// Remove from self
								ordered_remove(&ent.tasks, 0)

								// Remove from social target
								ordered_remove(&get_entity_from_id(t.entity_id).tasks, 0)

								pregnant_id: int = -1
								pregnant: ^Entity = {}
								if ent.gender && !get_entity_from_id(t.entity_id).gender {
									pregnant_id = t.entity_id 
								}

								if !ent.gender && get_entity_from_id(t.entity_id).gender {
									pregnant_id = ent.id
								}

								if pregnant_id != -1 {
									pregnant = get_entity_from_id(pregnant_id)

									if pregnant.mating >= pregnant.mating_max {
										fmt.println("child ==========================================")
										spawn_entity(rand_(), false, rl.ORANGE, rat_orange_model, pick_rand_name_in_pull())
									}
								}
							}


							/*
							Interacciones sociales deben generar una reaccion, por ejemplo: una interacion positiva puede dar puntos de mating, una interaccion negativa puede hacer la entidad huir.
							esto es por que a veces alguna entidad, digase rata, puede interactuar con otra de otro tipo, digase perro. Diferentes factores resultaran en diferentes outputs negativos y positivos.
							*/
						}

					case:
						fmt.println("waiting to entity")
				}
			}
	}
}

delete_task :: proc(ent: ^Entity, task: Task) {
	#partial switch t in task {
		case Social_Positive:
			ordered_remove(&ent.tasks, 0)
			ordered_remove(&get_entity_from_id(t.entity_id).tasks, 0)

		case:
			return
	}
}

// --------------------------------------------------------------------------
spawn_entity :: proc(pos: vec3i, gender: bool, color: rl.Color, model:rl.Model, name: string) {
	new_entity: Entity = {
		pos = pos,
		target_pos = {0, 0, 0},
		path = {},
		color = color,

		name = name,
		model = model, 
		tasks = {},

		water_max = 500,
		water = 500,

		food_max = 500,
		food = 500,

		sleep_max = 1000,
		sleep = 999,

		idle_tick_count = 0,

		gender = gender,
		dob = {hour, min, sec, day, month, year},
		age = {0, 0, 0, 0, 0, 0},

		id = get_valid_entitie_id(),

		mating_max = 100,
		mating = 0,

		social_max = 1500,
		social = 30
	}

	control_entity_enter_pos(&new_entity)

	entities[new_entity.id] = new_entity
}

valid_id: int = -1
get_valid_entitie_id :: proc() -> int {
	valid_id += 1
	return valid_id
}

get_current_entity :: proc() -> ^Entity {
	return &entities[current_entity]
}

get_entity_from_id :: proc(id: int) -> ^Entity {
	return &entities[id]
}

despawn_entity :: proc(ent: ^Entity) {
	for task in ent.tasks {
		delete_task(ent, task)
	}

	control_entity_exit_pos(ent)
	delete_key(&entities, ent.id)

	if current_entity == ent.id {
		current_entity = -1 
	}
}
///

Time :: [6]int // Indexes: 0 Hours, 1 Mins, 2 Secs, 3 Day, 4 Month, 5 Year

calculate_age :: proc(birth: [6]int) -> [6]int {
    age: [6]int
    carry: int = 0

    if sec >= birth[2] {
        age[2] = sec - birth[2]
    } else {
        age[2] = (sec + 60) - birth[2]
        carry = 1
    }

    if (min - carry) >= birth[1] {
        age[1] = (min - carry) - birth[1]
        carry = 0
    } else {
        age[1] = ((min - carry) + 60) - birth[1]
        carry = 1
    }

    if (hour - carry) >= birth[0] {
        age[0] = (hour - carry) - birth[0]
        carry = 0
    } else {
        age[0] = ((hour - carry) + 24) - birth[0]
        carry = 1
    }

    if (day - carry) >= birth[3] {
        age[3] = (day - carry) - birth[3]
        carry = 0
    } else {
        age[3] = ((day - carry) + 30) - birth[3]
        carry = 1
    }

    if (month - carry) >= birth[4] {
        age[4] = (month - carry) - birth[4]
        carry = 0
    } else {
        age[4] = ((month - carry) + 12) - birth[4]
        carry = 1
    }

    age[5] = (year - carry) - birth[5]

    return age
}

get_age :: proc(age: Time) -> string {
	day_buf: [4]byte
	month_buf: [4]byte
	year_buf: [4]byte

	day_str: string = strconv.itoa(day_buf[:], age[3])
	month_str: string = strconv.itoa(month_buf[:], age[4])
	year_str: string = strconv.itoa(year_buf[:], age[5])

	new: string = strings.concatenate({
		year_str, " years, ", month_str, " months, ", day_str, " days."
	})

	return new
}
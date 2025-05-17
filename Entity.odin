package Atalay

import fmt "core:fmt"
import rand "core:math/rand"
import rl "vendor:raylib"

entities: map[u32]Entity
null_id :: 0

Entity :: struct {
	id: u32,
	pos: vec3i,
	name: cstring,
	sprite: vec2i,

	idle_count: u32,
	blocked_count: u32,

	tasks: [dynamic]Task,

	social: f32, 
	max_social: f32,

	water: f32,
	max_water: f32,

	food: f32,
	max_food: f32,

	inventory: [dynamic]Slot
}

valid_entity_id: u32 = 0
get_entity_id :: proc() -> u32 {
	valid_entity_id += 1
	return valid_entity_id
}

get_entity :: proc(id: u32) -> ^Entity {
	return &entities[id]
}

create_entity :: proc(pos: vec3i, name: cstring, sprite: vec2i) {
	if pos not_in terrain_world {
		return
	}

	if terrain_world[pos].entity != null_id {
		return	
	}

	ID := get_entity_id()

	entity: Entity = {
		id = ID,
		pos = pos,
		name = name,
		sprite = sprite,

		idle_count = 0,

		tasks = {},

		social = f32(rand.int31_max(400)),
		max_social = 400,

		water = f32(rand.int31_max(400)),
		max_water = 400, 

		food = 10,// f32(rand.int31_max(400)),
		max_food = 400, 

		inventory = {
			Slot {
				"Left Hand",
				Null_Item { }
			},
			Slot {
				"Right Hand",
				Null_Item { }
			}
		}
	}

	entities[ID] = entity

	place_entity_in_world(ID, pos)
}

destroy_entity :: proc(ent_id: u32) {
	if ent_id not_in entities {
		return
	}

	ent := get_entity(ent_id)

	if ent_id == current_entity {
		current_entity = null_id
	}

	// // Remove tasks
	for &task in ent.tasks {
		end_task(ent_id, &task)
	}

	remove_entity_in_world(ent.pos)

	delete_key(&entities, ent_id)
}

entities_draw :: proc() {
	for id, ent in entities	{
		draw_sprite(&entity_atlas, ent.pos, ent.sprite)

		if id == current_entity {
			rl.DrawRectangleLines(ent.pos.x * tile_pixel_size, ent.pos.z * tile_pixel_size, tile_pixel_size, tile_pixel_size, rl.GREEN)
		}
	}
}

entities_update :: proc() {
	for id, &ent in entities {
		if !update_entity(&ent) {
			continue
		}
	}
}

update_entity :: proc(ent: ^Entity) -> bool {
	id := ent.id
	to_die: bool = false

	if ent.social > 0 {
		ent.social -= 1 
	} else {
		to_die = true
	}

	if ent.water > 0 {
		ent.water -= 1
	} else {
		to_die = true
	}

	if ent.food > 0 {
		ent.food -= 1
	} else {
		to_die = true
	}

	if to_die {
		destroy_entity(id)
		return false
	}

	if len(ent.tasks) > 0 {
		execute_task(id, &ent.tasks[0])
	}

	// Auto Water 
	if ent.water < ent.max_water / 2 {
		for task in ent.tasks {
			#partial switch type in task.type {
				case Drink:
					return true
			}
		}

		target: vec3i
		for key_pos, null in valid_drink_cells {
			target = key_pos
			break
		}

		add_task(
			id,
			Task {
				get_task_id(),
				"Drink Water",
				false,
				false,

				{},
				target,

				Drink {}
			}
		)
	}

	// Auto Social
	if ent.social < ent.max_social / 2 {
		for task in ent.tasks {
			#partial switch type in task.type {
				case Social:
					return true
			}
		}

		some_ent: u32
		for curr_id, ent in entities {
			if curr_id == id {
				continue
			}

			some_ent = curr_id
		}

		add_task(
		id,
		Task {
			get_task_id(),
			"Social",
			false,
			false,

			{},
			{},

			Social {
				some_ent,
				0,
				10
			}
		}
		)
	}

	// Idle
	if len(ent.tasks) < 1 && id != current_entity {
		ent.idle_count += 1

		if ent.idle_count >= 10 {
			ent.idle_count = 0

			add_task(
				id, 
				Task {
					id = get_task_id(),
					title = "Move to",
					is_init = false,
					is_auto = true,

					path = {},
					task_pos = get_rand_pos(),

					type = Move { }
				}
			)
		}
	} 

	return true
}

place_entity_in_world :: proc(id: u32, pos: vec3i) {
	if id == null_id {
		return
	}

	if terrain_world[pos].entity != null_id {
		return
	}

	if pos not_in terrain_world {
		return
	}

	if terrain_world[pos].color == rl.SKYBLUE {
		return
	}

	terrain_cell := &terrain_world[pos]
	terrain_cell.entity = id 
	
	path_cell := &path_world[pos]
	path_cell.is_walkable = false
}

remove_entity_in_world :: proc(pos: vec3i) {
	if pos not_in terrain_world {
		return
	}

	if terrain_world[pos].entity == null_id {
		return
	}

	terrain_cell := &terrain_world[pos]
	terrain_cell.entity = null_id 
	
	path_cell := &path_world[pos]
	path_cell.is_walkable = true
}

walk_entity_path :: proc(id: u32, task: ^Task) -> Walk_Status {
	ent := get_entity(id)

	if len(task.path) > 0 {
		new_pos := task.path[0]

		if terrain_world[new_pos].entity != null_id {
			ent.blocked_count += 1

			if ent.blocked_count >= 4 {
				task.path = get_path(ent.pos, task.task_pos, false)
			}

			return .BLOCKED
		}

		remove_entity_in_world(ent.pos)
		ent.pos = new_pos
		place_entity_in_world(id, new_pos)

		ordered_remove(&task.path, 0)	

		if len(task.path) <= 0 {
			return .PATH_END
		}

		return .WALK
	} 

	return .NO_PATH
}

Walk_Status :: enum {
	NO_PATH,
	WALK,
	PATH_END,
	BLOCKED
}

//
get_rand_pos :: proc() -> vec3i {
	rand_x := rand.int31_max(15)
	rand_z := rand.int31_max(15)
	pos: vec3i = {rand_x, 0, rand_z}
	return pos
}
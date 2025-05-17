package Atalay

import fmt "core:fmt"

Task :: struct {
	id: u32,
	title: cstring,
	is_init: bool,
	is_auto: bool,

	path: [dynamic]vec3i,
	task_pos: vec3i,

	type: union {
		Move,
		Social,
		Drink,
		Pick_Item,
		Harvest_Plant,
		Eat_Full
	}
}

valid_task_id: u32 = 0
get_task_id :: proc() -> u32 {
	valid_task_id += 1
	return valid_task_id
}

add_task :: proc(id: u32, task: Task) {
	ent := get_entity(id)

	#partial switch type in task.type {
		case Social:
			if task.is_auto {
				break
			}

			pair_task: Task = {
				id = task.id,
				title = task.title,
				is_init = true,
				is_auto = true,

				path = {},
				task_pos = {},

				type = Social {
					id,
					0,
					5	
				}
			}

			// Add task to Social Target Entity
			add_task(type.target_ent, pair_task)
	}

	append(&ent.tasks, task)
}

init_task :: proc(id: u32, task: ^Task) {
	task.is_init = true
	ent := get_entity(id)

	#partial switch &type in task.type {
		case Move: 
			task.path = get_path(ent.pos, task.task_pos, false)

		case Social:
			task.task_pos = get_entity(type.target_ent).pos
			task.path = get_path(ent.pos, task.task_pos, true)

		case Drink, Pick_Item, Harvest_Plant: 
			task.path = get_path(ent.pos, task.task_pos, true)
	}
}

execute_task :: proc(id: u32, task: ^Task) {
	ent := get_entity(id)

	#partial switch &type in task.type {
		case Move:
			if !task.is_init {
				init_task(id, task)
			}

			status := walk_entity_path(id, task)

			if status != .WALK {
				end_task(id, task)
			}

		case Social:
			if task.is_auto {
				return
			}				

			if get_entity(type.target_ent).tasks[0].id == task.id && !task.is_init {
				init_task(id, task)
			}

			status := walk_entity_path(id, task)

			if status != .WALK {
				social_ent := get_entity(type.target_ent)

				type.ticks += 1

				ent.social += 20
				social_ent.social += 20

				if type.ticks >= type.ticks_to_end {
					end_task(type.target_ent, task)
					end_task(id, task)
				}
			}

		case Drink:
			if !task.is_init {
				init_task(id, task)
			}

			status := walk_entity_path(id, task)

			if status != .WALK {
				ent.water += 40
			}

			if ent.water >= ent.max_water {
				end_task(id, task)
			}

		case Pick_Item:
			if !task.is_init {
				init_task(id, task)
			}

			status := walk_entity_path(id, task)

			if status != .WALK {
				if check_empty_slot(&ent.inventory) {
					// Add Item to Inventory and delete from world
					place_item_in_inventory(type.item_id, &ent.inventory)
					remove_item_from_terrain(type.item_id, task.task_pos)
				}
				end_task(id, task)
			}

		case Harvest_Plant:
			if !task.is_init {
				init_task(id, task)
			}

			status := walk_entity_path(id, task)

			if status != .WALK {
				if type.plant_id not_in plants {
					end_task(id, task)
					return
				}

				plant := &plants[type.plant_id]

				if plant.items_to_give > 0 {
					plant.items_to_give -= 1

					// Control if item is added to Inventory or Terrain
					new_item_id := create_item_from_item_data(&carrot_item_data)
					if check_empty_slot(&ent.inventory) {
						place_item_in_inventory(new_item_id, &ent.inventory)
					} else {
						place_item_in_world(new_item_id, ent.pos)
					}
				}

				if plant.items_to_give <= 0 {
					remove_plant(type.plant_id)
					end_task(id, task)
				}
			}

		case Eat_Full:
			if check_item_in_inventory(type.item_id, &ent.inventory) {
				edible := &items[type.item_id]

				#partial switch &type in edible.type {
					case Item_Food:
						type.calories -= 10
						ent.food += 10

						if type.calories <= 0 {
							end_task(id, task)
						}
				}

			} else {
				end_task(id, task)
			}
	}
}

end_task :: proc(id: u32, task: ^Task) {
	ent := get_entity(id)

	#partial switch type in task.type {
		case Social:
			social_ent := get_entity(type.target_ent)

			for curr_task, i in social_ent.tasks {
				if curr_task.id == task.id {
					ordered_remove(&social_ent.tasks, i)
				}
			}
	}

	for curr_task, i in ent.tasks {
		if task.id == curr_task.id {
			ordered_remove(&ent.tasks, i)
			return
		}
	}
}

// Task Types

Move :: struct { }

Social :: struct {
	target_ent: u32,
	ticks: u32,
	ticks_to_end: u32
}

Drink :: struct { }

Pick_Item :: struct { 
	item_id: u32
}

Harvest_Plant :: struct {
	plant_id: u32,
}

Eat_Full :: struct {
	item_id: u32
}
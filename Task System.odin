package Atalay

Task :: struct {
	id: int,
	init: bool,
	is_auto: bool,

	type: union {
		Move_To,
	}
}

Move_To :: struct {
	target_pos: vec3i 
}

task_id: int = -1
pick_task_id :: proc() -> int {
	task_id += 1
	return task_id
}

add_task :: proc(ent: ^Entity, task: Task) {
	append(&ent.tasks, task)
}

init_task :: proc(ent: ^Entity, task: ^Task) {
	#partial switch &type in task.type {
		case Move_To:
			set_entity_target_pos(ent, type.target_pos, false)
	}

	task.init = true
}

execute_task :: proc(ent: ^Entity, task: ^Task) {
	#partial switch &type in task.type {
		case Move_To:
			if !task.init {
				init_task(ent, task)
			}

			walk_state := walk_entity(ent)

			if walk_state == .TARGET || walk_state == .NO_PATH {
				end_task(ent)
			}
	}
}

end_task :: proc(ent: ^Entity) {
	ordered_remove(&ent.tasks, 0)
}

cancel_task :: proc(ent: ^Entity, task_index: int) {
	ordered_remove(&ent.tasks, task_index)
}
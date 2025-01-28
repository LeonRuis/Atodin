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
	water: int,
	food_max: int,
	food: int,
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
	400,

	400,
	0,
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
}

entities: [2]^Entity

test_init_rats :: proc() {
	gray_rat.pos = rand_()
	cell := &world[gray_rat.pos] 
	cell.entity = &gray_rat

	orange_rat.pos = rand_()
	cell = &world[orange_rat.pos] 
	cell.entity = &orange_rat

	gray_rat.model = rat_blue_model
	orange_rat.model = rat_orange_model 

	entities[0] = &gray_rat
	entities[1] = &orange_rat 
}

draw_rat :: proc() {
	for ent in entities {
		rl.DrawCubeWiresV(to_v3(to_visual_world(ent.pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, ent.color)
		rl.DrawModel(
				ent.model, 
				to_v3(to_visual_world(ent.pos)),
				0.5,
				rl.WHITE
			)
	}
}

update_entity :: proc(ent: ^Entity) {
	// Task Flow Control
	if len(ent.tasks) > 0 {
		execute_task(ent, ent.tasks[0])
	} else { 
		return
	}
}

set_entity_target_pos :: proc(ent: ^Entity, tar: vec3i) {
	ent.target_pos = tar
	ent.path = path(ent.pos, ent.target_pos) 
}

walk_entity :: proc(ent: ^Entity) -> bool{
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
	Craft,
}

Move_To :: struct {
	target_pos: vec3i,
	init: bool
}

Craft :: struct {
	name: cstring,
	init: bool
}

add_task :: proc(ent: ^Entity, task: Task) {
	append(&ent.tasks, task)
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

		case Craft: 
			fmt.println(t.name)
			ordered_remove(&ent.tasks, 0)
	}
}

init_task :: proc(ent: ^Entity, task: Task) {
	#partial switch &t in task {
		case Move_To:
			ent.target_pos = t.target_pos
			ent.path = path(ent.pos, ent.target_pos)
			t.init = true
	}
}

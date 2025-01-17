package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

Entity :: struct {
	pos: vec3i,
	target_pos: vec3i,
	path: [dynamic]vec3i,
	state: Entity_State
}

Entity_State :: enum {
	IDLE,
	WONDER,
}

//##
rat_test: Entity = {
	{0, 0, 0},
	{0, 0, 0},
	{},
	.IDLE
}

draw_rat :: proc() {
	rl.DrawCubeV(to_v3(rat_test.pos) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.LIGHTGRAY)
}
//##

wonder_entity :: proc(ent: ^Entity) {
	if ent.pos == ent.target_pos {
		fmt.println("Entity Reached Target")
	}

	if len(ent.path) == 0 {
		ent.target_pos = ran_v3i()	
		ent.path = path(ent.pos, ent.target_pos)
	}

	ent.pos = ent.path[0]
	ordered_remove(&ent.path, 0)
}
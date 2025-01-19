package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"

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
init_rat :: proc() {
	rat_test.pos = rand_()
}

rand_ :: proc() -> vec3i {
	x: int = int(rand.int31_max(i32(CHUNK_SIZE.x)))
	z: int = int(rand.int31_max(i32(CHUNK_SIZE.z)))
	y := terrain[{x, z}].floor_height

	return {int(x), int(y), int(z)}
}

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
		ent.target_pos = rand_()	
		ent.path = path(ent.pos, ent.target_pos)
	}

	ent.pos = ent.path[0]
	ordered_remove(&ent.path, 0)
}
package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import rand "core:math/rand"

Entity :: struct {
	pos: vec3i,
	target_pos: vec3i,
	path: [dynamic]vec3i,
	state: Entity_State,
	color: rl.Color,

	name: cstring
}

Entity_State :: enum {
	IDLE,
	WONDER,
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
	.IDLE,
	rl.LIGHTGRAY,

	"Gray Rat"
}

orange_rat: Entity = {
	{0, 0, 0},
	{0, 0, 0},
	{},
	.IDLE,
	rl.MAROON,

	"Orange"
}

entities: [2]Entity

test_init_rats :: proc() {
	gray_rat.pos = rand_()
	orange_rat.pos = rand_()

	entities[0] = gray_rat
	entities[1] = orange_rat 
}

draw_rat :: proc() {
	for &ent in entities {
		rl.DrawCubeV(to_v3(to_visual_world(ent.pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, ent.color)

		fmt.println(ent.name, ent.pos)
	}

	fmt.println("========================== ")
}

wonder_entities :: proc() {
	for &ent in entities {
		wonder_entity(&ent)
	}
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

	cell := &world[ent.pos] 
	cell.entity = {}

	ent.pos = ent.path[0]
	cell = &world[ent.pos] 
	cell.entity = ent

	ordered_remove(&ent.path, 0)
}

to_visual_world :: proc(cell_pos: vec3i) -> vec3i {
	return {cell_pos.x, cell_pos.y * 2, cell_pos.z}
}
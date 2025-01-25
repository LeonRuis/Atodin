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

	name: cstring,
	model: rl.Model
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
	.WONDER,
	rl.LIGHTGRAY,

	"Gray Rat",
	{}
}

orange_rat: Entity = {
	{0, 0, 0},
	{0, 0, 0},
	{},
	.WONDER,
	rl.MAROON,

	"Orange",
	{}
}

entities: [2]^Entity

test_init_rats :: proc() {
	gray_rat.pos = rand_()
	orange_rat.pos = rand_()

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
				1,
				rl.WHITE
			)

	}
}

entity_state :: proc() {
	for ent in entities {
		if ent.state == .WONDER && !walk_entity(ent) {
			set_entity_target_pos(ent, rand_())
		}
	}
}
//##

set_entity_target_pos :: proc(ent: ^Entity, tar: vec3i) {
	ent.target_pos = tar
	ent.path = path(ent.pos, ent.target_pos) 
}

walk_entity :: proc(ent: ^Entity) -> bool{
	if ent.pos == ent.target_pos {
		fmt.println("Target Reached")
		return false
	}
	
	if len(ent.path) == 0 {
		fmt.println("Not moving, no path assigned")
		return false
	} 

	cell := &world[ent.pos] 
	cell.entity = {}

	ent.pos = ent.path[0]

	cell = &world[ent.pos] 
	cell.entity = ent

	ordered_remove(&ent.path, 0)
	return true
}
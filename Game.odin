package Atalay

current_entity: ^Entity = &gray_rat
pointer_pos: vec3i

GameMode :: enum {
	POINTER,
	GUI,
	WALL_PLACE,
	MOVE_ENTITY
}

gamemode: GameMode = .POINTER

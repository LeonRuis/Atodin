package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

GameMode :: enum {
	POINTER,
	GUI,
	WALL_PLACE,
	FOCUS_ENTITY,
	RIGHT_CLICK,
	PAUSE_GUI
}

gamemode: GameMode = .POINTER
in_gui: bool = false

current_entity: int 
pointer_pos: vec3i
wall_rotation: int = 0

//##
current_plant: ^PlantInstance
//##

set_mode :: proc(mode: GameMode) {
	#partial switch mode {
		case .POINTER:
			rl.DisableCursor()
			in_gui = false 

		case .GUI:
			rl.EnableCursor()
			in_gui = true

		case .WALL_PLACE:
			rl.DisableCursor()
			in_gui = false 

		case .RIGHT_CLICK:
			rl.EnableCursor()
			right_click_mode_pos = rl.GetWorldToScreen(to_v3(to_visual_world(pointer_pos)), camera3)
			rl.SetMousePosition(i32(right_click_mode_pos.x), i32(right_click_mode_pos.y))

			if pointer_pos in plants {
				current_plant = &plants[pointer_pos]
			}

			in_gui = true

		case .FOCUS_ENTITY:
			rl.DisableCursor()
			in_gui = false 

		case .PAUSE_GUI:
			rl.EnableCursor()
			speed = 0
			in_gui = true

		case:
			rl.CloseWindow()
	}

	gamemode = mode
}

update_mode :: proc() {
	#partial switch gamemode {
		case .POINTER:
			update_pointer_mode()

		case .WALL_PLACE:
			update_wall_place_mode()

		case .FOCUS_ENTITY:
			return

		case:
			return
	}
}

////-----------------------------------------------------------------------------------------------------
update_pointer_mode :: proc() {

	if rl.IsMouseButtonReleased(.LEFT) && current_entity > -1{
		// select entity
		if world[pointer_pos].entity_id != -1 {
			current_entity = world[pointer_pos].entity_id
		}
	}

	// right click options
	if rl.IsMouseButtonReleased(.RIGHT) && current_entity > -1 {
		set_mode(.RIGHT_CLICK)
	}

	// draw pointer
	rl.DrawCubeWiresV(to_v3(to_visual_world(pointer_pos)) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.BLUE)
}

update_wall_place_mode :: proc() {
	rot: f32
	pos: vec3
	cell_to_disconnect: vec3i

	if rl.IsKeyPressed(.R) {
		wall_rotation += 1
	}
	if wall_rotation == 4 {
		wall_rotation = 0
	}

	switch wall_rotation {
	case 0:
		// North
		rot = 0
		pos = to_v3(pointer_pos)
		cell_to_disconnect = pointer_pos + N
	case 1: 
		// East
		rot = -90
		pos = to_v3(pointer_pos + E)
		cell_to_disconnect = pointer_pos + E
	case 2: 
		// South 
		rot = 0
		pos = to_v3(pointer_pos + S)
		cell_to_disconnect = pointer_pos + S
	case 3: 
		// West
		rot = 90
		pos = to_v3(pointer_pos + S)
		cell_to_disconnect = pointer_pos + W
	}

	rl.DrawModelEx(
		wall_model,
		pos * {1, 2, 1},
		{0, 1, 0},
		rot,
		{1, 1, 1},
		rl.WHITE
		)

	// Set Wall in World
	if rl.IsMouseButtonReleased(.LEFT) {
		new_wall: Wall = {
			wall_model,
			pos,
			rot
		}

		cell := &world[pointer_pos]
		cell.walls[wall_rotation] = new_wall

		disconnect_cells(pointer_pos, cell_to_disconnect)
	}
}

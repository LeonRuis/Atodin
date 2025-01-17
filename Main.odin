package Atalay 

import fmt "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

////
WINDOW_WIDTH :: 1400
WINDOW_HEIGHT :: 750 

camera3: rl.Camera = {
	{0, 10, 10}, 
	{0, 0, 0},
	{0.0, 1.0, 0.0},
	45.0,
	.PERSPECTIVE
}

world_atlas: rl.Texture
grass_tile: rl.Model
sand_tile: rl.Model
wall_tile: rl.Model

cube_pos: vec3i = {0, 0, 0}
cube_target: vec3i = {0, 0, 2}
cube_path: [dynamic]vec3i

pointer_pos: vec3i

GameMode :: enum {
	POINTER,
	GUI,
	WALL_PLACE,
}

gamemode: GameMode = .POINTER

Wall :: struct {
	model: rl.Model,
	pos: vec3,
	rot: f32 
}
////

main :: proc() {
	// INITS 
	init_world_path()

	////
	rl.InitWindow(1400, 750, "Atalay")
	rl.DisableCursor()

	world_atlas = rl.LoadTexture("assets/WorldAtlas.png")
	defer rl.UnloadTexture(world_atlas)

	grass_tile = rl.LoadModel("assets/Grass.obj")
	grass_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(grass_tile)

	sand_tile = rl.LoadModel("assets/Sand.obj")
	sand_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(sand_tile)

	wall_tile = rl.LoadModel("assets/Log_Wall.obj")
	wall_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(wall_tile)

	rl.SetTargetFPS(60)

	tick: int = 0
	generate_world_terrain()

	for !rl.WindowShouldClose() {
		tick += 1
		if tick >= 50 {
			tick = 0
			wonder_entity(&rat_test)
		}		

		if gamemode != .GUI {
			rl.UpdateCamera(&camera3, .FREE)
		}

			//// Inputs
		//// Update Entity Target
		if gamemode == .POINTER {
			if rl.IsMouseButtonReleased(.LEFT) {
				cube_path = path(cube_pos, pointer_pos)
			}
		}

		//// Free Cursor
		if rl.IsKeyReleased(.TAB) {
			if gamemode == .GUI {
				set_pointer_mode()
			} else {
				set_gui_mode()
			}
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.GRAY)

			rl.BeginMode3D(camera3)
				//##
				draw_rat()
				//##
				// Draw Mouse Pointer
				update_pointer()
				if gamemode == .POINTER {
					rl.DrawCubeV(to_v3(pointer_pos) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.BLUE)
				}

				// Draw simple map Tiles
				// for x in 0..< world_size {
				// 	for z in 0..< world_size {
				// 		this_pos: vec3i = {x, 0, z}
				// 		rl.DrawModel(grass_tile, {f32(x), 0, f32(z)}, 1.0, rl.WHITE)
				// 	}
				// } 

				draw_world_terrain()

				// Draw Walls
				for key_pos, &cell in world {
					for &wall in cell.walls {
						rl.DrawModelEx(
							wall.model, 
							wall.pos,
							{0, 1, 0},
							wall.rot,
							{1, 1, 1},
							rl.WHITE)
					}
				}

				// Draw Wall pointer for wall placing
				if gamemode == .WALL_PLACE {
					update_wall()
				}

				rl.DrawCubeV(to_v3(cube_pos) + {0.5, 0.5, 0.5}, {1, 1, 1}, rl.RED)
			rl.EndMode3D()

			//// GUI
			if gamemode == .GUI {
				control_place_wall_btn()
			}

		rl.EndDrawing()
	}

	rl.CloseWindow() 
	////
}

//// Raypick
get_ray_from_screen :: proc() -> rl.Ray{
	mid_screen_pos : vec2 = {f32(WINDOW_WIDTH) / 2.0, f32(WINDOW_HEIGHT) / 2.0} 
	return rl.GetMouseRay(mid_screen_pos, camera3)
}

get_ground_intersection :: proc(ray: rl.Ray) -> vec3 {
	if ray.direction.y != 0 {
		t := -ray.position.y / ray.direction.y
		return ray.position + ray.direction * t
	}
	return ray.position
}

update_pointer :: proc() {
	ray := get_ray_from_screen()
	pointer:= get_ground_intersection(ray)
	pointer_pos = {int(pointer.x), 0, int(pointer.z)}
}
////

wall_rotation: int = 0
update_wall :: proc() {
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
		wall_tile,
		pos,
		{0, 1, 0},
		rot,
		{1, 1, 1},
		rl.WHITE
		)

	// Set Wall in World
	if rl.IsMouseButtonReleased(.LEFT) {
		new_wall: Wall = {
			wall_tile,
			pos,
			rot
		}

		cell := &world[pointer_pos]
		cell.walls[wall_rotation] = new_wall

		disconnect_cells(pointer_pos, cell_to_disconnect)
	}
}

//// Modes
	// Pointer
set_pointer_mode :: proc() {
	gamemode = .POINTER
	rl.DisableCursor()
}

update_pointer_mode :: proc () {

}
	//

set_gui_mode :: proc() {
	gamemode = .GUI
	rl.EnableCursor()
}

set_place_wall_mode :: proc() {
	gamemode = .WALL_PLACE
	rl.DisableCursor()
}
////
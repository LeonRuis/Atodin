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

rat_blue_model: rl.Model
rat_orange_model: rl.Model

rat_blue_texture: rl.Texture
rat_orange_texture: rl.Texture

Wall :: struct {
	model: rl.Model,
	pos: vec3,
	rot: f32 
}
////

main :: proc() {

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

	rat_blue_texture = rl.LoadTexture("assets/Rat_1.png")
	rat_blue_model = rl.LoadModel("assets/Rat.obj")
	rat_blue_model.materials[0].maps[0].texture = rat_blue_texture
	defer rl.UnloadTexture(rat_blue_texture)
	defer rl.UnloadModel(rat_blue_model)

	rat_orange_texture = rl.LoadTexture("assets/Rat_2.png")
	rat_orange_model = rl.LoadModel("assets/Rat.obj")
	rat_orange_model.materials[0].maps[0].texture = rat_orange_texture
	defer rl.UnloadTexture(rat_orange_texture)
	defer rl.UnloadModel(rat_orange_model)

	// INITS 
	generate_world_terrain()
	init_world_path()

	rl.SetTargetFPS(60)

	tick: int = 0
	pause: bool = false

	//##
	test_init_rats()

	//##

	for !rl.WindowShouldClose() {
		tick += 1
		if tick >= 50 && pause == false{
			tick = 0
			entity_state(&gray_rat)
		}		

		if !in_gui {
			rl.UpdateCamera(&camera3, .FREE)
		}

			//// Inputs

		//// Free Cursor
		if rl.IsKeyReleased(.TAB) {
			if gamemode == .GUI {
				set_mode(.POINTER)
			} else {
				set_mode(.GUI)
			}
		}

		//// Pause
		if rl.IsKeyReleased(.SPACE) {
			pause = !pause 
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.GRAY)

			rl.BeginMode3D(camera3)
				//##
				draw_rat()
				//##

				update_pointer()

					//// Modes Update
				update_mode()

				draw_world_terrain()

				// Draw Walls
				for key_pos, &cell in world {
					for &wall in cell.walls {
						rl.DrawModelEx(
							wall.model, 
							wall.pos * {1, 2, 1},
							{0, 1, 0},
							wall.rot,
							{1, 1, 1},
							rl.WHITE)
					}
				}
				
			rl.EndMode3D()

				//// GUIS
			if gamemode == .GUI {
				menu_modes()
			}

			if gamemode == .RIGHT_CLICK {
				menu_right_click()
			}

			entity_gui()

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

	height := terrain[{int(pointer.x), int(pointer.z)}].floor_height
	pointer_pos = {int(pointer.x), int(height), int(pointer.z)}
}
////
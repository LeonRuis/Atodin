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
water_tile: rl.Model
wall_tile: rl.Model

rat_blue_model: rl.Model
rat_orange_model: rl.Model

rat_blue_texture: rl.Texture
rat_orange_texture: rl.Texture

carrots_model: rl.Model
carrots_texture: rl.Texture

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
	rl.SetExitKey(.BACKSPACE)

	world_atlas = rl.LoadTexture("assets/WorldAtlas.png")
	defer rl.UnloadTexture(world_atlas)

	grass_tile = rl.LoadModel("assets/Grass.obj")
	grass_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(grass_tile)

	sand_tile = rl.LoadModel("assets/Sand.obj")
	sand_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(sand_tile)

	water_tile = rl.LoadModel("assets/Water.obj")
	water_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(water_tile)

	wall_tile = rl.LoadModel("assets/Log_Wall.obj")
	wall_tile.materials[0].maps[0].texture = world_atlas
	defer rl.UnloadModel(wall_tile)

	carrots_texture = rl.LoadTexture("assets/Carrots.png")
	carrots_model = rl.LoadModel("assets/Carrots.obj")
	carrots_model.materials[0].maps[0].texture = carrots_texture
	defer rl.UnloadTexture(carrots_texture)
	defer rl.UnloadModel(carrots_model)

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

	//##
	test_init_rats()
	// init_plant_in_world(&carrot)
	init_some_plants()
	// plant_patch_carrot(&carrot_data)

	//##

	for !rl.WindowShouldClose() {

		if tick >= 25 {
			tick = 0
			for ent in entities {
				update_entity(ent)
			}

			update_plants()
			update_time()
		}		

		if !in_gui {
			if gamemode == .FOCUS_ENTITY {
				rl.UpdateCamera(&camera3, .THIRD_PERSON)
				camera3.target = to_v3(current_entity.pos)
			} else {
				rl.UpdateCamera(&camera3, .FREE)
			}
		}

			//// Inputs
		if rl.IsKeyReleased(.F) {
			if gamemode == .POINTER {
				set_mode(.FOCUS_ENTITY)
			} else if gamemode == .FOCUS_ENTITY {
				set_mode(.POINTER)
			}
		}

		//// Gui Modes 
		if rl.IsKeyReleased(.TAB) {
			if gamemode == .GUI {
				set_mode(.POINTER)
			} else {
				set_mode(.GUI)
			}
		}

		if rl.IsKeyReleased(.ESCAPE) {
			if gamemode == .RIGHT_CLICK {
				set_mode(.POINTER)
			}
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.SKYBLUE)

			rl.BeginMode3D(camera3)
				//##
				draw_rat()
				//##
				update_pointer()

					//// Modes Update
				update_mode()

				draw_world_terrain()
				// Draw plants
				draw_plants()

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
			
			//## TEST Circle
			// circle_center: vec3 = {-20, 2, -20}
			// radius: f32 = 10 

			// for r in 0..<radius {
			//     for x in -r + 1..<r {
			//         for z in -r + 1..<r {
			//             this_pos: vec3 = {f32(x), 0, f32(z)}

			//             // Verificar si está dentro del círculo
			//             if (this_pos.x * this_pos.x + this_pos.z * this_pos.z) <= (r * r) {
			//                 rl.DrawCubeV(
			//                     (circle_center + this_pos) + {0.5, 0.5, 0.5}, 
			//                     {1, 1, 1},
			//                     rl.RED,
			//                 )		
			//             }
			//         }
			//     }
			// }
	

			// for x in 0..< radius {
			// 	for z in 0..< radius {
			// 		this_pos: vec3 = {f32(x), 0, f32(z)}

			// 		if this_pos == circle_center {
			// 			continue
			// 		} 

			// 		rl.DrawCubeV(
			// 			(circle_center - {3, 1, 3} + this_pos) + {0.5, 0.5, 0.5} , 
			// 			{1, 1, 1},
			// 			rl.RED,
			// 		)		
			// 	}
			// }

			//##

			rl.EndMode3D()

				//// GUIS
			if gamemode == .GUI {
				menu_modes()
			}

			if gamemode == .RIGHT_CLICK {
				menu_right_click()
			}

			draw_time()

			rl.DrawFPS(0, 0)

			entity_gui()
			speed_gui()

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
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

	load_textures_and_models()
	defer unload_textures_and_models()

	// INITS 
	generate_world_terrain()
	init_world_path()

	rl.SetTargetFPS(60)



	//##
	test_init_rats()
	current_entity = 1

	init_some_plants()

	//##

	for !rl.WindowShouldClose() {

		if tick >= 25 {
			tick = 0
			update_entities()
			update_plants()
			update_time()
		}		

		if !in_gui {
			if gamemode == .FOCUS_ENTITY {
				rl.UpdateCamera(&camera3, .THIRD_PERSON)
				camera3.target = to_v3(get_current_entity().pos)
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
				rl.DrawModel(male_model, {0, 0, 0}, 1, rl.WHITE)
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

			if current_entity != -1 {
				entity_gui()
			}
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
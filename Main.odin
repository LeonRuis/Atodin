package Atalay 

import fmt "core:fmt"
import strings "core:strings"
import strconv "core:strconv"

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

////
WINDOW_WIDTH: f32 = 1400
WINDOW_HEIGHT: f32 = 750 

camera3: rl.Camera = {
	{0, 10, 10}, 
	{0, 3, 0},
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
	rl.SetTargetFPS(60)

	load_textures_and_models()
	defer unload_textures_and_models()

	// INITS 
	generate_world_terrain()
	init_world_path()

	//##
	test_init_rats()
	init_some_plants()

	current_entity = 1

	put_item_in_terrain_cell(
		create_item(&Rock_GameModel, "A Rock"),
		{0, 3, 0}
	)
	put_item_in_terrain_cell(
		create_item(&Rock_GameModel, "Rock n roll"),
		{0, 2, 1}
	)

	put_item_on_entity_inventory(create_item(&Rock_GameModel, "Rock test"), get_entity_from_id(1))
	put_item_on_entity_inventory(create_item(&Rock_GameModel, "Rock test 2"), get_entity_from_id(1))
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

	// UPDATES
		update_pointer()

	/* INPUTS */ {
		if rl.IsKeyReleased(.F) {
			if gamemode == .POINTER {
				set_mode(.FOCUS_ENTITY)
			} else if gamemode == .FOCUS_ENTITY {
				set_mode(.POINTER)
			}
		}

		//// Gui Modes 
			// Pointer-GUI
		if rl.IsKeyReleased(.LEFT_SHIFT) {
			if gamemode == .GUI {
				set_mode(.POINTER)
			} else {
				set_mode(.GUI)
			}
		}

			// Right Click
		if rl.IsKeyReleased(.U) {
			if gamemode == .RIGHT_CLICK {
				set_mode(.POINTER)
			}
		}

			// Pause 
		if rl.IsKeyReleased(.ESCAPE) {
			if gamemode == .PAUSE_GUI {
				set_mode(.POINTER)
			} else {
				set_mode(.PAUSE_GUI)
			}
		}

			// GUI
		if rl.IsKeyReleased(.TAB) {

		}

			// Deselect Entity, this erase entity GUI
		if rl.IsKeyReleased(.N) {
			current_entity = -1
		}


		if rl.IsKeyReleased(.TAB) {
			view_inventory = !view_inventory
		}
	}

		rl.BeginDrawing()
			rl.ClearBackground(rl.SKYBLUE)

			rl.BeginMode3D(camera3)
				mode()

				draw_entities()
				draw_world_terrain()
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
			rl.EndMode3D()

	/* GUIS */ { 
			if gamemode != .PAUSE_GUI {

				rl.DrawFPS(i32(WINDOW_WIDTH) - 75, 0)
				pointer_pos_str: string = "Pointer Position: "
				for val, i in pointer_pos {
					buf: [4]byte
					str := strconv.itoa(buf[:], val)
					pointer_pos_str = strings.concatenate({pointer_pos_str, str})

					if i != 2 {
						pointer_pos_str = strings.concatenate({pointer_pos_str, ", "})
					}
				}
				pointer_pos_cstr: cstring = strings.clone_to_cstring(pointer_pos_str)
				rl.DrawText(pointer_pos_cstr, 0, 20, 20, rl.DARKGREEN)

				draw_time()
				speed_gui()

				if current_entity != -1 {
					entity_gui()
				}
			}

			if gamemode == .GUI {
				menu_modes()
			}

			if gamemode == .RIGHT_CLICK {
				menu_right_click()
			}

			if gamemode == .PAUSE_GUI {
				pause_gui()
			}


			if view_inventory {
				inventory_gui()
			}
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

	height := terrain[{int(pointer.x), int(pointer.z)}].floor_height
	pointer_pos = {int(pointer.x), int(height), int(pointer.z)}
}
////
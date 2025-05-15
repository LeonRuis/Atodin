package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import rl "vendor:raylib"

window_width: i32 = 1200
window_height: i32 = 799

tile_pixel_size :: 32

// 
font_size :: 20
//

entity_atlas: rl.Texture2D

male := vec2i{0, 0} * tile_pixel_size
female := vec2i{1, 0} * tile_pixel_size

main :: proc() {
	// Init Engine
	rl.InitWindow(window_width, window_height, "Atalay 2D")
	defer rl.CloseWindow()

	// rl.ToggleBorderlessWindowed()
	rl.GuiSetStyle(.DEFAULT, 16, font_size)
	rl.GuiSetStyle(.DEFAULT, 2, i32(rl.ColorToInt(rl.BLACK)))
	rl.GuiSetStyle(.PROGRESSBAR, 0, i32(rl.ColorToInt(rl.BLACK)))

	rl.SetTargetFPS(60)

	// Init Game
	entity_atlas = rl.LoadTexture("Entity_Atlas.png")
	defer rl.UnloadTexture(entity_atlas)

	terrain_init()
	path_init()

	//##

	create_entity({0, 0, 0}, "Tert", male)
	create_entity({3, 0, 2}, "Afliton", male)
	create_entity({7, 0, 3}, "Ina", female)

	tick: u32 = 0	
	pause: bool = false
	//##

	for !rl.WindowShouldClose() {
		//##
		if rl.IsMouseButtonPressed(.LEFT) {
			ok := (mouse_grid_pos in path_world)
			fmt.println(ok)
		}

		if rl.IsKeyPressed(.SPACE) {
			pause = !pause
		}

		if !pause {
			tick += 1
		}

		if tick == 30 {
			tick = 0

			entities_update()
		}

		// Choose Current Entity
		if !in_gui {
			if rl.IsMouseButtonPressed(.LEFT) {
				if terrain_world[mouse_grid_pos].entity != null_id {
					current_entity = terrain_world[mouse_grid_pos].entity
				}
			} else {
				target_entity = terrain_world[mouse_grid_pos].entity
			}
		}
		//##	

		camera_control()

		rl.BeginDrawing()
			rl.ClearBackground(rl.GRAY)

			rl.BeginMode2D(camera)
				terrain_draw()			
				entities_draw()

				// Draw Mouse Position
				if mouse_grid_pos in terrain_world {
					rl.DrawRectangleLines(mouse_grid_pos.x * tile_pixel_size, mouse_grid_pos.z * tile_pixel_size, tile_pixel_size, tile_pixel_size, rl.WHITE)
				}

				//##
				// for key_pos, path_cell in path_world {
				// 	rl.DrawRectangleLines(key_pos.x * tile_pixel_size, key_pos.z * tile_pixel_size, tile_pixel_size, tile_pixel_size, rl.YELLOW)
				// }	
				//##

			rl.EndMode2D()

			rl.DrawFPS(0, 0)
			entity_gui()
		rl.EndDrawing()

	}
}

// Terrain
terrain_world: map[vec3i]Terrain_Cell

map_size: vec3i = {50, 1, 50}
seed: i64 = 799
scale: f64 = 0.01

Terrain_Cell :: struct {
	color: rl.Color,
	entity: u32
}

terrain_init :: proc() {
	// seed = i64(rand.int31())
	for x in 0..<map_size.x {
		for y in 0..<map_size.y {
			for z in 0..<map_size.z {
				pos: vec3i = {x, y, z}

				color := rl.DARKGREEN

				moist_value := noise.noise_2d(seed, {f64(x) * scale, f64(z) * scale})
				moist_v := i32(moist_value * 10)

				if moist_v >= 8 {
					color = rl.SKYBLUE

				}

				terrain_cell: Terrain_Cell = {
					color,
					null_id
				}

				terrain_world[pos] = terrain_cell
			}
		}
	}
}

terrain_draw :: proc() {
	for key_pos, cell in terrain_world {
		pos := key_pos * tile_pixel_size
		rl.DrawRectangle(pos.x, pos.z, tile_pixel_size, tile_pixel_size, cell.color)
	}	
}

// Camera
camera: rl.Camera2D = {
	offset = {0, 0},
	target = {0, 0},
	zoom = 1
}

camera_speed: f32 = 15

mouse_grid_pos: vec3i 

camera_control :: proc() {
	mouse_grid_v2 := rl.GetMousePosition()
	mouse_grid_v2 = rl.GetScreenToWorld2D(mouse_grid_v2, camera)

	mouse_grid_pos = {i32(mouse_grid_v2.x), 0, i32(mouse_grid_v2.y)} / tile_pixel_size

	if rl.IsKeyDown(.W) { camera.target.y -= camera_speed }
	if rl.IsKeyDown(.S) { camera.target.y += camera_speed }
	if rl.IsKeyDown(.D) { camera.target.x += camera_speed }
	if rl.IsKeyDown(.A) { camera.target.x -= camera_speed }

	if rl.GetMouseWheelMove() == 1 {
		camera.zoom += 0.1
	}

	if rl.GetMouseWheelMove() == -1 {
		camera.zoom -= 0.1
	}

	if camera.zoom <= 0 {
		camera.zoom = 0.1
	}
}

// Entity Control
current_entity: u32 = 1
target_entity: u32 = 0

in_gui: bool = false

in_right_click: bool = false
rc_world_pos: vec3i
rc_target_ent: u32

entity_gui :: proc() {
	in_gui = false
	if current_entity == null_id {
		return
	}

	ent := get_entity(current_entity)

	// Data Display
		// Tasks
	tasks_rect: rl.Rectangle = {
		0, 0,
		100, 100
	}

	rl.GuiPanel(tasks_rect, ent.name)
	button_rect := tasks_rect
	button_rect.height = 27

	for &task in ent.tasks {
		button_rect.y += 25

		if rl.GuiButton(button_rect, task.title) {
			end_task(current_entity, &task)
		}
	}

		// Social 
	social_rect: rl.Rectangle = {
		165, 0,
		200, 50
	}

	rl.GuiProgressBar(social_rect, "Social:", "", &ent.social, 0, ent.max_social)

		// Water
	water_rect: rl.Rectangle = {
		165, 50,
		200, 50
	}

	rl.GuiProgressBar(water_rect, "Water:", "", &ent.water, 0, ent.max_water)

	// Right Click Menu
	if rl.IsMouseButtonPressed(.RIGHT) {
		if !in_right_click {
			in_right_click = true 

			rc_world_pos = mouse_grid_pos
			rc_target_ent = target_entity
		} else {
			in_right_click = false 
		}
	}

	right_click_gui()
}

right_click_gui :: proc() {
	if !in_right_click {
		return
	}

	screen_pos := rl.GetWorldToScreen2D({f32(rc_world_pos.x) * tile_pixel_size , f32(rc_world_pos.z) * tile_pixel_size}, camera)
	rl.DrawRectangleLines(i32(screen_pos.x), i32(screen_pos.y), i32(tile_pixel_size * camera.zoom), i32(tile_pixel_size * camera.zoom), rl.RED)

	rect: rl.Rectangle = {
		f32(screen_pos.x + (tile_pixel_size * camera.zoom)), f32(screen_pos.y),
		100, 100
	}

	rl.GuiPanel(rect, "Options")

	if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect) {
		in_gui = true
	}

	button_rect: rl.Rectangle = {
		rect.x, rect.y + 25,
		rect.width, 27
	}

	// Move Here
	if rl.GuiButton(button_rect, "Move Here") {
		ent := get_entity(current_entity)
		add_task(
			current_entity, 
			Task {
				get_task_id(),
				"Move to",
				false,
				false,

				{},
				rc_world_pos,

				Move { }
			}
		)

		in_right_click = false
	}

	// Social Entity
	if rc_target_ent == null_id || rc_target_ent == current_entity { } else {

		button_rect.y += 25
		if rl.GuiButton(button_rect, "Social") {
			add_task(
				current_entity,
				Task {
					get_task_id(),
					"Social",
					false,
					false,

					{},
					{},

					Social {
						rc_target_ent,
						0,
						5
					}
				}
			)
			in_right_click = false
		}
	}

	// Drink From Terrain
	if rc_world_pos in valid_drink_cells {

		button_rect.y += 25
		if rl.GuiButton(button_rect, "Drink From") {
			add_task(
				current_entity,
				Task {
					get_task_id(),
					"Drink Water",
					false,
					false,

					{},
					rc_world_pos,

					Drink {}
				}
			)
			in_right_click = false
		}
	}
}

////
vec3i :: [3]i32
vec3 :: [3]f32

vec2i :: [2]i32
vec2 :: [2]f32

N :: vec3i{0, 0, -1}
S :: vec3i{0, 0, 1}
E :: vec3i{1, 0, 0}
W :: vec3i{-1, 0, 0}

v2i_to_v2 :: proc(vi: vec2i) -> vec2 {
	v: vec2 = {f32(vi.x), f32(vi.y)}
	return v
}

v3i_to_v2 :: proc(vi: vec3i) -> vec3 {
	v: vec3 = {f32(vi.x), f32(vi.y), f32(vi.z)}
	return v
}

draw_sprite :: proc(atlas: ^rl.Texture2D, world_pos: vec3i, sprite_vec: vec2i) {
	source: rl.Rectangle = {f32(sprite_vec.x), f32(sprite_vec.y), tile_pixel_size, tile_pixel_size}
	dest: rl.Rectangle = {f32(world_pos.x) * tile_pixel_size, f32(world_pos.z) * tile_pixel_size, tile_pixel_size, tile_pixel_size}
	origin: vec2 = {0, 0}
	rot: f32 = 0

	rl.DrawTexturePro(
		atlas^,
		source,
		dest,
		origin,
		rot,
		rl.WHITE
	)
}

get_path :: proc(source, target: vec3i, adyacent: bool) -> [dynamic]vec3i {
	path := path(source, target, adyacent)

	if len(path) == 0 {
		return {}
	}

	ordered_remove(&path, 0)

	if adyacent {
		ordered_remove(&path, len(path) - 1)
	}

	return path
}
////
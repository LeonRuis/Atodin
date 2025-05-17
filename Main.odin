package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import strings "core:strings"
import rl "vendor:raylib"

window_width: i32 = 1200
window_height: i32 = 799

tile_pixel_size  :: 32
item_pixel_size  :: 16
plant_pixel_size :: 16
// 
font_size :: 20
//

	// Entities
entity_atlas: rl.Texture2D

male := vec2i{0, 0} * tile_pixel_size
female := vec2i{1, 0} * tile_pixel_size

	// Items
item_atlas: rl.Texture2D

rock  :: vec2i{0, 0}
stick :: vec2i{1, 0}
carrot_item :: vec2i{2, 0}

	// Plants
plant_atlas: rl.Texture2D

carrot_plant :: vec2i{0, 0}
rose_bush :: vec2i{1, 0}

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

	item_atlas = rl.LoadTexture("Items_Atlas.png")
	defer rl.UnloadTexture(item_atlas)

	plant_atlas = rl.LoadTexture("Plants_Atlas.png")
	defer rl.UnloadTexture(plant_atlas)

	terrain_init()
	path_init()

	//##
	create_plant(&carrot_plant_data, {15, 0, 0})

	place_item_in_world(
		get_item_from_item_data(&rock_item_data),
		{3, 0, 3} 
	)

	place_item_in_world(
		get_item_from_item_data(&carrot_item_data),
		{6, 0, 10}
	)

	create_entity({0, 0, 0}, "Tert", male)
	create_entity({3, 0, 2}, "Afliton", male)
	create_entity({7, 0, 3}, "Ina", female)

	place_item_in_inventory(
		get_item_from_item_data(&carrot_item_data),
		&get_entity(1).inventory
	)

	tick: u32 = 0	
	pause: bool = false
	//##

	for !rl.WindowShouldClose() {
		//##
		if rl.IsMouseButtonPressed(.LEFT) {
			fmt.println(mouse_grid_pos)
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

				//##
				// draw_plant(carrot, mouse_grid_pos)
				//##

				// Draw Mouse Position
				if mouse_grid_pos in terrain_world {
					rl.DrawRectangleLines(mouse_grid_pos.x * tile_pixel_size, mouse_grid_pos.z * tile_pixel_size, tile_pixel_size, tile_pixel_size, rl.WHITE)
				}

			rl.EndMode2D()

			//--
			if len(terrain_world[mouse_grid_pos].items) > 0 {
				str: string = ""

				label_rect: rl.Rectangle = {
					(f32(window_width) / 2) - 175, f32(window_height) - 50,
					500, 50
				}

				s: string
				for item, i in terrain_world[mouse_grid_pos].items {
					s = strings.clone_from_cstring(item.name)
					if i == 0 {
						str = strings.concatenate({str, s})
						continue
					}

					str = strings.concatenate({str, " - ", s})
				}

				cstr := strings.clone_to_cstring(str)

				rl.GuiLabel(label_rect, cstr)
			}
			//--

			rl.DrawFPS(0, 0)
			entity_gui()
		rl.EndDrawing()

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

in_item_options: bool = false
item_in_options: Item
item_options_rect: rl.Rectangle

in_plant_options: bool = false
plant_options_pos: vec3i

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

	// Needs
	needs_rect: rl.Rectangle = {
		165, 0,
		200, 50
	}

		// Social 
	social_rect := needs_rect

	rl.GuiProgressBar(social_rect, "Social:", "", &ent.social, 0, ent.max_social)

		// Water
	water_rect := needs_rect
	water_rect.y += 50

	rl.GuiProgressBar(water_rect, "Water:", "", &ent.water, 0, ent.max_water)

		// Food
	food_rect := needs_rect
	food_rect.x += 275

	rl.GuiProgressBar(food_rect, "Food:", "", &ent.food, 0, ent.max_food)


	// Inventory
	inventory_rect: rl.Rectangle = {
		0, f32(window_height) - 200,
		400, 200 
	}

	rl.GuiPanel(inventory_rect, "Items")

	slot_rect: rl.Rectangle = {
		inventory_rect.x, inventory_rect.y,
		inventory_rect.width / 2, 27 
	}

	item_rect: rl.Rectangle = {
		inventory_rect.x + slot_rect.width, slot_rect.y,
		inventory_rect.width / 2, 27 
	}

	for slot in ent.inventory {
		slot_rect.y += 30
		item_rect.y += 30
		rl.GuiLabel(slot_rect, slot.name)

		switch &item in slot.item_type {
			case Item:
				if rl.GuiButton(item_rect, item.name) {
					if in_item_options {
						in_item_options = false 
					} else {
						in_item_options = true
						item_in_options = item
						item_options_rect = item_rect
						item_options_rect.x += 200
					}
				}

			case Null_Item:
				rl.GuiLabel(item_rect, "No Item")
		}
	} 

		// Item Options
	if in_item_options && item_in_options.id != null_id {
		rl.GuiPanel(item_options_rect, "Options")

		// Drop Item
		option_rect: rl.Rectangle = item_options_rect
		option_rect.y += 25

		if rl.GuiButton(option_rect, "Drop") {
			remove_item_from_inventory(item_in_options, &ent.inventory)
			place_item_in_world(item_in_options, ent.pos)

			in_item_options = false
		}

		// Eat Item (if is food)
		#partial switch &type in item_in_options.item_data.type {
			case Item_Food:
				option_rect.y += 25
				if rl.GuiButton(option_rect, "Eat") {
					add_task(
						current_entity,
						Task {
							get_task_id(),
							"Eat Item",
							false,
							false,

							{},
							{},

							Eat_Full {
								item_in_options
							}
						}
					)

					in_item_options = false
				}
		}
	}

	// Plant Options
	if in_plant_options {
		screen_pos := rl.GetWorldToScreen2D({f32(plant_options_pos.x) * tile_pixel_size , f32(plant_options_pos.z) * tile_pixel_size}, camera)


		rect: rl.Rectangle = {
			f32(screen_pos.x + (tile_pixel_size * camera.zoom)), f32(screen_pos.y),
			100, 100
		}
		rl.GuiPanel(rect, "Plant Options")
		button_rect = rect 
		button_rect.height = 27
		button_rect.y += 25

		// Harvest Plant
		if rl.GuiButton(button_rect, "Harvest") {
			add_task(
				current_entity,
				Task {
					get_task_id(),
					"Harvest Plant",
					false,
					false,

					{},
					plant_options_pos,

					Harvest_Plant { terrain_world[plant_options_pos].plant }
				}	
			)
			in_plant_options = false
		}
	}

	// Right Click Menu
	if rl.IsMouseButtonPressed(.RIGHT) {
		if !in_right_click {
			in_right_click = true 

			rc_world_pos = mouse_grid_pos
			rc_target_ent = target_entity

			in_plant_options = false
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

	ent := get_entity(current_entity)

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

	// Pick Item From Terrain 
	if len(terrain_world[rc_world_pos].items) > 0 {
		for item in terrain_world[rc_world_pos].items {
			button_rect.y += 25

			if rl.GuiButton(button_rect, item.name) {
				in_right_click = false
				if check_empty_slot(&ent.inventory) {
					// Add task
					add_task(
						current_entity,
						Task {
							get_task_id(),
							"Pick Item",
							false, 
							false, 

							{},
							rc_world_pos,

							Pick_Item { item }
						}
					)

				} else {
					fmt.println("No space on inventory")
				}
			}
		}
	}

	// Plant Options
	if terrain_world[rc_world_pos].plant != null_id {
		button_rect.y += 25

		plant_id := terrain_world[rc_world_pos].plant
		if rl.GuiButton(button_rect, plants[plant_id].plant_data.title) {
			in_right_click = false
			in_plant_options = true
			plant_options_pos = rc_world_pos
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
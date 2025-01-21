package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

test :: struct {
	action: proc()
}

test_struct :: proc() {
	a_test: test = {
		test_proc
	}

	a_test.action()
}

test_proc :: proc() {
	fmt.println("===================================================")	
}

//----------------- Menu Modes ------------------------------------------------------
menu_modes :: proc() {
	menu_title: cstring = "Select Mode..."

	menu_pos_x: f32 = 0
	menu_pos_y: f32 = 0

	menu_size_x: f32 = 200
	menu_size_y: f32 = 500

	menu_rect: rl.Rectangle = {
		menu_pos_x,
		menu_pos_y,
		menu_size_x,
		menu_size_y
	}

	if rl.GuiWindowBox(menu_rect, menu_title) == 1 {
		set_mode(.POINTER)
	}

	offset: f32 = 25
	offset += btn_place_wall(menu_rect, offset)
	btn_pointer(menu_rect, offset)
}

btn_place_wall :: proc(rect: rl.Rectangle, offset: f32) -> f32 {
	btn_title: cstring = "Place Walls"

	btn_size_x: f32 = rect.width 
	btn_size_y: f32 = 30

	btn_rect: rl.Rectangle = {
		rect.x, rect.y + offset, 
		btn_size_x, btn_size_y
	}

	if rl.GuiButton(btn_rect, btn_title) {
		set_mode(.WALL_PLACE)
	}

	return btn_rect.y 
}

btn_pointer :: proc(rect: rl.Rectangle, offset: f32) -> f32 {
	btn_title: cstring = "Pointer"

	btn_size_x: f32 = rect.width 
	btn_size_y: f32 = 30

	btn_rect: rl.Rectangle = {
		rect.x, rect.y + offset, 
		btn_size_x, btn_size_y
	}

	if rl.GuiButton(btn_rect, btn_title) {
		set_mode(.POINTER)
	}

	return btn_rect.y
}

//----------------- Right Mouse Options ---------------------------------------
right_click_mode_pos: vec2

menu_right_click :: proc() {
	menu_rect: rl.Rectangle = {
		right_click_mode_pos.x,
		right_click_mode_pos.y,
		200,
		500,
	}	

	rl.GuiPanel(menu_rect, "Options")

	if rl.IsMouseButtonPressed(.LEFT) {
		set_mode(.POINTER)
	}
}

////
control_place_wall_btn :: proc() {

	x: i32 = 0
	y: i32 = 0	 

	size_x: f32 = 200
	size_y: f32 = 30

	color := rl.RED

	// Control Button
	mouse_point := rl.GetMousePosition()
	mouse_on: bool = rl.CheckCollisionPointRec(mouse_point, {f32(x), f32(y), size_x, size_y})

	if mouse_on {
		color = rl.GREEN

		if rl.IsMouseButtonReleased(.LEFT) {
			set_mode(.WALL_PLACE)
		}
	}

	// Draw Button
	rl.DrawRectangleV({f32(x), f32(y)}, {size_x, size_y}, color)
	rl.DrawText("Place Walls", x + 25, y + 4, 25, rl.BLACK)
}

control_move_entity_btn :: proc() {
	size_x: f32 = 200
	size_y: f32 = 30

	x: i32 = i32(size_x) + 10
	y: i32 = 0	 

	color := rl.RED

	// Control Button
	mouse_point := rl.GetMousePosition()
	mouse_on: bool = rl.CheckCollisionPointRec(mouse_point, {f32(x), f32(y), size_x, size_y})

	if mouse_on {
		color = rl.GREEN

		if rl.IsMouseButtonReleased(.LEFT) {
			set_mode(.MOVE_ENTITY)
		}
	}

	// Draw Button
	rl.DrawRectangleV({f32(x), f32(y)}, {size_x, size_y}, color)
	rl.DrawText("Move Selected Entity", x + 25, y + 4, 25, rl.BLACK)
}
////

selected_entity_gui :: proc() {
	// rl.DrawText(current_entity.name, 0, 0, 40, rl.BLACK)
}
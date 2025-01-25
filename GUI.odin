package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

Button :: struct {
	title: cstring,
	action: proc(),
	rect: rl.Rectangle
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
	
	// Buttons
	btn_place_wall: Button = {
		"Place Walls",
		pressed_place_wall,
		{}
	}	

	btn_pointer: Button = {
		"Pointer",
		pressed_pointer,
		{}
	}	

	menu_buttons: [2]Button = {
		btn_place_wall,
		btn_pointer
	}

	control_buttons(&menu_buttons, menu_rect)
}

pressed_place_wall :: proc() {
	set_mode(.WALL_PLACE)
}

pressed_pointer :: proc() {
	set_mode(.POINTER)
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

	// Buttons
	btn_move_here: Button = {
		"Move Entity Here...",
		pressed_move_here,
		{}
	}

	menu_buttons: [1]Button = {
		btn_move_here
	}

	control_buttons(&menu_buttons, menu_rect)
}

pressed_move_here :: proc() {
	set_entity_target_pos(current_entity, pointer_pos)
	set_mode(.POINTER)
}
//-------------------------------------------------------------------------------
entity_gui :: proc() {
	menu_width: f32 = 100
	menu_height: f32 = 100

	menu_x: f32 = 0
	menu_y: f32 = WINDOW_HEIGHT - menu_height

	rect: rl.Rectangle = {
		menu_x, 
		menu_y,
		menu_width,
		menu_height	
	}

	rl.GuiPanel(rect, current_entity.name)
	rl.GuiLabel(rect, get_entity_state())
}

get_entity_state :: proc() -> cstring {
	#partial switch current_entity.state {
	case .WONDER:
		return "Wonder"

	case: 
		return "NO VALID"
	}
}

//---------------- Tools -------------------------------------
control_buttons :: proc(buttons: ^$T, menu_rect: rl.Rectangle) {
	btn_size_x: f32 = menu_rect.width
	btn_size_y: f32 = 30

	btn_y_offset: f32 = 25

	for btn in buttons {
		new_rect: rl.Rectangle = {
			menu_rect.x,
			menu_rect.y + btn_y_offset,
			btn_size_x,
			btn_size_y
		}

		if rl.GuiButton(new_rect, btn.title) {
			btn.action()
		}

		btn_y_offset += btn_size_y
	}
}
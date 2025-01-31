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

	btn_eat_plant: Button = {
		"Eat Plant",
		pressed_eat_plant,
		{}
	}

	btn_drink_world: Button = {
		"Drink From Source",
		pressed_drink_world,
		{}
	}

	menu_buttons: [dynamic]Button

	append(&menu_buttons, btn_move_here)

	// Eat plant
	if pointer_pos in plants {
		append(&menu_buttons, btn_eat_plant)
	} 

	// Drink Source
	if terrain[{pointer_pos.x, pointer_pos.z}].water_source {
		append(&menu_buttons, btn_drink_world)
	} 


	control_buttons(&menu_buttons, menu_rect)
}

pressed_move_here :: proc() {
	add_task(current_entity, Move_To{pointer_pos, false, false})
	set_mode(.POINTER)
}

pressed_eat_plant :: proc() {
	add_task(current_entity, Eat_Plant{false, pointer_pos, &plants[pointer_pos]})
	set_mode(.POINTER)
}

pressed_drink_world :: proc() {
	add_task(current_entity, Drink_World{false, pointer_pos})
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

	// Needs
	water_rect: rl.Rectangle = {
		rect.x + rect.width, 
		rect.y,
		200,
		menu_height/2	
	}

	food_rect: rl.Rectangle = {
		rect.x + rect.width, 
		rect.y + rect.height/2,
		200,
		rect.height/2	
	}

	rl.GuiProgressBar(water_rect, "", "Water", &current_entity.water, 0, f32(current_entity.water_max))
	rl.GuiProgressBar(food_rect, "", "Food", &current_entity.food, 0, f32(current_entity.food_max))

	// Task Buttons
	btn_task_offset: f32 = 25 
	for task, i in current_entity.tasks {
		btn_rect: rl.Rectangle = {
			menu_x,
			menu_y + btn_task_offset,
			menu_width,
			30
		} 
		
		if rl.GuiButton(btn_rect, get_task_title(task)) {
			ordered_remove(&current_entity.tasks, i)
		}		
	
		btn_task_offset += 30
	}
}

get_task_title :: proc(task: Task) -> cstring {
	#partial switch t in task {
		case Move_To:
			return "Move To..."

		case Eat_Plant: 
			return "Eating Plant"

		case Drink_World:
			return "Drink From Source"

		case: 
			return "Not Defined Task"
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
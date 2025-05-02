package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import strings "core:strings"
import strconv "core:strconv"
import mem "core:mem"

Button :: struct {
	title: cstring,
	action: proc(),
}

Label :: struct {
	text: cstring,
}

// Modes ------------------------------------------------------
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
	}	

	btn_pointer: Button = {
		"Pointer",
		pressed_pointer,
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

// Right Mouse Options ---------------------------------------
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
	}

	// btn_eat_plant: Button = {
	// 	"Eat Plant",
	// 	pressed_eat_plant,
	// }

	// btn_drink_world: Button = {
	// 	"Drink From Source",
	// 	pressed_drink_world,
	// }

	// btn_sleep: Button = {
	// 	"Sleep",
	// 	pressed_sleep,
	// }

	// btn_positive_social: Button = {
	// 	"Social +",
	// 	pressed_positive_social,
	// }

	// btn_pick_item: Button = {
	// 	"Pick",
	// 	pressed_pick_item,
	// }

	menu_buttons: [dynamic]Button

	append(&menu_buttons, btn_move_here)

	// // Eat plant
	// if pointer_pos in plants && plants[pointer_pos].grow >= 200 {
	// 	append(&menu_buttons, btn_eat_plant)
	// } 

	// // Drink Source
	// if terrain[{pointer_pos.x, pointer_pos.z}].water_source {
	// 	append(&menu_buttons, btn_drink_world)
	// } 

	// // Social +
	// if world[pointer_pos].entity_id != current_entity && world[pointer_pos].entity_id != -1 {
	// 	append(&menu_buttons, btn_positive_social)
	// 	social_entity = world[pointer_pos].entity_id
	// }

	// // Selected entity Options
	// if get_current_entity().pos == pointer_pos {
	// 	append(&menu_buttons, btn_sleep)
	// }

	// // Pick Item
	// terrain_cell := &terrain[{pointer_pos.x, pointer_pos.z}]
	// if len(terrain_cell.items) == 1 {
	// 	if pointer_pos.y == terrain_cell.floor_height {
	// 		item := terrain_cell.items[0]
	// 		btn_pick_item.title = strings.clone_to_cstring(strings.concatenate({"Pick ", item.name}))
	// 		append(&menu_buttons, btn_pick_item)
	// 	}
	// }

	// if len(terrain_cell.items) > 1 {
	// 	fmt.println("open pile inventory")
	// }

	control_buttons(&menu_buttons, menu_rect)
}

pressed_move_here :: proc() {
	add_task(
		get_current_entity(),
		Task{
			pick_task_id(),
			false,
			false,

			Move_To{
				pointer_pos
			}
		} 
	)
	set_mode(.POINTER)
}

// pressed_eat_plant :: proc() {
// 	add_task(get_current_entity(), Eat_Plant{false, pointer_pos})
// 	set_mode(.POINTER)
// }

// pressed_drink_world :: proc() {
// 	add_task(get_current_entity(), Drink_World{false, pointer_pos})
// 	set_mode(.POINTER)
// }

// pressed_sleep :: proc() {
// 	add_task(get_current_entity(), Sleep{})
// 	set_mode(.POINTER)
// }

// pressed_positive_social :: proc() {
// 	add_task(get_current_entity(), Social_Positive{social_entity, false, false, 10})
// 	set_mode(.POINTER)
// }

// pressed_pick_item :: proc() {
// 	add_task(get_current_entity(), PickItem{false, pointer_pos, terrain[{pointer_pos.x, pointer_pos.z}].items[0]})
// 	set_mode(.POINTER)
// }

social_entity: int = -1

// Entity -------------------------------------------------------------------------------
entity_gui :: proc() {
	// Data Display
	menu_data_width: f32 = 200
	menu_data_height: f32 = 200

	menu_data_x: f32 = 0
	menu_data_y: f32 = WINDOW_HEIGHT - menu_data_height

	menu_data_rect: rl.Rectangle = {
		menu_data_x, 
		menu_data_y,
		menu_data_width,
		menu_data_height
	}

	labels: [dynamic]Label

	gender: string
	switch get_current_entity().gender {
		case true:
			gender = "Male"

		case:
			gender = "Female"
	}

	gender_string: string = strings.concatenate({"Gender: ", gender})
	gender_text: cstring = strings.clone_to_cstring(gender_string)

	label_gender: Label = {
		gender_text,
	}

	dob_string: string = strings.concatenate({"Date of Bird: ", date_to_string(get_current_entity().dob)})
	dob_text: cstring = strings.clone_to_cstring(dob_string)
	label_dob: Label = { // DOB = Date of Bird
		dob_text,
	}

	age_text: cstring = strings.clone_to_cstring(get_age(get_current_entity().age))

	label_age: Label = { 
		age_text,
	}

	append(&labels, label_gender)
	append(&labels, label_dob)
	append(&labels, label_age)

	rl.GuiPanel(menu_data_rect, strings.clone_to_cstring(get_current_entity().name))

	control_labels(&labels, menu_data_rect)

	// Tasks
	menu_width: f32 = 150
	menu_height: f32 = 100

	menu_x: f32 = menu_data_width 
	menu_y: f32 = WINDOW_HEIGHT - menu_height

	rect: rl.Rectangle = {
		menu_x, 
		menu_y,
		menu_width,
		menu_height	
	}

	rl.GuiPanel(rect, "Tasks")

	// Needs
	water_rect: rl.Rectangle = {
		rect.x + rect.width, 
		rect.y,
		200,
		menu_height/3	
	}

	food_rect: rl.Rectangle = {
		rect.x + rect.width, 
		rect.y + rect.height/3,
		200,
		rect.height/3	
	}

	sleep_rect: rl.Rectangle = {
		rect.x + rect.width, 
		rect.y + rect.height/3 * 2,
		200,
		rect.height/3
	}

	social_rect: rl.Rectangle = {
		rect.x + rect.width + 300, 
		rect.y + rect.height/3 * 2,
		200,
		rect.height/3
	}

	mating_rect: rl.Rectangle = {
		rect.x + rect.width + 300, 
		rect.y,
		200,
		rect.height/3
	}

	ent := get_current_entity()
	water, food, sleep, social, mating: f32 = f32(ent.water), f32(ent.food), f32(ent.sleep), f32(ent.social), f32(ent.mating)

	rl.GuiProgressBar(water_rect, "", "Water", &water, 0, f32(ent.water_max))
	rl.GuiProgressBar(food_rect, "", "Food", &food, 0, f32(ent.food_max))
	rl.GuiProgressBar(sleep_rect, "", "Sleep", &sleep, 0, f32(ent.sleep_max))
	rl.GuiProgressBar(social_rect, "", "Social", &social, 0, f32(ent.social_max))
	rl.GuiProgressBar(mating_rect, "", "Mating", &mating, 0, f32(ent.mating_max))

	// Task Buttons
	btn_task_offset: f32 = 25 
	for task, i in get_current_entity().tasks {
		btn_rect: rl.Rectangle = {
			menu_x,
			menu_y + btn_task_offset,
			menu_width,
			30
		} 
		
		if rl.GuiButton(btn_rect, get_task_title(task)) {
			cancel_task(get_current_entity(), i)
		}		
	
		btn_task_offset += 30
	}
}

get_task_title :: proc(task: Task) -> cstring {
	#partial switch type in task.type {
		case Move_To:
			return "Move To..."

		// case Eat_Plant: 
		// 	return "Eating Plant"

		// case Drink_World:
		// 	return "Drink From Source"

		// case Sleep: 
		// 	return "Sleep"

		// case Social_Positive: 
		// 	str: string = strings.concatenate({"Social With ", get_entity_from_id(t.entity_id).name})
		// 	return strings.clone_to_cstring(str) 

		// case PickItem:
		// 	str: string = strings.concatenate({"Picking ", t.item.name})
		// 	return strings.clone_to_cstring(str) 

		case: 
			return "Not Defined Task"
	}
}

// Pause --------------------------------------
in_borderless: bool = false 

pause_gui :: proc() {
	rect: rl.Rectangle = {
		0,
		0, 
		WINDOW_WIDTH,
		WINDOW_HEIGHT
	}

	btn_rect: rl.Rectangle = {
		WINDOW_WIDTH / 2,
		WINDOW_HEIGHT / 2,
		200, 
		200,
	}

	rl.GuiLabel(rect, "This is the Pause Menu")
	if rl.GuiButton(btn_rect, "Borderless Window") {
		set_borderles_window()
	}
}

set_borderles_window :: proc() {
	rl.ToggleBorderlessWindowed()
	if in_borderless {
		WINDOW_WIDTH = 1400
		WINDOW_HEIGHT = 750 
	} else {
		WINDOW_WIDTH = f32(rl.GetMonitorWidth(1))
		WINDOW_HEIGHT = f32(rl.GetMonitorHeight(1))
	}
		in_borderless = !in_borderless
}

//---------------- Other guis -------------------------------------
tick: int = 0
speed: i32 = 1

speed_gui :: proc() {
	rect: rl.Rectangle = {
		WINDOW_WIDTH - 100 * 4,
		WINDOW_HEIGHT - 20, 
		100,
		20
	}

	// Speed by GUI
	rl.GuiToggleGroup(rect, "Pause;Normal;Fast;Forward", &speed)

	// Speed by Input
	if rl.IsKeyReleased(.G) {
		if speed == 0 {
			speed = 1	
		} else {
			speed = 0
		}
	} else if rl.IsKeyReleased(.ONE) {
		speed = 1
	} else if rl.IsKeyReleased(.TWO) {
		speed = 2
	} else if rl.IsKeyReleased(.THREE) {
		speed = 3
	}

	// Speed Control
	switch speed {
		case 0: 
			return

		case 1:
			tick += 1

		case 2:
			tick += 2

		case 3:
			tick += 15

		case:	
			fmt.println("No Speed Defined")
			tick += 0 
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

control_labels :: proc(labels: ^$T, menu_rect: rl.Rectangle) {
	label_width: f32 = menu_rect.width
	label_height: f32 = 30

	label_y_offset: f32 = 25

	for label in labels {
		new_rect: rl.Rectangle = {
			menu_rect.x,
			menu_rect.y + label_y_offset,
			label_width,
			label_height
		}

		rl.GuiLabel(new_rect, label.text)
		label_y_offset += label_height
	}
}

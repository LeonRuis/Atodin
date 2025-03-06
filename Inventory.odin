package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"
import strings "core:strings"
import strconv "core:strconv"
import mem "core:mem"

view_inventory: bool = false
item_to_draw_id: int 

ButtonInventory :: struct {
	title: cstring,
	action: proc(item: Item),
	item: Item,
}

inventory_gui :: proc() {
	menu_rect: rl.Rectangle = {
		0, 
		WINDOW_HEIGHT/2 - WINDOW_HEIGHT/4, 
		WINDOW_WIDTH/4,
		WINDOW_HEIGHT/2
	}

	labels_rect: rl.Rectangle = {
		menu_rect.x,
		menu_rect.y,
		menu_rect.width/2,
		menu_rect.height 
	}

	buttons_rect: rl.Rectangle = {
		menu_rect.width/2,
		menu_rect.y,
		menu_rect.width/2,
		menu_rect.height 
	}

	rl.GuiPanel(menu_rect, "Inventory")

	ent := get_current_entity()
	body_parts_count: int = len(ent.inventory)

	labels: [dynamic]Label
	buttons: [dynamic]ButtonInventory

	for body_part in ent.inventory {
		new_label: Label = {
			get_body_part_cstr(body_part),
		}

		append(&labels, new_label)

		slot: Slot = ent.inventory[body_part] 

		switch item in slot {
			case NullItem:

			case Item:
				new_button: ButtonInventory = {
					strings.clone_to_cstring(item.name),
					pressed_item,
					item,
				}

				append(&buttons, new_button)
		}
	}

	control_labels(&labels, labels_rect)
	control_buttons_inventory(&buttons, buttons_rect)
}

get_body_part_cstr :: proc(body_part: BodyPart) -> cstring {
	#partial switch body_part {
		case .MOUTH:
			return "Mouth"

		case .L_HAND:
			return "Left Hand"

		case .R_HAND:
			return "Right Hand"

		case: 
			return "Invalid Body Part"
	}
}

pressed_item :: proc(item: Item) {
	if item_to_draw_id == item.id {
		item_to_draw_id = {}
	} else {
		item_to_draw_id = item.id
	}
}

control_buttons_inventory :: proc(buttons: $T, menu_rect: rl.Rectangle) {
	btn_size_x: f32 = menu_rect.width
	btn_size_y: f32 = 30

	btn_y_offset: f32 = 25

	for &btn in buttons {
		new_rect: rl.Rectangle = {
			menu_rect.x,
			menu_rect.y + btn_y_offset,
			btn_size_x,
			btn_size_y
		}

		if rl.GuiButton(new_rect, btn.title) {
			btn.action(btn.item)
		}

		if btn.item.id == item_to_draw_id {
			active_rect: rl.Rectangle = {
				btn_size_x + menu_rect.x,
				new_rect.y,
				200,
				40 * f32(len(btn.item.actions))
			}

			rl.GuiPanel(active_rect, "Item Options")

			item_options_rect: rl.Rectangle = {
				active_rect.x,
				active_rect.y + 25,
				active_rect.width,
				35
			}

			for action in btn.item.actions {
				if rl.GuiButton(item_options_rect, "Drop") {
					action(get_current_entity(), btn.item)
				}
				item_options_rect.y += 35
			}
		}

		btn_y_offset += btn_size_y
	}
}

// Crafting Menu

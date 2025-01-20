package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

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
			set_place_wall_mode()
			fmt.println("Place Walls")
		}
	}

	// Draw Button
	rl.DrawRectangleV({f32(x), f32(y)}, {size_x, size_y}, color)
	rl.DrawText("Place Walls", x + 25, y + 4, 25, rl.BLACK)
}

selected_entity_gui :: proc() {
	rl.DrawText(current_entity.name, 0, 0, 40, rl.BLACK)
}
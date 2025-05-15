package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import rl "vendor:raylib"

terrain_world: map[vec3i]Terrain_Cell

map_size: vec3i = {50, 1, 50}
seed: i64 = 799
scale: f64 = 0.01

Terrain_Cell :: struct {
	color: rl.Color,
	entity: u32,
	plant: u32,

	items: [dynamic]Item
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
					color = color,
					entity = null_id,
					plant = null_id,
					items = {}
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

		if len(cell.items) > 0 {
			draw_item(key_pos, cell.items[0].item_data.sprite_dir)
		}

		if cell.plant != null_id {
			plant := &plants[cell.plant]
			draw_plant(plant.plant_data.sprite_dir, key_pos)	
		}
	}	
}
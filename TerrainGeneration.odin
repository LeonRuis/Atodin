package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rl "vendor:raylib"

Tile :: enum {
	GRASS,
	SAND
}

CHUNK_SIZE :: vec3i{20, 10, 20}
seed: i64 = 4 
scale: f64 = 0.1

generate_world_terrain :: proc() {
	for x in 0..<CHUNK_SIZE.x {
		for y in 0..<CHUNK_SIZE.y {
			for z in 0..<CHUNK_SIZE.z {
				this_pos: vec3i = {x, y, z}

				noise_value := noise.noise_2d(seed, {f64(x) * scale, f64(z) * scale}) + 1
				max_y := int(noise_value)

				cell_to_draw: bool = (y == max_y) 

				this_terrain_cell: terrain_cell = {
					grass_tile,
					y
				}

				if cell_to_draw {
					terrain[{x, z}] = this_terrain_cell
				}
			}
		}
	}
}

terrain: map[vec2i]terrain_cell

terrain_cell :: struct {
	tile: rl.Model,
	floor_height: int
}

draw_world_terrain :: proc() {
	for key_pos, &cell in terrain {
			rl.DrawModel(cell.tile, {f32(key_pos.x), f32(cell.floor_height * 2) , f32(key_pos.y)}, 1.0, rl.WHITE)
		}
}
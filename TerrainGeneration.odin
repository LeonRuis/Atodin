package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rl "vendor:raylib"

Tile :: enum {
	GRASS,
	SAND
}

CHUNK_SIZE :: vec3i{20, 10, 20}

generate_world_terrain :: proc() {
	seed: i64 = 15
	scale: f64 = 0.1
	index: int = 0 

	for x in 0..<CHUNK_SIZE.x {
		for y in 0..<CHUNK_SIZE.y {
			for z in 0..<CHUNK_SIZE.z {
				this_pos: vec3i = {x, y, z}

				noise_value := noise.noise_2d(seed, {f64(x) * scale, f64(z) * scale}) + 1
				max_y := int(noise_value)

				cell_to_draw: bool = (y == max_y) 

				this_terrain_cell: terrain_cell = {
					this_pos,
					grass_tile,
					cell_to_draw
				}

				terrain[index] = this_terrain_cell
				index += 1
			}
		}
	}
}

terrain: [20 * 20 * 10]terrain_cell

terrain_cell :: struct {
	pos: vec3i,
	tile: rl.Model,
	to_draw: bool
}

draw_world_terrain :: proc() {
	for &cell in terrain {
		if cell.to_draw {
			rl.DrawModel(cell.tile, {f32(cell.pos.x), f32(cell.pos.y), f32(cell.pos.z)}, 1.0, rl.WHITE)
		}
	}
}
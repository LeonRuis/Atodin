package Atalay

import fmt "core:fmt"
import noise "core:math/noise"
import rl "vendor:raylib"
import rand "core:math/rand"

Tile :: enum {
	GRASS,
	SAND
}

CHUNK_SIZE :: vec3i{50, 10, 50}
seed: i64// = 799
scale: f64 = 0.01

generate_world_terrain :: proc() {
	seed = i64(rand.int31())
	temp_seed := i64(rand.int31())
	moist_seed := i64(rand.int31())

	// fmt.println(seed, temp_seed, moist_seed)
	for x in 0..<CHUNK_SIZE.x {
		for y in 0..<CHUNK_SIZE.y {
			for z in 0..<CHUNK_SIZE.z {
				this_pos: vec3i = {x, y, z}

				noise_value := (noise.noise_2d(seed, {f64(x) * scale, f64(z) * scale}) + 1)
				max_y := int(noise_value * 3)

				cell_to_draw: bool = (y == max_y) 

				// Asign tile 
				temp_value := noise.noise_2d(temp_seed, {f64(x) * scale, f64(z) * scale}) * 100
				moist_value := noise.noise_2d(moist_seed, {f64(x) * scale, f64(z) * scale}) * 100

				water_source: bool	
				cell_tile: rl.Model = grass_model


				if  temp_value > 40 {
					cell_tile = sand_model
				} 

				if moist_value >= 70 {
					cell_tile = water_model 
					water_source = true
				}	

				if cell_to_draw {
					this_terrain_cell: terrain_cell = {
						cell_tile,
						y,

						int(temp_value),
						int(moist_value),
						water_source,

						{}
					}

					terrain[{x, z}] = this_terrain_cell
				}
			}
		}
	}
}

terrain: map[vec2i]terrain_cell

terrain_cell :: struct {
	tile: rl.Model,
	floor_height: int,

	temp: int,
	moist: int,

	water_source: bool,

	items: [dynamic]Item
}

draw_world_terrain :: proc() {
	for key_pos, &cell in terrain {
		this_pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}
		this_pos_visual: vec3 = to_v3(to_visual_world(this_pos))

		rl.DrawModel(cell.tile, this_pos_visual, 1.0, rl.WHITE)

		// Draw First Item in Cell
		if len(cell.items) > 0 {
			draw_visual_instance(&cell.items[0].visual_instance, this_pos)
		}
	}

	draw_terrain_walls()
}

walls_neighbors: [4]vec3i = {
	N,
	S,
	W,
	E
}

draw_terrain_walls :: proc() {
	for key_pos, &cell in terrain {
		for dir in walls_neighbors {
			neighbor_pos: vec2i = {key_pos.x + dir.x, key_pos.y + dir.z}

			rot: f32 = 0
			pos: vec3i = {key_pos.x, cell.floor_height, key_pos.y}

			if terrain[neighbor_pos].floor_height == cell.floor_height {
				continue
			}

			if terrain[neighbor_pos].floor_height > cell.floor_height {
				// fmt.println(key_pos, "Draw", dir, ":", neighbor_pos)

				switch dir {
					case N:
						rot = 0

					case S:
						rot = 180
						pos += S
						pos += E

					case W:
						rot = 90
						pos += S

					case E:
						rot = -90
						pos += E
				}

				rl.DrawModelEx(
					grass_wall_model,
					to_v3(to_visual_world(pos)),
					{0, 1, 0},
					rot, 
					{1, 1, 1},
					rl.WHITE
				)
			}
		}
	}
}

// ----------------------- Other ----------------------------------------------------
put_item_in_terrain_cell :: proc(item: Item, pos: vec3i) {
	pos2d: vec2i = {pos.x, pos.z}
	cell := &terrain[pos2d]

	if cell.floor_height != pos.y {
		return
	}

	append(&cell.items, item)
}

remove_item_in_terrain_cell :: proc(item: Item, pos: vec3i) {
	pos2d: vec2i = {pos.x, pos.z}
	cell := &terrain[pos2d]	

	for itm, i in cell.items {
		if itm.id == item.id {
			ordered_remove(&cell.items, i)
			return
		}
	}
}
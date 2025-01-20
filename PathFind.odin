package Atalay 

import fmt "core:fmt" 
import math "core:math"

world: map[vec3i]cell

cell :: struct {
	walkable: bool,
	cells_conected: map[vec3i]bool,
	position: vec3i,
	walls: [4]Wall,
	entity: ^Entity
}

node :: struct {
	pos: vec3i,
	g, h, f: int,
	prev: vec3i,
}

neighbor_dirs: [dynamic]vec3i = {
	N,
	S,
	E,
	W,
	UP,
	DONW,
	UP + N,
	UP + S,
	UP + E,
	UP + W,
}

init_world_path :: proc() {
	//Init World Structure
	ind: int = 0
	for x in 0..< CHUNK_SIZE.x {
		for y in 0..< CHUNK_SIZE.y {
			for z in 0..< CHUNK_SIZE.z {
				ind += 1

				pos: vec3i = {x, y, z}
				pos2d: vec2i = {x, z}
				walk: bool = (pos2d in terrain && terrain[pos2d].floor_height == y)

				world[pos] = {
					walk,
					{},
					pos,
					{},
					{}
				}
			}
		}
	}


	// Fill World Cells Data
	for key_pos, &terrain_cell in terrain {
		this_pos: vec3i = {key_pos.x, terrain_cell.floor_height, key_pos.y}
		for dir in neighbor_dirs {
			neighbor := this_pos + dir 
			neighbor2d: vec2i = {neighbor.x, neighbor.z}

			if neighbor in world {
				connect_cell(this_pos, neighbor, true)
			}
		} 
	}

	fmt.println("Path Find Setup Ready...") //##############

}

connect_cell :: proc(A, B: vec3i, bidirectional: bool) {
	a: ^cell = &world[A]
	b: ^cell = &world[B]

	if bidirectional {

		// Check if already connected
		if a.position in b.cells_conected && b.position in a.cells_conected {
			return
		}

		a.cells_conected[b.position] = true
		b.cells_conected[a.position] = true
	}

	a.cells_conected[b.position] = true
}

disconnect_cells :: proc(A, B: vec3i) {
	if A in world && B in world {
		a: ^cell = &world[A]
		b: ^cell = &world[B]

		delete_key(&a.cells_conected, b.position)
		delete_key(&b.cells_conected, a.position)
	}
}

disable_cell :: proc(cell_pos: vec3i) {
	the_cell: cell = world[cell_pos]

	clear(&the_cell.cells_conected)

	for dir in neighbor_dirs {
		neighbor_pos: vec3i = dir + cell_pos
		neighbor_cell: cell = world[neighbor_pos]

		delete_key(&neighbor_cell.cells_conected, cell_pos)	
	}
}

path :: proc(source_pos, target_pos: vec3i) -> [dynamic]vec3i{
	open_list: map[vec3i]node
	closed_list: map[vec3i]node

	starting_node: node = {
		source_pos,
		0, 0, 0,
		source_pos
	}

	current_node: node

	open_list[source_pos] = starting_node

	// source and target valid
	if source_pos not_in world && target_pos not_in world {
		fmt.println("Unvalid source or target")
		return {}
	}

	// Path search logic
	for len(open_list) > 0 {

		// pick first node in list
		for key_pos, node in open_list {
			current_node = open_list[key_pos]
			break
		}

		// choose node with least f
		for key_pos, node in open_list {
			if node.f < current_node.f {
				current_node = node
			}
		}

		delete_key(&open_list, current_node.pos)
		closed_list[current_node.pos] = current_node

		// node is target
		if current_node.pos == target_pos {
			fmt.println("Path Found")
			return rebuild_path(source_pos, target_pos, &closed_list)
		}

		for cell in world[current_node.pos].cells_conected {
			neighbor_pos: vec3i = cell

			if neighbor_pos in closed_list {
				continue
			}

			// Unwalkable
			if world[neighbor_pos].walkable == false{
				continue
			}

			g_new: int = current_node.g + 1
			h_new: int = get_heuclidean(target_pos, neighbor_pos)	
			f_new: int = g_new + h_new	

			if neighbor_pos in open_list && open_list[neighbor_pos].g < g_new {
				continue
			}

			open_list[neighbor_pos] = {
				neighbor_pos,
				g_new, h_new, f_new,
				current_node.pos
			}
		}
	}

	fmt.println("No Path to Target")
	return {}
}

rebuild_path :: proc(source_pos, target_pos: vec3i, list: ^map[vec3i]node) -> [dynamic]vec3i {
	current_pos: vec3i = target_pos
	current_node: node

	path_temp: [dynamic]vec3i
	path: [dynamic]vec3i = {source_pos}

	for current_pos != source_pos {
		append(&path_temp, current_pos)

		current_pos = list[current_pos].prev
	}

	#reverse for pos in path_temp {
		append(&path, pos)
	}

	return path 
}

get_heuclidean :: proc(source, target: vec3i) -> int {
	return math.abs(source.x - target.x) + math.abs(source.z - target.z)
}

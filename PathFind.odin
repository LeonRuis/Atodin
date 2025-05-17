package Atalay

import fmt "core:fmt"
import math "core:math"

import rl "vendor:raylib"

path_world: map[vec3i]Path_Cell
valid_drink_cells: map[vec3i]bool

Path_Cell :: struct {
	pos: vec3i,
	is_walkable: bool,
	cells_connected: [dynamic]vec3i
}

Path_Node :: struct {
	pos: vec3i,
	g, h, f: i32, 
	previous_node: vec3i
}

neighbor_dirs: [8]vec3i = {
	N,
	S,
	E,
	W,
	N + E,
	N + W,
	S + E,
	S + W	
}

path_init :: proc() {
	for key_pos, terrain_cell in terrain_world {

		// Connect Cells
		connected_positions: [dynamic]vec3i

		if terrain_world[key_pos].color == rl.SKYBLUE {
			continue	
		}

		for dir in neighbor_dirs {
			neighbor_pos: vec3i = key_pos + dir

			// Position exists on Terrain
			if neighbor_pos not_in terrain_world {
				continue
			}

			// Neighbor is Water
			if terrain_world[neighbor_pos].color == rl.SKYBLUE {
				reacheable_water: Path_Cell = {
					pos = neighbor_pos,
					is_walkable = false,
					cells_connected = {}
				}

				append(&reacheable_water.cells_connected, key_pos)
				append(&connected_positions, neighbor_pos)

				valid_drink_cells[neighbor_pos] = true

				if neighbor_pos not_in path_world {
					path_world[neighbor_pos] = reacheable_water
				}
			}

			append(&connected_positions, neighbor_pos)
		}

		// Check if Walkable
		walkable: bool = true

		path_cell: Path_Cell = {
			pos = key_pos,
			is_walkable = walkable,
			cells_connected = connected_positions
		}

		path_world[key_pos]	= path_cell
	}
}

path :: proc(source, target: vec3i, adyacent: bool) -> [dynamic]vec3i {
	if target == source {
		return {}
	}
	
	open_list  : map[vec3i]Path_Node
	closed_list: map[vec3i]Path_Node

	starting_node: Path_Node = {
		source,
		0, 0, 0,
		source
	}

	current_node := starting_node

	open_list[source] = starting_node

	// Source and Target valid
	if source not_in path_world || target not_in path_world {
		return {}
	}

	// Path search
	for len(open_list) > 0 {

		// Pick first node in open list
		for key_pos, node in open_list {
			current_node = open_list[key_pos]
			break
		}

		// Pick node with least f in open list
		for key_pos, node in open_list {
			if node.f < current_node.f {
				current_node = node
			}
		}

		delete_key(&open_list, current_node.pos)
		closed_list[current_node.pos] = current_node

		// Node is Target
		if current_node.pos == target {
			return rebuild_path(source, target, &closed_list)
		}

		// Get Closest connected node to target
		for connected_pos in path_world[current_node.pos].cells_connected {
			if connected_pos == target && adyacent {
				closed_list[target] = {
                    pos = target,
                    g = current_node.g + 1,
                    h = 0,
                    f = current_node.g + 1,
                    previous_node = current_node.pos
                }
                
				return rebuild_path(source, connected_pos, &closed_list)
			}

			// Already Processed
			if connected_pos in closed_list {
				continue
			}

			// Unwalkable
			if !path_world[connected_pos].is_walkable {
				continue
			}

			g_new: i32 = current_node.g + 1
			h_new: i32 = get_heuristics(connected_pos, target)
			f_new: i32 = g_new + h_new

			if connected_pos in open_list && open_list[connected_pos].g < g_new {
				continue
			}

			open_list[connected_pos] = {
				connected_pos, 
				g_new, h_new, f_new,
				current_node.pos
			}
		}
	}

	// No Path
	return {}
}

rebuild_path :: proc(source, target: vec3i, list: ^map[vec3i]Path_Node) -> [dynamic]vec3i {
	current_pos: vec3i = target

	path_temp: [dynamic]vec3i
	path: [dynamic]vec3i

	for current_pos != source {
		append(&path_temp, current_pos)

		current_pos = list[current_pos].previous_node
	}

	append(&path_temp, source)

	#reverse for pos in path_temp {
		append(&path, pos)
	}

	return path
}

// Currently using: Manhattan Distance
get_heuristics :: proc(source, target: vec3i) -> i32 {
	return math.abs(source.x - target.x) + math.abs(source.z - target.z)
}
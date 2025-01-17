package Atalay

vec2i :: [2]int
vec3i :: [3]int

vec2 :: [2]f32
vec3 :: [3]f32

to_v3 :: proc(a: vec3i) -> vec3{
	return {f32(a.x), f32(a.y), f32(a.z)}
}

////----------------------------------------------

N :: vec3i{0, 0, -1}
S :: vec3i{0, 0, 1}
E :: vec3i{1, 0, 0}
W :: vec3i{-1, 0, 0}
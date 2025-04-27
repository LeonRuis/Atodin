package Atalay

import rl "vendor:raylib"

Light :: struct {
	type: i32,
	enabled: i32,
	position: vec3,
	target: vec3,
	color: rl.Color,

	enabledLoc: i32,
	typeLoc: i32,
	positionLoc: i32,
	targetLoc: i32,
	colorLoc: i32,
}

light_shader: rl.Shader
light: Light

init_lighting :: proc() {
	light_shader = rl.LoadShader("assets/lighting.vs", "assets/lighting.fs")
	light_shader.locs[rl.ShaderLocationIndex.VECTOR_VIEW] = rl.GetShaderLocation(shader, "viewPos")

	ambientLoc: i32 = rl.GetShaderLocation(light_shader, "ambient")
	ambient_color: [4]f32 = {0.1, 0.1, 0.1, 0.1} 
	rl.SetShaderValue(light_shader, ambientLoc, &ambient_color, .VEC4)

	init_light(&light)
}

init_light :: proc(light: ^Light) {
	light.type = 1
	light.enabled = 1 
	light.position = {15, 10, 16}
	light.target = {0, 0, 0}
	light.color = rl.ORANGE

	light.typeLoc = rl.GetShaderLocation(light_shader, "the_light.type")
	light.enabledLoc = rl.GetShaderLocation(light_shader, "the_light.enabled")
	light.positionLoc = rl.GetShaderLocation(light_shader, "the_light.position")
	light.targetLoc = rl.GetShaderLocation(light_shader, "the_light.target")
	light.colorLoc = rl.GetShaderLocation(light_shader, "the_light.color")

	update_light(light)
}

update_light :: proc(light: ^Light) {
	rl.SetShaderValue(light_shader, light.enabledLoc, &light.enabled, .INT)
	rl.SetShaderValue(light_shader, light.typeLoc, &light.type, .INT)

	rl.SetShaderValue(light_shader, light.positionLoc, &light.position, .VEC3)

	rl.SetShaderValue(light_shader, light.targetLoc, &light.target, .VEC3)

	color: [4]f32 = {f32(light.color.r), f32(light.color.g), 
		f32(light.color.b), f32(light.color.a)} / 255

	rl.SetShaderValue(light_shader, light.colorLoc, &color, .VEC4)
}
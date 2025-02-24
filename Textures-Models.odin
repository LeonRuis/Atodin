package Atalay

import rl "vendor:raylib"
import fmt "core:fmt"

GameModel :: struct {
	model: ^rl.Model,
	scale: f32,
	rot_axis: vec3,
	offset_pos: vec3
}

VisualInstance :: struct {
	game_model: ^GameModel,
	rot: f32,
}

Male_GameModel: GameModel = {
	model = &male_model,
	scale = 1,
	rot_axis = {0, 1, 0},
	offset_pos = {0, 0, 0}
}

Rat_Blue_GameModel: GameModel = {
	model = &rat_blue_model,
	scale = 0.5, 
	rot_axis = {0, 1, 0},
	offset_pos = {0, 0, 0}
}

Rat_Orange_GameModel: GameModel = {
	model = &rat_orange_model,
	scale = 0.5, 
	rot_axis = {0, 1, 0},
	offset_pos = {0, 0, 0}
}

Carrots_GameModel: GameModel = {
	model = &carrots_model,
	scale = 1,
	rot_axis = {0, 1, 0},
	offset_pos = {0.5, 0, 0.5}
}

Long_Grass_GameModel: GameModel = {
	model = &long_grass_model,
	scale = 0.5,
	rot_axis = {0, 1, 0},
	offset_pos = {0.5, 0, 0.5}
}

// Atlas
terrain_atlas_texture: rl.Texture

grass_model: rl.Model
sand_model: rl.Model
water_model: rl.Model
wall_model: rl.Model

// Individual
male_texture: rl.Texture
male_model: rl.Model

rat_blue_texture: rl.Texture
rat_blue_model: rl.Model

rat_orange_texture: rl.Texture 
rat_orange_model: rl.Model

carrots_texture: rl.Texture
carrots_model: rl.Model

long_grass_texture: rl.Texture
long_grass_model: rl.Model
shader: rl.Shader

load_textures_and_models :: proc() {
	// Atlas
	terrain_atlas_texture = rl.LoadTexture("assets/WorldAtlas.png")

	grass_model = rl.LoadModel("assets/Grass.obj")
	grass_model.materials[0].maps[0].texture = terrain_atlas_texture

	sand_model = rl.LoadModel("assets/Sand.obj")
	sand_model.materials[0].maps[0].texture = terrain_atlas_texture

	water_model = rl.LoadModel("assets/Water.obj")
	water_model.materials[0].maps[0].texture = terrain_atlas_texture

	wall_model = rl.LoadModel("assets/Log_Wall.obj")
	wall_model.materials[0].maps[0].texture = terrain_atlas_texture

	// Individual
	load_pair_texture_model(&male_texture, &male_model, "assets/Male_texture.png", "assets/Male_object.obj")
	load_pair_texture_model(&rat_blue_texture, &rat_blue_model, "assets/Rat_1.png", "assets/Rat.obj")
	load_pair_texture_model(&rat_orange_texture, &rat_orange_model, "assets/Rat_2.png", "assets/Rat.obj")
	load_pair_texture_model(&carrots_texture, &carrots_model, "assets/Carrots.png", "assets/Carrots.obj")

	load_pair_texture_model(&long_grass_texture, &long_grass_model, "assets/Long Grass.png", "assets/Long Grass.obj")
	shader = rl.LoadShader(nil, "assets/discard_alpha.fs")
	long_grass_model.materials[0].shader = shader
}

unload_textures_and_models :: proc() {
	// Atlas
	rl.UnloadTexture(terrain_atlas_texture)

	rl.UnloadModel(grass_model)
	rl.UnloadModel(sand_model)
	rl.UnloadModel(water_model)
	rl.UnloadModel(wall_model)

	// Individual
	unload_pair_texture_model(&male_texture, &male_model)
	unload_pair_texture_model(&rat_blue_texture, &rat_blue_model)
	unload_pair_texture_model(&rat_orange_texture, &rat_orange_model)
	unload_pair_texture_model(&carrots_texture, &carrots_model)
}

//-------------------------------------------- Tools -------------------------------------------------------

load_pair_texture_model :: proc(texture: ^rl.Texture, model: ^rl.Model, cstr_texture, cstr_model: cstring) {
	texture^ = rl.LoadTexture(cstr_texture)
	model^ = rl.LoadModel(cstr_model)
	model^.materials[0].maps[0].texture = texture^
}

unload_pair_texture_model :: proc(texture: ^rl.Texture, model: ^rl.Model) {
	rl.UnloadTexture(texture^)
	rl.UnloadModel(model^)
}

// -----------------------------------------------------------------------------------------------------
draw_visual_instance :: proc(visual_instance: ^VisualInstance, pos: vec3i) {
	rl.DrawModelEx(
		visual_instance.game_model.model^,
		to_v3(to_visual_world(pos)) + visual_instance.game_model.offset_pos,
		visual_instance.game_model.rot_axis,
		visual_instance.rot,
		visual_instance.game_model.scale,
		rl.WHITE
	)
}
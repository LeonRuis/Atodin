package Atalay

import rl "vendor:raylib"

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

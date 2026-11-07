@tool
class_name RoomMaterials
extends RefCounted
## Shared original PBR maps. Geometry UVs are in metres; scale is physical.

static var _cache: Dictionary = {}
static var _texture_cache: Dictionary = {}
const TEXTURE_ROOT := "res://assets/textures/pbr/"

static func get_mat(key: String) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.resource_name = key
	mat.roughness = 0.72
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	match key:
		"plaster":
			_pbr(mat, "plaster", .80, .55)
		"tile", "marble":
			_pbr(mat, "marble", 1.20, .20)
			mat.set_meta("uv_variation", true)
		"wood", "oak":
			_pbr(mat, "oak", .72, .45)
			mat.set_meta("uv_variation", true)
		"dark_wood":
			_pbr(mat, "oak", .72, .40)
			mat.albedo_color = Color("81736a")
			mat.set_meta("uv_variation", true)
		"granite":
			_pbr(mat, "granite", .60, .30)
		"brushed_metal", "stainless":
			_pbr(mat, "brushed_metal", .30, .35)
			mat.metallic = .80
		"metal":
			# Powder-coated stair frame, less reflective than unpainted steel.
			mat.albedo_color = Color("939b9c")
			mat.metallic = .22
			mat.roughness = .44
		"chrome":
			mat.albedo_color = Color("b7bec0")
			mat.metallic = .88
			mat.roughness = .22
		"dark":
			mat.albedo_color = Color("25282a")
			mat.roughness = .53
		"rubber":
			mat.albedo_color = Color("222526")
			mat.roughness = .89
		"fabric", "blue_fabric", "cream_fabric", "green_fabric":
			_pbr(mat, "fabric", .18, .70)
			match key:
				"blue_fabric": mat.albedo_color = Color("6c91a6")
				"cream_fabric": mat.albedo_color = Color("d9d3c4")
				"green_fabric": mat.albedo_color = Color("46544d")
				_: mat.albedo_color = Color("444a4c")
		"chair_mesh", "mesh_fabric":
			_pbr(mat, "chair_mesh", .10, .75)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			mat.alpha_scissor_threshold = .48
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		"green":
			mat.albedo_color = Color("739b32")
			mat.roughness = .25
		"stove_glass":
			mat.albedo_color = Color("171d1e")
			mat.roughness = .22
		"glass":
			_glass(mat, Color(.78, .89, .88, .11), .16)
		"frosted_glass":
			_glass(mat, Color(.80, .81, .73, .60), .58)
			mat.normal_enabled = true
			mat.normal_texture = _texture("plaster_normal")
			mat.normal_scale = .30
			mat.uv1_scale = Vector3.ONE / .24
		"water":
			_glass(mat, Color(.33, .56, .51, .20), .20)
		"ceramic":
			mat.albedo_color = Color("dfe2de")
			mat.roughness = .28
		"white":
			mat.albedo_color = Color("dedfd8")
			mat.roughness = .51
		"grout":
			mat.albedo_color = Color("aaa9a1")
			mat.roughness = .96
		"bath_tile", "bath_wall", "ivory_tile", "bath_wall_ivory":
			_pbr(mat, "bath_ivory", .60, .32)
			mat.set_meta("uv_variation", true)
		"bath_floor", "brown_tile", "bath_floor_brown":
			_pbr(mat, "bath_brown", .60, .55)
			mat.set_meta("uv_variation", true)
		"screen":
			mat.albedo_color = Color("1f3c42")
			mat.roughness = .36
			mat.emission_enabled = true
			mat.emission = Color("4e7c83")
			mat.emission_energy_multiplier = .38
		"screen_desktop":
			mat.albedo_texture = _texture("desktop_albedo")
			mat.emission_enabled = true
			mat.emission_texture = mat.albedo_texture
			mat.emission = Color.WHITE
			mat.emission_energy_multiplier = .48
			mat.roughness = .38
			mat.set_meta("uv_mode", "fit")
		"rgb":
			mat.albedo_color = Color("7188c7")
			mat.emission_enabled = true
			mat.emission = Color("5a6aba")
			mat.emission_energy_multiplier = 1.0
			mat.roughness = .35
		"leaf":
			mat.albedo_color = Color("4e7241")
			mat.roughness = .76
		"sand":
			_pbr(mat, "granite", .12, 1.0)
			mat.albedo_color = Color("d7cc9e")
			mat.albedo_texture = null
			mat.roughness_texture = null
			mat.roughness = .94
		"pink":
			mat.albedo_color = Color("ab7a83")
		"food":
			mat.albedo_color = Color("74543e")
			mat.roughness = .94
		"orange":
			mat.albedo_color = Color("b98344")
		"cream":
			mat.albedo_color = Color("d6cdb9")
		_:
			mat.albedo_color = Color(key) if key.begins_with("#") else Color("b8b7ae")
	_cache[key] = mat
	return mat

static func _pbr(mat: StandardMaterial3D, texture_name: String, repeat_m: float, normal_strength: float) -> void:
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = _texture(texture_name + "_albedo")
	mat.normal_enabled = true
	mat.normal_texture = _texture(texture_name + "_normal")
	mat.normal_scale = normal_strength
	mat.roughness = 1.0
	mat.roughness_texture = _texture(texture_name + "_roughness")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	if texture_name in ["oak", "fabric", "chair_mesh", "granite"]:
		mat.ao_enabled = true
		mat.ao_texture = _texture(texture_name + "_ao")
		mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		mat.ao_light_affect = 0.0
	mat.uv1_scale = Vector3.ONE / repeat_m
	# Metric UVs are baked into RoomGeo meshes. No triple texture sampling.
	mat.uv1_triplanar = false

static func _glass(mat: StandardMaterial3D, tint: Color, roughness: float) -> void:
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = roughness
	mat.metallic = 0.0
	# No screen-space refraction or opaque depth prepass for thin tank panes.

static func _texture(name: String) -> Texture2D:
	if not _texture_cache.has(name):
		_texture_cache[name] = load(TEXTURE_ROOT + name + ".png") as Texture2D
	return _texture_cache[name]

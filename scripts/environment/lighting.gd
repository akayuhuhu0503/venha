extends Node3D
## One owner for daylight and the three independent domestic light circuits.
var is_night := false
var circuits := {"main":false,"kitchen":false,"bathroom":false}
var circuit_lights: Dictionary = {}
var env: Environment
var exterior: DirectionalLight3D
var window_fill: OmniLight3D
var entry_fill: OmniLight3D
var loft_fill: OmniLight3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.name = "RoomEnvironment"
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("7195ae")
	sky_mat.sky_horizon_color = Color("cbd4d6")
	sky_mat.ground_bottom_color = Color("43494b")
	sky_mat.ground_horizon_color = Color("b5c0c3")
	sky.sky_material = sky_mat
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	world.environment = env
	add_child(world)
	exterior = DirectionalLight3D.new()
	exterior.name = "SunThroughNorthWindow"
	exterior.rotation_degrees = Vector3(-24,165,0)
	exterior.shadow_enabled = true
	exterior.directional_shadow_max_distance = 12
	exterior.shadow_bias = .025
	exterior.light_angular_distance = .8
	add_child(exterior)
	window_fill = _omni("WindowBounce",Vector3(3.02,1.82,-5.25),Color("d6e4e9"),3.2,.60,true)
	entry_fill = _omni("BalconyBounce",Vector3(.52,2.0,-5.20),Color("dae4e6"),4.0,.45,false)
	loft_fill = _omni("HighWallBounce",Vector3(1.0,3.5,-3.5),Color("e0e1d8"),4.1,.26,false)
	circuit_lights["main"] = _omni("MainTube",Vector3(.25,3.04,-2.8),Color("e5e8dd"),5.3,1.05,true)
	circuit_lights["kitchen"] = _omni("KitchenTube",Vector3(1.08,1.90,-.71),Color("f0dfbd"),2.2,.73,true)
	circuit_lights["bathroom"] = _omni("BathroomTube",Vector3(2.55,2.40,-2.36),Color("e5e9e5"),2.5,.85,true)
	_omni("MonitorOne",Vector3(3.36,1.15,-4.51),Color("94bdcb"),1.5,.16,false)
	_omni("MonitorTwo",Vector3(2.82,1.05,-3.36),Color("8eaebd"),1.3,.12,false)
	_omni("RGB",Vector3(3.00,.38,-5.04),Color("777bc7"),1.0,.16,false)
	_omni("Aquarium",Vector3(3.40,1.24,-4.99),Color("c5dbc5"),.78,.19,false)
	_omni("PCFairyLights",Vector3(2.4,1.96,-3.10),Color("718ac7"),1.8,.07,false)
	apply()

func _omni(label: String, pos: Vector3, color: Color, reach: float, energy: float, shadows: bool) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = label
	light.position = pos
	light.light_color = color
	light.omni_range = reach
	light.omni_attenuation = 1.25
	light.light_energy = energy
	light.shadow_enabled = shadows
	light.shadow_bias = .025
	light.light_size = .12
	add_child(light)
	return light

func toggle_day() -> void:
	is_night = not is_night
	apply()

func toggle_circuit(key: String) -> void:
	if circuits.has(key):
		circuits[key] = not circuits[key]
		apply()

func apply() -> void:
	env.background_energy_multiplier = .12 if is_night else .75
	env.ambient_light_color = Color("798596") if is_night else Color("d9dfdf")
	env.ambient_light_energy = .13 if is_night else .36
	exterior.light_color = Color("9db1c8") if is_night else Color("f1ead9")
	exterior.light_energy = .025 if is_night else .80
	window_fill.light_energy = .035 if is_night else .60
	entry_fill.light_energy = .035 if is_night else .45
	loft_fill.light_energy = .025 if is_night else .26
	for key in circuit_lights:
		circuit_lights[key].visible = circuits[key]

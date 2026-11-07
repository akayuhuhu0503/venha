extends SceneTree
## Essential v0.5 checks; no images or benchmarks. Prior smoke is in .history/before_room_v05.zip.
## Godot --headless --path . --fixed-fps 60 --script res://tests/technical_smoke.gd
var failures: int = 0
var checks: int = 0
var game: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var last_walk_contacts: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main := load("res://scenes/main.tscn") as PackedScene
	if main == null:
		push_error("FAIL main scene cannot load")
		quit(1)
		return
	game = main.instantiate() as Node3D
	root.add_child(game)
	current_scene = game
	player = game.get_node("Player") as CharacterBody3D
	ui = game.get_node("UI") as CanvasLayer
	await _ticks(24)
	_check("main scene spawn has floor support", player.is_on_floor() and absf(player.global_position.y) < .03, player.global_position)
	var stationary := player.global_position
	await _ticks(24)
	_check("idle does not drift", player.global_position.distance_to(stationary) < .003, player.global_position)
	_check_layout()
	# Entrance -> corridor -> PC -> stair approach uses only real movement.
	var route_ok := true
	for point: Vector3 in [Vector3(.65,0,-.55), Vector3(.65,0,-1.90), Vector3(.75,0,-2.20), Vector3(.75,0,-4.37), Vector3(2.30,0,-4.37)]:
		var reached: bool = await _walk_to(point)
		route_ok = reached and route_ok
		if not reached:
			break
	_check("natural entrance corridor to PC area", route_ok and absf(player.global_position.y) < .04, [player.global_position, last_walk_contacts])
	await _check_modals()
	if route_ok:
		for point: Vector3 in [Vector3(.75,0,-4.37), Vector3(.30,0,-4.37), Vector3(.30,0,-4.82)]:
			var reached: bool = await _walk_to(point)
			route_ok = reached and route_ok
			if not reached:
				break
	_check("natural PC area to stair approach", route_ok and player.global_position.y < .10, [player.global_position, last_walk_contacts])
	var ascent := false
	if not route_ok:
		await _place(Vector3(.35,.04,-4.82))
	ascent = await _walk_to(Vector3(1.79,0,-5.06), 300)
	_check("continuous narrow stair ascent", ascent and absf(player.global_position.y - 2.2805) < .08, [player.global_position, last_walk_contacts])
	var onto_loft := false
	if ascent:
		onto_loft = await _walk_to(Vector3(1.79,0,-4.35))
	_check("top landing turns onto loft with head clearance", onto_loft and absf(player.global_position.y - 2.2805) < .08, [player.global_position, last_walk_contacts])
	if onto_loft:
		player.rotation = Vector3.ZERO
		await _walk("move_left",35)
		_check("loft rail prevents fall",player.global_position.x > 1.74 and absf(player.global_position.y-2.2805)<.08,[player.global_position,last_walk_contacts])
		var landing: bool = await _walk_to(Vector3(1.79,0,-5.06))
		var descended := false
		if landing:
			descended = await _walk_to(Vector3(.35,0,-4.82),300)
		_check("continuous stair descent",descended and player.global_position.y<.08 and player.is_on_floor(),[player.global_position,last_walk_contacts])
	else:
		_check("loft rail and stair descent reachable",false,"ascent/landing failed")
	# Independent fixture checks reset only their own starting position.
	await _place(Vector3(.65,.04,-.45))
	await _walk("move_back",40)
	_check("room wall blocks capsule",player.global_position.z < -.21 and player.global_position.z > -.27,[player.global_position,last_walk_contacts])
	await _place(Vector3(.85,.04,-3.20))
	await _walk("move_left",40)
	_check("wardrobe blocks capsule",player.global_position.x>.60 and player.global_position.x<.75,[player.global_position,last_walk_contacts])
	await _place(Vector3(1.45,.04,-4.35))
	Input.action_press("crouch")
	await _ticks(8)
	var entered: bool = await _walk_to(Vector3(1.45,0,-4.97))
	Input.action_release("crouch")
	await _ticks(10)
	var blocked_stand: bool = bool(player.get("is_crouching")) and not bool(player.call("can_stand"))
	var under_stair := player.global_position
	var escaped: bool = await _walk_to(Vector3(1.45,0,-4.35))
	_check("crouch prevents standing into ramp and recovers",entered and escaped and blocked_stand and not bool(player.get("is_crouching")),[under_stair,player.global_position,last_walk_contacts])
	await _place(Vector3(.75,.04,-3.80))
	await _check_door("EntryDoor",Vector3(.20,1.0,-.53),Vector3(-.55,1.0,-.53))
	await _check_door("BathroomDoor",Vector3(1.10,1.0,-2.37),Vector3(1.85,1.0,-2.37))
	print("TECHNICAL_SMOKE: %d/%d PASS; %d FAIL" % [checks-failures,checks,failures])
	game.queue_free()
	await process_frame
	quit(1 if failures>0 else 0)

func _check_layout() -> void:
	var room := game.get_node("Room") as Node3D
	var hall := _bounds("HallFloor")
	var entry := _bounds("EntranceFloor")
	var pc := _bounds("PCFloor")
	var bath := _bounds("BathFloor")
	var footprint_ok := absf(pc.end.x-hall.position.x-3.75)<.001 and absf(hall.size.x-1.54)<.001 and absf(hall.position.x-entry.position.x-.47)<.001 and absf(bath.position.x-1.54)<.001
	_check("measured L outline and WC remain outside corridor",footprint_ok and room.global_basis.is_equal_approx(Basis.IDENTITY),[entry,hall,pc,bath])
	var wardrobe := room.get_node("Wardrobe") as Node3D
	var fridge := room.get_node("Fridge") as Node3D
	var primary := room.get_node("Computer01") as Node3D
	var secondary := room.get_node("Computer02") as Node3D
	var pair := fridge.global_position-wardrobe.global_position
	var pc1_forward := -primary.global_basis.z
	var pc2_forward := -secondary.global_basis.z
	_check("photo directions and perpendicular PCs are not mirrored",pair.dot(Vector3.RIGHT)>0 and pair.dot(Basis(Vector3.UP,PI).x)<0 and pc1_forward.dot(Vector3.RIGHT)>.999 and pc2_forward.dot(Vector3.BACK)>.999,[pc1_forward,pc2_forward])
	var packed := load("res://assets/layout/room_v4/7150_PHONG_TRO_LAYOUT_v4.glb") as PackedScene
	var imported := packed.instantiate() as Node3D
	root.add_child(imported)
	var kitchen := imported.find_child("000_kitchen",true,false) as Node3D
	_check("GLB imports Y-up without a second rotation",kitchen!=null and kitchen.global_position.distance_to(Vector3(1.2278,.44,-.7078))<.00001 and imported.transform.is_equal_approx(Transform3D.IDENTITY),kitchen.global_position if kitchen!=null else null)
	imported.queue_free()

func _check_modals() -> void:
	var camera := player.get("camera") as Camera3D
	var before_pose := player.global_transform
	var before_camera := camera.transform
	ui.call("open_pc","Máy tính của tôi",player)
	await _walk("move_back",20)
	var locked: bool = not bool(player.get("controls_enabled")) and player.global_transform.is_equal_approx(before_pose)
	await _escape()
	_check("PC Esc restores pose camera and controls",locked and bool(player.get("controls_enabled")) and player.global_transform.is_equal_approx(before_pose) and camera.transform.is_equal_approx(before_camera) and str(ui.get("modal_kind")).is_empty(),Input.mouse_mode)
	await _escape()
	var paused_ok: bool = paused and str(ui.get("modal_kind"))=="pause"
	await _escape()
	_check("pause Esc restores controls",paused_ok and not paused and bool(player.get("controls_enabled")),str(ui.get("modal_kind")))
	var aquarium := game.get_node("Room/Aquarium/TankInteraction") as Node3D
	ui.call("open_aquarium",aquarium,player)
	await _ticks(30)
	var observed := camera.global_position.distance_to(aquarium.get_meta("focus_point") as Vector3)<.03
	await _escape()
	_check("aquarium returns camera and controls",observed and camera.transform.is_equal_approx(before_camera) and bool(player.get("controls_enabled")),camera.position)

func _check_door(name: String, from: Vector3, to: Vector3) -> void:
	var door := game.get_node("Room/Architecture/"+name) as Node3D
	var closed_hit := _ray(from,to)
	var opened := bool(door.call("try_toggle",player))
	await _ticks(3)
	var open_hit := _ray(from,to)
	var closed_again := bool(door.call("try_toggle",player))
	await _ticks(3)
	var restored_hit := _ray(from,to)
	_check(name+" collider follows open close",opened and closed_again and not closed_hit.is_empty() and open_hit.is_empty() and not restored_hit.is_empty(),[closed_hit.size(),open_hit.size(),restored_hit.size()])

func _bounds(name: String) -> AABB:
	var mesh := game.get_node("Room/Architecture/"+name) as MeshInstance3D
	return mesh.global_transform * mesh.mesh.get_aabb()

func _check(label: String, passed: bool, detail: Variant=null) -> void:
	checks += 1
	if not passed:
		failures += 1
	print(("PASS " if passed else "FAIL ")+label+" | "+str(detail))

func _ticks(count: int) -> void:
	for _i in count:
		await physics_frame

func _walk_to(point: Vector3, max_ticks: int=240) -> bool:
	var stagnant := 0
	var previous := player.global_position
	var encountered: Array[String] = []
	Input.action_press("move_forward")
	for _i in max_ticks:
		var direction := point-player.global_position
		player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
		await physics_frame
		for contact: String in _contacts():
			if not encountered.has(contact):
				encountered.append(contact)
		var delta := Vector2(player.global_position.x-point.x,player.global_position.z-point.z)
		if delta.length()<.035:
			break
		if player.global_position.distance_to(previous)<.0005:
			stagnant += 1
		else:
			stagnant = 0
		if stagnant>24:
			break
		previous = player.global_position
	last_walk_contacts = encountered
	Input.action_release("move_forward")
	await _ticks(2)
	return Vector2(player.global_position.x-point.x,player.global_position.z-point.z).length()<.065

func _walk(action: String, ticks: int) -> void:
	Input.action_press(action)
	await _ticks(ticks)
	last_walk_contacts = _contacts()
	Input.action_release(action)
	await _ticks(2)

func _place(location: Vector3) -> void:
	for action in ["move_left","move_right","move_forward","move_back","crouch","sprint"]:
		Input.action_release(action)
	player.global_position = location
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	await _ticks(18)

func _escape() -> void:
	var press := InputEventAction.new()
	press.action="pause"
	press.pressed=true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action="pause"
	release.pressed=false
	Input.parse_input_event(release)
	await process_frame

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to,3,[player.get_rid()])
	return player.get_world_3d().direct_space_state.intersect_ray(query)

func _contacts() -> Array[String]:
	var paths: Array[String]=[]
	for i in player.get_slide_collision_count():
		var collider := player.get_slide_collision(i).get_collider() as Node
		if collider!=null:
			paths.append(str(collider.get_path()))
	return paths

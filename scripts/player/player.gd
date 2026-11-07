extends CharacterBody3D
class_name RoomPlayer

signal footstep(surface: String, location: Vector3)

@export var walk_speed: float = 2.0
@export var run_speed: float = 3.2
@export var mouse_sensitivity: float = 0.0022
@export var interaction_distance: float = 2.5

const STANDING_HEIGHT: float = 1.70
const CROUCH_HEIGHT: float = 1.05
const BODY_RADIUS: float = 0.22
const STANDING_EYE: float = 1.57
const CROUCH_EYE: float = 0.93
const STEP_HEIGHT: float = .26

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var body_shape: CollisionShape3D = $CollisionShape3D
var controls_enabled: bool = true
var is_crouching: bool = false
var target: Node = null
var _stand_probe: CapsuleShape3D
var _step_distance: float = 0.0
var _gravity: float = 9.8

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.30
	floor_stop_on_slope = true
	floor_constant_speed = true
	safe_margin = 0.002
	collision_layer = 4
	collision_mask = 3
	_stand_probe = CapsuleShape3D.new()
	_stand_probe.radius = BODY_RADIUS
	_stand_probe.height = STANDING_HEIGHT
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ensure_input_actions() -> void:
	# Keep this modular player scene runnable on its own without overwriting settings.
	var bindings: Dictionary = {
		"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
		"sprint": KEY_SHIFT, "crouch": KEY_CTRL, "interact": KEY_E, "pause": KEY_ESCAPE,
	}
	for action_name: String in bindings:
		if InputMap.has_action(action_name):
			continue
		InputMap.add_action(action_name)
		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = int(bindings[action_name])
		InputMap.action_add_event(action_name, key_event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var ui: Node = _ui()
		if ui != null:
			ui.call("toggle_pause", self)
		get_viewport().set_input_as_handled()
		return
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensitivity, -1.45, 1.45)
	if event.is_action_pressed("interact") and is_instance_valid(target):
		target.call("interact", self)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector3.ZERO
		return
	_update_crouch(delta)
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	var speed: float = walk_speed
	var stair_zone := global_position.x > .25 and global_position.x < 2.03 and global_position.z < -4.52 and global_position.z > -5.42
	# V4 has a steep compact stair. Normal walking surfaces retain their normal limit.
	floor_max_angle = deg_to_rad(70.0 if stair_zone else 50.0)
	if is_crouching:
		speed = 1.25
	elif Input.is_action_pressed("sprint"):
		speed = run_speed
	if stair_zone:
		speed = minf(speed,1.45)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	var before: Vector3 = global_position
	move_and_slide()
	var wanted_travel := Vector3(direction.x,0,direction.z)*speed*delta
	var actual_travel := Vector2(global_position.x-before.x,global_position.z-before.z).length()
	if is_on_floor() and wanted_travel.length() > .001 and actual_travel < wanted_travel.length()*.30:
		_try_low_step(wanted_travel)
	if is_on_floor():
		var travel: Vector3 = global_position - before
		_step_distance += Vector2(travel.x, travel.z).length()
		if _step_distance > (0.74 if Input.is_action_pressed("sprint") else 0.57):
			_step_distance = 0.0
			var on_stairs: bool = global_position.y > 0.08 and stair_zone
			footstep.emit("wood" if global_position.y > 1.95 or on_stairs else "tile", global_position)
	_update_interaction()

func _try_low_step(motion: Vector3) -> void:
	# A short, collision-tested step over low domestic props; never over furniture.
	# Only invoked after movement stalls, so normal ramps retain move_and_slide.
	var low_obstacle := false
	for i in get_slide_collision_count():
		var object := get_slide_collision(i).get_collider() as Node
		if object != null and object.is_in_group("low_step"):
			low_obstacle = true
	if not low_obstacle:
		return
	# A support probe must reach beyond the rounded capsule toe at a low edge.
	motion = motion.normalized()*maxf(motion.length(),.12)
	var lifted := global_transform
	if test_move(lifted,Vector3.UP*STEP_HEIGHT):
		return
	lifted.origin.y += STEP_HEIGHT
	if test_move(lifted,motion):
		return
	lifted.origin += motion
	var landing := KinematicCollision3D.new()
	if not test_move(lifted,Vector3.DOWN*(STEP_HEIGHT+.025),landing):
		return
	if landing.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return
	var settled := lifted.origin+landing.get_travel()
	var rise := settled.y-global_position.y
	if rise < .006 or rise > STEP_HEIGHT+.002:
		return
	global_position = settled
	head.position.y -= rise
	velocity.y = 0
	apply_floor_snap()

func _update_crouch(delta: float) -> void:
	var wants_crouch: bool = Input.is_action_pressed("crouch")
	if not wants_crouch and is_crouching:
		wants_crouch = not can_stand()
	if wants_crouch != is_crouching:
		is_crouching = wants_crouch
		var capsule: CapsuleShape3D = body_shape.shape as CapsuleShape3D
		capsule.height = CROUCH_HEIGHT if is_crouching else STANDING_HEIGHT
		body_shape.position.y = capsule.height * 0.5
	var desired_eye: float = CROUCH_EYE if is_crouching else STANDING_EYE
	head.position.y = lerpf(head.position.y, desired_eye, 1.0 - exp(-14.0 * delta))

func can_stand() -> bool:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = _stand_probe
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, STANDING_HEIGHT * 0.5 + 0.025, 0.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.001
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _update_interaction() -> void:
	target = null
	var start: Vector3 = camera.global_position
	var finish: Vector3 = start - camera.global_transform.basis.z * interaction_distance
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, finish, 3, [get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var candidate: Node = hit.get("collider") as Node
		if candidate != null and candidate.has_method("interact") and candidate.has_method("get_prompt"):
			target = candidate
	var ui: Node = _ui()
	if ui != null:
		ui.call("set_prompt", str(target.call("get_prompt")) if target != null else "")

func set_control_enabled(value: bool) -> void:
	controls_enabled = value
	velocity = Vector3.ZERO
	target = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	if not value:
		var ui: Node = _ui()
		if ui != null:
			ui.call("set_prompt", "")

func _ui() -> Node:
	var game: Node = get_tree().get_first_node_in_group("game")
	if game == null:
		return null
	return game.get("ui") as Node

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and controls_enabled and is_node_ready():
		var ui: Node = _ui()
		if ui != null:
			ui.call("toggle_pause", self)

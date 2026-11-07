@tool
extends Node3D
## Safe discrete hinge motion: refuse to swing through the player's capsule.
const G = preload("res://scripts/geometry.gd")
const M = preload("res://scripts/materials.gd")
const Interaction = preload("res://scripts/interaction/interactable.gd")
@export var door_width := 0.9
@export var door_height := 2.1
@export var open_angle := 90.0
@export var door_title := "Cửa"
@export var is_bathroom := false
@export_enum("wood", "bath", "balcony") var door_style := "wood"
var is_open := false
var hinge: Node3D

func _ready() -> void:
	is_bathroom = door_style == "bath" or is_bathroom
	for xx in [-0.035,door_width+0.035]:
		G.box(self,"Frame",Vector3(xx,door_height/2,0),Vector3(0.055,door_height+0.09,0.11),M.get_mat("dark"),true)
	G.box(self,"Header",Vector3(door_width/2,door_height+0.035,0),Vector3(door_width+0.12,0.07,0.11),M.get_mat("dark"),true)
	hinge = Node3D.new()
	hinge.name = "Hinge"
	add_child(hinge)
	var body = Interaction.new()
	body.name = "DoorLeaf"
	body.action = "door"
	body.title = door_title
	body.set_meta("door_root",self)
	hinge.add_child(body)
	if is_bathroom or door_style == "balcony":
		for xx in [.045,door_width-.045]:
			G.bevel_box(body,"LeafStile",Vector3(xx,door_height/2,0),Vector3(.065,door_height-.025,.045),M.get_mat("dark"),.004)
		for yy in [.04,door_height-.04]:
			G.bevel_box(body,"LeafRail",Vector3(door_width/2,yy,0),Vector3(door_width-.03,.065,.045),M.get_mat("dark"),.004)
		G.box(body,"GlazedPanel",Vector3(door_width/2,door_height/2,0),Vector3(door_width-.13,door_height-.15,.012),M.get_mat("frosted_glass" if is_bathroom else "glass"),false)
		if is_bathroom:
			var rim := G.torus(body,"RoundWindowRim",Vector3(door_width/2,1.50,.018),.135,.149,M.get_mat("metal"))
			rim.rotation.x = PI/2
	else:
		G.bevel_box(body,"Leaf",Vector3(door_width/2,door_height/2,0),Vector3(door_width-.025,door_height-.025,.045),M.get_mat("dark_wood"),.004)
		for yy in [0.55,1.55]:
			for side in [-1.0,1.0]:
				G.bevel_box(body,"DoorInset",Vector3(door_width/2,yy,.026*side),Vector3(door_width-.19,.65,.012),M.get_mat("dark_wood"),.008)
	for zz in [-0.075,0.075]:
		G.box(body,"Handle",Vector3(door_width-0.16,1.02,zz),Vector3(0.17,0.028,0.028),M.get_mat("dark"),false)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(door_width-0.02,door_height-0.02,0.065)
	col.position = Vector3(door_width/2,door_height/2,0)
	col.shape = shape
	body.add_child(col)

func try_toggle(player: CharacterBody3D) -> bool:
	# Test the swept leaf, not a full circle that would reject narrow WC approaches.
	var query := PhysicsShapeQueryParameters3D.new()
	var leaf := BoxShape3D.new()
	leaf.size = Vector3(door_width-.02,door_height-.02,.075)
	query.shape = leaf
	query.collision_mask = player.collision_layer
	query.margin = .015
	var start := hinge.rotation.y
	var finish := 0.0 if is_open else deg_to_rad(open_angle)
	for i in range(19):
		var rotation_basis := Basis(Vector3.UP,lerpf(start,finish,float(i)/18))
		query.transform = global_transform * Transform3D(rotation_basis,rotation_basis * Vector3(door_width/2,door_height/2,0))
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			return false
	is_open = not is_open
	hinge.rotation.y = deg_to_rad(open_angle) if is_open else 0.0
	return true

@tool
extends Node3D
## Measured L footprint. No architecture is inferred from old sample photos.
const G = preload("res://scripts/geometry.gd")
const M = preload("res://scripts/materials.gd")
const Door = preload("res://scripts/environment/door.gd")
const Interaction = preload("res://scripts/interaction/interactable.gd")
@export var layout: RoomLayoutV4
var loft_height: float:
	get: return layout.loft_surface
var ceiling_height: float:
	get: return layout.ceiling_height

func _ready() -> void:
	if layout == null:
		layout = preload("res://scenes/room/layout_v4.tres")
	layout.read_source()
	var structure := Node3D.new()
	structure.name = "Architecture"
	add_child(structure)
	_shell(structure)
	_stairs(structure)
	_details(structure)
	if has_node("Bedding"):
		$Bedding.position.y = loft_height
	if has_node("BathroomFittings"):
		$BathroomFittings.scale = Vector3(layout.bathroom_depth/2.21,1,layout.bathroom_width/1.18)
	for path in ["BongBowls/BowlInteraction","BongBed/CatBedCollision","Bedding/BedInteraction"]:
		if has_node(path):
			get_node(path).add_to_group("low_step")

func _box(p: Node3D, label: String, pos: Vector3, size: Vector3, mat: String, solid := true) -> MeshInstance3D:
	var mesh := G.box(p,label,pos,size,M.get_mat(mat),solid)
	if solid and mat != "glass":
		var occluder := OccluderInstance3D.new()
		var volume := BoxOccluder3D.new()
		volume.size = size * .995
		occluder.occluder = volume
		mesh.add_child(occluder)
	return mesh

func _floor_rect(p: Node3D, label: String, x0: float, x1: float, y0: float, y1: float, top: float, mat: String, thick := .10) -> void:
	_box(p,label,Vector3((x0+x1)/2,top-thick/2,-(y0+y1)/2),Vector3(x1-x0,thick,y1-y0),mat)

func _wall_x(p: Node3D, label: String, x: float, y0: float, y1: float, height: float, mat := "plaster", base := 0.0) -> void:
	_box(p,label,Vector3(x,base+height/2,-(y0+y1)/2),Vector3(.10,height,y1-y0),mat)

func _wall_y(p: Node3D, label: String, y: float, x0: float, x1: float, height: float, mat := "plaster", base := 0.0) -> void:
	_box(p,label,Vector3((x0+x1)/2,base+height/2,-y),Vector3(x1-x0,height,.10),mat)

func _shell(p: Node3D) -> void:
	var h := ceiling_height
	_floor_rect(p,"EntranceFloor",-.47,1.54,0,1.25,0,"tile")
	_floor_rect(p,"HallFloor",0,1.54,1.25,5.435,0,"tile")
	_floor_rect(p,"PCFloor",1.54,3.75,2.955,5.435,0,"tile")
	# Wall inner faces preserve corridor and measured entrance clearance.
	_wall_y(p,"EntryBottom",-.05,-.57,1.64,h)
	_wall_x(p,"EntryLeftBottom",-.52,0,.145,h)
	_wall_x(p,"EntryLeftTop",-.52,.915,1.30,h)
	_wall_x(p,"EntryHeader",-.52,.145,.915,h-2.10,"plaster",2.10)
	_wall_y(p,"EntryInset",1.30,-.57,-.05,h)
	_wall_x(p,"HallLeft",-.05,1.25,5.535,h)
	_wall_x(p,"KitchenRight",1.59,0,1.90,h)
	_wall_x(p,"BathDoorLowerPier",1.59,1.90,2.02,h)
	_wall_x(p,"BathDoorUpperPier",1.59,2.72,2.955,h)
	_wall_x(p,"BathDoorHeader",1.59,2.02,2.72,h-2.11,"plaster",2.11)
	_wall_y(p,"PCSouth",2.905,1.54,3.85,h)
	_wall_x(p,"PCEast",3.80,2.955,5.535,h)
	_wall_y(p,"NorthLeft",5.485,-.05,.14,h)
	_wall_y(p,"NorthCenter",5.485,.90,2.565,h)
	_wall_y(p,"NorthRight",5.485,3.475,3.85,h)
	_wall_y(p,"BalconyHeader",5.485,.14,.90,h-2.30,"plaster",2.30)
	_wall_y(p,"WindowSill",5.485,2.565,3.475,1.11)
	_wall_y(p,"WindowHeader",5.485,2.565,3.475,h-2.19,"plaster",2.19)
	_floor_rect(p,"CeilingEntry",-.47,1.54,0,1.25,h+.12,"plaster",.12)
	_floor_rect(p,"CeilingHall",0,1.54,1.25,5.435,h+.12,"plaster",.12)
	_floor_rect(p,"CeilingPC",1.54,3.75,2.955,5.435,h+.12,"plaster",.12)
	# WC annex remains entirely to the right of x=1.54. Width is provisional.
	var bx := 1.54+layout.bathroom_depth
	var by := 2.955-layout.bathroom_width
	_floor_rect(p,"BathFloor",1.54,bx,by,2.955,0,"bath_floor")
	_wall_x(p,"BathEast",bx+.05,by,2.955,2.62,"bath_wall")
	_wall_y(p,"BathSouth",by-.05,1.64,bx+.10,2.62,"bath_wall")
	# Thin tile facing avoids changing the actual WC partition footprint.
	_box(p,"BathNorthBrown",Vector3((1.64+bx)/2,.55,-2.851),Vector3(bx-1.64,1.10,.008),"bath_floor",false)
	_box(p,"BathNorthIvory",Vector3((1.64+bx)/2,1.86,-2.851),Vector3(bx-1.64,1.52,.008),"bath_wall",false)
	_box(p,"BathEastBrown",Vector3(bx-.004,.55,-(by+2.955)/2),Vector3(.008,1.10,2.955-by),"bath_floor",false)
	_box(p,"BathSouthBrown",Vector3((1.64+bx)/2,.55,-by-.004),Vector3(bx-1.64,1.10,.008),"bath_floor",false)
	_floor_rect(p,"BathCeiling",1.64,bx,by,2.955,2.72,"plaster")
	# Stair opening removes the intersecting blockout slab at the landing.
	_floor_rect(p,"LoftFloorFront",1.5175,3.7291,2.955,4.60,loft_height,"wood",.1905)
	_floor_rect(p,"LoftFloorBack",2.02,3.7291,4.60,5.435,loft_height,"wood",.1905)
	_floor_rect(p,"LoftLandingTurn",1.76,2.02,4.60,4.80,loft_height,"wood",.1905)
	_floor_rect(p,"LoftLandingRear",1.76,2.02,5.32,5.435,loft_height,"wood",.1905)
	_box(p,"LoftSoffitFront",Vector3(2.6233,loft_height-.192,-3.7775),Vector3(2.2116,.009,1.645),"white",false)
	_box(p,"LoftSoffitBack",Vector3(2.87455,loft_height-.192,-5.0175),Vector3(1.7091,.009,.835),"white",false)
	_box(p,"LoftFasciaLeft",Vector3(1.5375,loft_height-.10,-3.7775),Vector3(.04,.20,1.645),"metal",false)
	_box(p,"LoftFasciaFront",Vector3(2.6233,loft_height-.10,-2.98),Vector3(2.2116,.20,.045),"metal",false)
	_floor_rect(p,"BalconyThreshold",.05,.96,5.435,5.935,0,"tile")
	_rail(p,"BalconyGuard",Vector3(.05,0,-5.935),Vector3(.96,0,-5.935),1.05)
	_rail(p,"BalconySideLeft",Vector3(.05,0,-5.435),Vector3(.05,0,-5.935),1.05)
	_rail(p,"BalconySideRight",Vector3(.96,0,-5.435),Vector3(.96,0,-5.935),1.05)
	# No exterior level has been supplied beyond the main door.
	G.collider(p,"MainThresholdBoundary",Vector3(-.59,1.1,-.53),Vector3(.05,2.2,.82))
	_door(p,"EntryDoor",Vector3(-.47,0,-.145),PI/2,.77,2.10,-90,"Cửa chính","wood")
	_door(p,"BathroomDoor",Vector3(1.59,0,-2.72),-PI/2,.70,2.11,90,"Cửa nhà vệ sinh","bath")
	_door(p,"BalconyDoor",Vector3(.14,0,-5.435),0,.76,2.30,-90,"Cửa ban công","balcony")
	_tile_joints(p)

func _door(p: Node3D, label: String, pos: Vector3, yaw: float, width: float, height: float, angle: float, title: String, style: String) -> void:
	var door := Door.new()
	door.name = label
	door.position = pos
	door.rotation.y = yaw
	door.door_width = width
	door.door_height = height
	door.open_angle = angle
	door.door_title = title
	door.door_style = style
	p.add_child(door)

func _tile_joints(p: Node3D) -> void:
	for rect: Rect2 in [Rect2(-.47,0,2.01,1.25),Rect2(0,1.25,1.54,4.185),Rect2(1.54,2.955,2.21,2.48)]:
		var x := ceilf(rect.position.x/.6)*.6
		while x < rect.end.x:
			_box(p,"FloorGroutX",Vector3(x,.001,-rect.get_center().y),Vector3(.002,.001,rect.size.y),"grout",false)
			x += .6
		var y := ceilf(rect.position.y/.6)*.6
		while y < rect.end.y:
			_box(p,"FloorGroutY",Vector3(rect.get_center().x,.001,-y),Vector3(rect.size.x,.001,.002),"grout",false)
			y += .6

func _stairs(p: Node3D) -> void:
	var stair := Node3D.new()
	stair.name = "Stairs"
	p.add_child(stair)
	for part: Dictionary in layout.source.get("parts",[]):
		if part.get("group") == "stairs" and part.get("kind") == "box" and str(part.name).contains("Bậc"):
			var c: Array = part.center
			var s: Array = part.size
			G.bevel_box(stair,"OakTread",Vector3(c[0],c[2],-float(c[1])),Vector3(s[0],s[2],s[1]),M.get_mat("wood"),.006,false)
	var a := Vector3(.59,0,-4.86)
	var b := Vector3(1.79,loft_height,-5.06)
	var landing_end := Vector3(2.02,loft_height,-5.06)
	var across := Vector3(.1644,0,.9864)*.2579
	var ramp := StaticBody3D.new()
	ramp.name = "ContinuousStairCollision"
	ramp.add_to_group("stairs")
	stair.add_child(ramp)
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for side in [-1.0,1.0]:
		for v in [a+across*side,b+across*side,landing_end+across*side]:
			points.append(v)
			points.append(v-Vector3.UP*.075)
	shape.points = points
	var col := CollisionShape3D.new()
	col.shape = shape
	ramp.add_child(col)
	G.bevel_box(stair,"LandingDeck",Vector3(1.905,loft_height-.024,-5.06),Vector3(.23,.048,.5158),M.get_mat("wood"),.004,false)
	# Two short top treads resolve the source's missing final .32m rise.
	for i in range(2):
		var t := float(i+1)/2
		G.bevel_box(stair,"TopConnectionTread",Vector3(1.63+.14*t,1.959+(loft_height-1.959)*t-.024,-5.05),Vector3(.14,.048,.5158),M.get_mat("wood"),.005,false)
	for side in [-1.0,1.0]:
		var s0: Vector3 = a+across*side
		var s1: Vector3 = b+across*side
		G.rod(stair,"SteelStringer",s0+Vector3.UP*.07,s1-Vector3.UP*.10,.026,M.get_mat("metal"))
		if side > 0:
			s1 = s0.lerp(s1,.75)
		G.rod(stair,"SteelHandrail",s0+Vector3.UP*.72,s1+Vector3.UP*.70,.018,M.get_mat("metal"))
		for i in range(5):
			var base: Vector3 = s0.lerp(s1,float(i)/4)
			G.rod(stair,"RailUpright",base,base+Vector3.UP*.70,.012,M.get_mat("metal"))
		var rail := StaticBody3D.new()
		rail.name = "StairSideGuard"
		stair.add_child(rail)
		var hull := ConvexPolygonShape3D.new()
		var ps := PackedVector3Array()
		for d in [0.0,.018*side]:
			for v in [s0,s1,s0+Vector3.UP*.74,s1+Vector3.UP*.74]:
				ps.append(v+across.normalized()*d)
		hull.points = ps
		var rail_col := CollisionShape3D.new()
		rail_col.shape = hull
		rail.add_child(rail_col)
	_rail(p,"LoftLeftRail",Vector3(1.54,loft_height,-2.99),Vector3(1.54,loft_height,-4.58),.86)
	_rail(p,"LoftFrontRail",Vector3(1.54,loft_height,-2.99),Vector3(3.72,loft_height,-2.99),.86)

func _rail(p: Node3D, label: String, a: Vector3, b: Vector3, height: float) -> void:
	G.rod(p,label+"Top",a+Vector3.UP*height,b+Vector3.UP*height,.018,M.get_mat("metal"))
	G.rod(p,label+"Bottom",a+Vector3.UP*.10,b+Vector3.UP*.10,.012,M.get_mat("metal"))
	var count := maxi(2,ceili(a.distance_to(b)/.19))
	for i in range(count+1):
		var base := a.lerp(b,float(i)/count)
		G.rod(p,label+"Post",base,base+Vector3.UP*height,.009,M.get_mat("metal"))
	G.collider(p,label+"Collision",(a+b)/2+Vector3.UP*height/2,Vector3(absf(a.x-b.x)+.025,height,absf(a.z-b.z)+.025))

func _details(p: Node3D) -> void:
	_box(p,"WindowGlass",Vector3(3.02,1.65,-5.481),Vector3(.85,1.02,.012),"glass")
	for x in [2.565,3.02,3.475]:
		G.bevel_box(p,"WindowMullion",Vector3(x,1.65,-5.43),Vector3(.026,1.10,.045),M.get_mat("dark"),.003)
	for yy in [1.11,2.19]:
		_box(p,"WindowFrame",Vector3(3.02,yy,-5.43),Vector3(.95,.035,.06),"dark",false)
	for x in [2.78,3.02,3.26]:
		G.rod(p,"SecurityBar",Vector3(x,1.14,-5.46),Vector3(x,2.16,-5.46),.006,M.get_mat("metal"))
	_box(p,"StoneWindowSill",Vector3(3.02,1.10,-5.39),Vector3(.97,.035,.16),"tile",false)
	_box(p,"WindowRoller",Vector3(3.02,2.21,-5.39),Vector3(.96,.08,.055),"fabric",false)
	G.bevel_box(p,"AirConditioner",Vector3(.7511,2.82,-5.3556),Vector3(.5996,.25,.1786),M.get_mat("white"),.035)
	for i in range(5):
		_box(p,"ACLouver",Vector3(.7511,2.72+i*.011,-5.258),Vector3(.51,.004,.018),"dark",false)
	_box(p,"DoorMat",Vector3(-.18,.009,-.56),Vector3(.48,.015,.63),"fabric",false)
	for x in [.24,.39]:
		G.sphere(p,"SlipperSole",Vector3(x,.022,-.21),Vector3(.105,.035,.235),M.get_mat("rubber"))
		G.sphere(p,"SlipperStrap",Vector3(x,.05,-.25),Vector3(.106,.05,.08),M.get_mat("rubber"))
	G.rod(p,"HallConduit",Vector3(.024,3.18,-1.3),Vector3(.024,3.18,-5.30),.007,M.get_mat("white"))
	for y in [1.6,3.7]:
		_box(p,"HallTubeHousing",Vector3(.04,3.10,-y),Vector3(.05,.09,.76),"white",false)
		G.rod(p,"HallTube",Vector3(.075,3.10,-y-.32),Vector3(.075,3.10,-y+.32),.016,M.get_mat("white"))
	for i in range(10):
		_box(p,"PCFairyLight",Vector3(1.75+i*.19,loft_height-.213,-3.02),Vector3(.012,.008,.012),"rgb",false)
	_switch(p,"main",Vector3(.026,1.28,-4.15),PI/2,"Đèn phòng")
	_switch(p,"kitchen",Vector3(1.50,1.35,-.18),-PI/2,"Đèn bếp")
	_switch(p,"bathroom",Vector3(1.50,1.25,-1.86),-PI/2,"Đèn nhà vệ sinh")

func _switch(p: Node3D, circuit: String, pos: Vector3, angle: float, title: String) -> void:
	var body := Interaction.new()
	body.name = "Switch_"+circuit
	body.action = "light"
	body.payload = circuit
	body.title = title
	body.position = pos
	body.rotation.y = angle
	p.add_child(body)
	G.bevel_box(body,"Plate",Vector3.ZERO,Vector3(.09,.12,.018),M.get_mat("white"),.004)
	G.bevel_box(body,"Rocker",Vector3(0,0,.015),Vector3(.043,.058,.014),M.get_mat("white"),.003)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(.13,.16,.065)
	col.shape = shape
	body.add_child(col)

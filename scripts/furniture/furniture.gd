@tool
class_name FurnitureBuilder
extends Node3D

@export_enum("kitchen", "washer", "wardrobe", "clothes_rack", "fridge", "fan", "pc_desk", "office_chair", "aquarium", "bed", "bathroom", "cat_corner", "cat_bed", "litter_box") var kind := "pc_desk"
@export var pc_name := "Máy tính 01"
@export var dimensions: Vector3 = Vector3.ZERO
@export_enum("primary", "shelf") var desk_variant: String = "primary"
@export var include_chair: bool = false
var _built := false
var _fan_blades: Array[MeshInstance3D] = []
var _fan_angle: float = 0.0

func _ready() -> void:
	if _built:
		return
	_built = true
	match kind:
		"kitchen": _kitchen()
		"washer": _washer()
		"wardrobe": _wardrobe()
		"clothes_rack": _clothes_rack()
		"fridge": _fridge()
		"fan": _fan()
		"pc_desk": _desk()
		"office_chair": _chair(Vector3.ZERO)
		"aquarium": _aquarium()
		"bed": _bed()
		"bathroom": _bathroom()
		"cat_corner": _cat_corner()
		"cat_bed": _cat_bed()
		"litter_box": _litter_box()
	set_process(kind == "fan" and not Engine.is_editor_hint())

func _process(delta: float) -> void:
	_fan_angle = fmod(_fan_angle + delta * 8.0, TAU)
	for i in _fan_blades.size():
		var angle := _fan_angle + TAU * float(i) / 3.0
		_fan_blades[i].position = Vector3(cos(angle) * .10, 1.38 + sin(angle) * .10, -.02)
		_fan_blades[i].rotation.z = angle + .35

func m(key: String) -> StandardMaterial3D:
	return RoomMaterials.get_mat(key)

func _dimensions(nominal: Vector3) -> Vector3:
	return dimensions if dimensions.x > 0 and dimensions.y > 0 and dimensions.z > 0 else nominal

func bb(label: String, pos: Vector3, size: Vector3, material: String, bevel: float = .01, collide: bool = false) -> MeshInstance3D:
	return RoomGeo.bevel_box(self, label, pos, size, m(material), bevel, collide)

func b(label: String, pos: Vector3, size: Vector3, material: String, collide := false) -> MeshInstance3D:
	return RoomGeo.box(self, label, pos, size, m(material), collide)

func c(label: String, pos: Vector3, radius: float, height: float, material: String) -> MeshInstance3D:
	return RoomGeo.cylinder(self, label, pos, radius, height, m(material))

func s(label: String, pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	return RoomGeo.sphere(self, label, pos, size, m(material))

func r(label: String, start: Vector3, end: Vector3, radius: float, material: String) -> MeshInstance3D:
	return RoomGeo.rod(self, label, start, end, radius, m(material))

func t(label: String, pos: Vector3, inner: float, outer: float, material: String) -> MeshInstance3D:
	return RoomGeo.torus(self, label, pos, inner, outer, m(material))

func interaction(label: String, pos: Vector3, size: Vector3, action: String, title: String, payload := "") -> StaticBody3D:
	var body := RoomGeo.collider(self, label, pos, size)
	body.set_script(load("res://scripts/interaction/interactable.gd"))
	body.set("action", action)
	body.set("title", title)
	body.set("payload", payload)
	body.collision_layer = 3
	body.add_to_group("interactable")
	return body

func _label(text: String, pos: Vector3, font_size := 20, color := Color.WHITE) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.001
	label.position = pos
	label.modulate = color
	label.outline_size = 0
	add_child(label)
	return label

func _kitchen() -> void:
	var d: Vector3 = _dimensions(Vector3(1.0171, .86, .5976))
	var w: float = d.x
	var h: float = d.y
	var depth: float = d.z
	# Real cabinet shell leaves the sink hollow; the safety collider is separate.
	RoomGeo.collider(self, "KitchenCollision", Vector3(0, h / 2, 0), d)
	bb("CabinetBack", Vector3(0, h / 2, -depth / 2 + .015), Vector3(w, h, .03), "dark_wood", .006)
	for side in [-1.0, 1.0]:
		bb("CabinetSide", Vector3(side * (w / 2 - .014), h / 2, 0), Vector3(.028, h, depth), "wood", .005)
	b("CabinetFloor", Vector3(0, .06, 0), Vector3(w, .04, depth), "dark_wood")
	b("ToeKick", Vector3(0, .065, depth / 2 - .035), Vector3(w - .035, .10, .025), "rubber")
	for i in 3:
		var x: float = (float(i) - 1.0) * w / 3.0
		bb("CabinetDoor", Vector3(x, h / 2 + .015, depth / 2 + .008), Vector3(w / 3.0 - .006, h - .095, .022), "wood", .004)
		_handle(Vector3(x + w / 9.0, .61, depth / 2 + .028), .14)
	# Source-v4 basin and stove locations expressed in this cabinet's local frame.
	var sink_x: float = -.1718
	var sink_z: float = .0713
	var rim_y: float = h + .08
	var sink_w: float = .323
	var sink_depth: float = .3746
	var counter_w: float = w + .0481
	var counter_depth: float = depth + .0535
	var counter_z: float = .0178
	var left_edge: float = -counter_w / 2
	var right_edge: float = counter_w / 2
	var sink_left: float = sink_x - sink_w / 2
	var sink_right: float = sink_x + sink_w / 2
	bb("CounterLeft", Vector3((left_edge + sink_left) / 2, h + .03, counter_z), Vector3(sink_left - left_edge, .08, counter_depth), "granite", .005)
	bb("CounterRight", Vector3((right_edge + sink_right) / 2, h + .03, counter_z), Vector3(right_edge - sink_right, .08, counter_depth), "granite", .005)
	for back in [true, false]:
		var z0: float = counter_z - counter_depth / 2 if back else sink_z + sink_depth / 2
		var z1: float = sink_z - sink_depth / 2 if back else counter_z + counter_depth / 2
		bb("CounterSinkStrip", Vector3(sink_x, h + .03, (z0 + z1) / 2), Vector3(sink_w, .08, z1 - z0), "granite", .003)
	bb("SinkBasinBottom", Vector3(sink_x, rim_y - .17, sink_z), Vector3(sink_w - .018, .014, sink_depth - .018), "chrome", .006)
	for side in [-1.0, 1.0]:
		bb("SinkWallX", Vector3(sink_x + side * (sink_w / 2 - .006), rim_y - .086, sink_z), Vector3(.012, .17, sink_depth), "chrome", .003)
		bb("SinkWallZ", Vector3(sink_x, rim_y - .086, sink_z + side * (sink_depth / 2 - .006)), Vector3(sink_w, .17, .012), "chrome", .003)
		bb("SinkRolledLipX", Vector3(sink_x + side * sink_w / 2, rim_y, sink_z), Vector3(.015, .009, sink_depth + .02), "chrome", .003)
		bb("SinkRolledLipZ", Vector3(sink_x, rim_y, sink_z + side * sink_depth / 2), Vector3(sink_w + .02, .009, .015), "chrome", .003)
	c("SinkDrain", Vector3(sink_x, rim_y - .159, sink_z), .026, .004, "dark")
	t("DrainRing", Vector3(sink_x, rim_y - .156, sink_z), .023, .030, "chrome")
	var tap: Vector3 = Vector3(-.268, rim_y, -.155)
	c("TapFoot", tap, .025, .025, "chrome")
	r("TapStem", tap, tap + Vector3(0, .20, 0), .012, "chrome")
	for i in 10:
		var a: float = float(i) * PI / 10.0
		var a2: float = float(i + 1) * PI / 10.0
		r("CurvedTap", tap + Vector3(0, .20 + sin(a) * .055, .055 - cos(a) * .055), tap + Vector3(0, .20 + sin(a2) * .055, .055 - cos(a2) * .055), .012, "chrome")
	r("TapLever", tap + Vector3(.028, .06, 0), tap + Vector3(.063, .10, 0), .008, "chrome")
	bb("LimeGlassSplashback", Vector3(0, 1.34, -depth / 2), Vector3(counter_w, .68, .014), "green", .004)
	bb("InductionGlass", Vector3(.2336, rim_y + .003, .0892), Vector3(.2955, .026, .4103), "stove_glass", .008)
	for x in [.158, .3092]:
		t("InductionZone", Vector3(x, rim_y + .018, -.0219), .060, .062, "brushed_metal")
		t("InductionZoneInner", Vector3(x, rim_y + .018, -.0219), .034, .035, "brushed_metal")
	for x in [.17, .225, .28]:
		b("TouchControl", Vector3(x, rim_y + .018, .22), Vector3(.017, .001, .003), "white")
	var control_text := _label("+    -    I", Vector3(.235, rim_y + .02, .25), 10, Color("bbc4c4"))
	control_text.rotation.x = -PI / 2
	bb("ChoppingBoard", Vector3(-.40, 1.27, -depth / 2 + .018), Vector3(.15, .24, .014), "wood", .018)
	c("SoapBottle", Vector3(.005, rim_y + .06, -.23), .023, .12, "green")
	bb("SoapPump", Vector3(.014, rim_y + .128, -.23), Vector3(.045, .014, .015), "white", .004)
	# Three everyday condiments on the wire shelf seen against the green glass.
	bb("CondimentShelf", Vector3(.15, 1.405, -.247), Vector3(.34, .009, .078), "rubber", .003)
	r("ShelfFrontRail", Vector3(-.02, 1.445, -.207), Vector3(.32, 1.445, -.207), .003, "dark")
	for i in 3:
		var x: float = .045 + float(i) * .102
		c("CondimentBottle", Vector3(x, 1.475, -.247), .021, .13, "#928142" if i == 0 else "#6d7132")
		c("BottleLabel", Vector3(x, 1.465, -.247), .0215, .042, "cream")
		c("BottleNeck", Vector3(x, 1.55, -.247), .009, .025, "#6d7132")
		c("BottleCap", Vector3(x, 1.568, -.247), .011, .014, "orange" if i == 0 else "dark")

func _washer() -> void:
	var d: Vector3 = _dimensions(Vector3(.481, .96, .5619))
	var front: float = d.z / 2
	bb("WasherBody", Vector3(0, d.y / 2, 0), d, "dark", .018, true)
	bb("WasherTopLid", Vector3(0, d.y - .009, 0), Vector3(d.x + .005, .025, d.z + .008), "dark", .007)
	bb("ControlPanel", Vector3(0, d.y - .105, front + .004), Vector3(d.x - .018, .14, .018), "rubber", .006)
	bb("DetergentDrawer", Vector3(-.155, d.y - .10, front + .017), Vector3(.135, .086, .012), "dark", .004)
	b("DrawerGrip", Vector3(-.155, d.y - .125, front + .026), Vector3(.087, .009, .008), "brushed_metal")
	var dial := c("ProgramDial", Vector3(-.025, d.y - .10, front + .027), .033, .021, "brushed_metal")
	dial.rotation.x = PI / 2
	b("DialPointer", Vector3(-.025, d.y - .076, front + .040), Vector3(.003, .011, .003), "white")
	bb("Readout", Vector3(.125, d.y - .10, front + .019), Vector3(.12, .055, .006), "stove_glass", .003)
	_label("0:50", Vector3(.12, d.y - .095, front + .025), 19, Color("99bb9f"))
	_label("CASPER", Vector3(-.158, d.y - .10, front + .026), 10, Color("c4c8c8"))
	for x in [.095, .125, .155]:
		var button := c("WashButton", Vector3(x, d.y - .145, front + .025), .005, .006, "brushed_metal")
		button.rotation.x = PI / 2
	var center: Vector3 = Vector3(0, .455, front + .018)
	var gasket := t("DoorGasket", center, .172, .213, "rubber")
	gasket.rotation.x = PI / 2
	var rim := t("ChromeDoorRim", center + Vector3(0, 0, .015), .179, .204, "brushed_metal")
	rim.rotation.x = PI / 2
	var drum := c("RecessedDrum", center + Vector3(0, 0, .003), .175, .012, "dark")
	drum.rotation.x = PI / 2
	for i in 16:
		var a: float = float(i) * TAU / 16.0
		var hole := c("DrumPerforation", center + Vector3(cos(a) * .125, sin(a) * .125, .012), .007, .002, "brushed_metal")
		hole.rotation.x = PI / 2
	s("DoorConvexGlass", center + Vector3(0, 0, .035), Vector3(.335, .335, .05), "glass")
	bb("RecessedLatch", center + Vector3(.183, .01, .04), Vector3(.031, .11, .022), "rubber", .01)
	b("BottomPlinth", Vector3(0, .09, front + .003), Vector3(d.x - .02, .065, .012), "rubber")
	for x in [-d.x * .37, d.x * .37]:
		c("AdjustableFoot", Vector3(x, .012, front - .07), .024, .024, "rubber")
	_checked_cloth(Vector3(0, d.y + .014, 0), Vector2(d.x + .014, d.z + .014))
	_rice_cooker(Vector3(-.105, d.y + .021, -.135))
	_kettle(Vector3(.135, d.y + .021, .085))

func _wardrobe() -> void:
	var d: Vector3 = _dimensions(Vector3(1.302, 2.2, .3913))
	bb("WardrobeBody", Vector3(0, d.y / 2, 0), d, "dark_wood", .007, true)
	for side in [-1.0, 1.0]:
		bb("OakSidePanel", Vector3(side * (d.x / 2 - .011), d.y / 2, 0), Vector3(.022, d.y, d.z), "wood", .004)
	for i in 4:
		var x: float = (float(i) - 1.5) * d.x / 4
		bb("OakDoorPanel", Vector3(x, d.y / 2 + .015, d.z / 2 + .012), Vector3(d.x / 4 - .0055, d.y - .092, .024), "wood", .003)
		var offset: float = d.x / 4 * .32 * (1.0 if i % 2 == 0 else -1.0)
		_handle(Vector3(x + offset, 1.13, d.z / 2 + .026), .24)
	bb("TopTrim", Vector3(0, d.y - .009, 0), Vector3(d.x + .018, .032, d.z + .012), "dark_wood", .004)
	bb("BottomPlinth", Vector3(0, .042, d.z / 2 + .004), Vector3(d.x - .025, .07, .025), "dark_wood", .004)
	bb("Suitcase", Vector3(-.28, d.y + .16, -.015), Vector3(.48, .30, .32), "rubber", .035)
	for x in [-.45, -.35, -.25, -.15]:
		bb("SuitcaseRib", Vector3(x, d.y + .16, .148), Vector3(.018, .23, .013), "dark", .006)
	bb("SuitcaseSeam", Vector3(-.28, d.y + .16, .155), Vector3(.47, .006, .008), "brushed_metal", .002)
	r("LuggageHandle", Vector3(-.35, d.y + .334, -.015), Vector3(-.20, d.y + .334, -.015), .011, "rubber")
	bb("FoldedBlanketBase", Vector3(.32, d.y + .045, -.01), Vector3(.46, .085, .32), "fabric", .027)
	for i in 3:
		bb("FoldedFabricLayer", Vector3(.32, d.y + .025 + i * .023, .155), Vector3(.43, .016, .02), "blue_fabric", .006)

func _clothes_rack() -> void:
	var d: Vector3 = _dimensions(Vector3(1.04, 1.68, .31))
	for x in [-d.x / 2 + .02, d.x / 2 - .02]:
		r("RackUpright", Vector3(x, .04, 0), Vector3(x, d.y, 0), .016, "white")
		r("RackFoot", Vector3(x, .035, -d.z / 2), Vector3(x, .035, d.z / 2), .022, "white")
		for z in [-d.z / 2, d.z / 2]:
			c("RackFootCap", Vector3(x, .026, z), .024, .035, "rubber")
	r("HangingBar", Vector3(-d.x / 2 + .02, d.y, 0), Vector3(d.x / 2 - .02, d.y, 0), .017, "brushed_metal")
	r("RackBrace", Vector3(-d.x / 2 + .02, .18, 0), Vector3(d.x / 2 - .02, .18, 0), .011, "brushed_metal")
	var colors: Array[String] = ["blue_fabric", "fabric", "cream", "dark", "blue_fabric"]
	for i in 5:
		var x: float = -.39 + float(i) * .19
		var garment := _garment(colors[i], .76 if i != 3 else .90)
		garment.position = Vector3(x, d.y - .14, 0)
		garment.rotation.y = PI / 2 + (float(i % 3) - 1) * .06
		garment.scale.x = minf(1.0, d.z / .41 * .95)
		add_child(garment)
		var hook := t("HangerHook", Vector3(x, d.y - .028, 0), .017, .020, "brushed_metal")
		hook.rotation.z = PI / 2
		r("HangerNeck", Vector3(x, d.y - .04, 0), Vector3(x, d.y - .16, 0), .003, "brushed_metal")
		r("HangerShoulder", Vector3(x, d.y - .16, 0), Vector3(x, d.y - .24, -.15), .003, "brushed_metal")
		r("HangerShoulder", Vector3(x, d.y - .16, 0), Vector3(x, d.y - .24, .15), .003, "brushed_metal")
	RoomGeo.collider(self, "RackCollision", Vector3(0, .77, 0), Vector3(d.x, 1.54, d.z))

func _fridge() -> void:
	var d: Vector3 = _dimensions(Vector3(.5228, 1.48, .4411))
	var front: float = d.z / 2
	bb("FridgeBody", Vector3(0, d.y / 2, 0), d, "brushed_metal", .016, true)
	bb("DoorGasket", Vector3(0, d.y / 2, front + .005), Vector3(d.x - .024, d.y - .035, .016), "rubber", .008)
	bb("LowerDoor", Vector3(0, .49, front + .019), Vector3(d.x - .015, .945, .038), "metal", .013)
	bb("FreezerDoor", Vector3(0, 1.225, front + .019), Vector3(d.x - .015, .485, .038), "metal", .013)
	bb("FreezerHandleRecess", Vector3(-.035, .975, front + .033), Vector3(.32, .042, .015), "rubber", .012)
	bb("FreezerPullLip", Vector3(-.035, 1.004, front + .048), Vector3(.32, .015, .018), "brushed_metal", .005)
	_handle(Vector3(d.x * .35, .83, front + .039), .23)
	_label("SHARP", Vector3(-.15, 1.385, front + .042), 13, Color("d6d9d6"))
	bb("EnergySticker", Vector3(.16, 1.28, front + .040), Vector3(.072, .115, .0015), "green", .003)
	_label("ECO", Vector3(.16, 1.30, front + .043), 11, Color("dce9b0"))
	for side in [-1.0, 1.0]:
		c("FridgeFoot", Vector3(side * d.x * .34, .014, front - .045), .025, .028, "rubber")
	var base: float = d.y + .008
	c("WaterJug", Vector3(0, base + .22, -.03), .175, .43, "#276ca5")
	s("JugShoulder", Vector3(0, base + .43, -.03), Vector3(.35, .12, .35), "#276ca5")
	c("JugNeck", Vector3(0, base + .515, -.03), .046, .10, "#276ca5")
	c("JugCap", Vector3(0, base + .575, -.03), .050, .022, "dark")
	for y in [.06, .12, .29, .36]:
		t("JugMoulding", Vector3(0, base + y, -.03), .169, .180, "#3a83b4")
	bb("JugLabel", Vector3(0, base + .23, .147), Vector3(.20, .115, .0015), "#367cac", .005)
	_label("NƯỚC SẠCH", Vector3(0, base + .235, .150), 13, Color("c4dcdd"))

func _fan() -> void:
	t("OpenBaseRing",Vector3(0,.048,0),.204,.275,"rubber")
	for i in 3:
		var a:float=TAU*float(i)/3
		r("BaseSpoke",Vector3(0,.055,0),Vector3(cos(a)*.23,.055,sin(a)*.23),.019,"rubber")
	c("StemFoot",Vector3(0,.095,0),.06,.10,"rubber")
	c("LowerStem",Vector3(0,.58,0),.023,.94,"rubber")
	c("UpperStem",Vector3(0,1.15,0),.015,.30,"chrome")
	var motor:=c("Motor",Vector3(0,1.38,-.075),.073,.17,"dark")
	motor.rotation.x=PI/2
	for radius in [.075,.125,.175,.224]:
		var ring:=t("FanGrille",Vector3(0,1.38,.026),radius,radius+.003,"brushed_metal")
		ring.rotation.x=PI/2
	for i in 32:
		var a:float=TAU*float(i)/32
		r("GrilleSpoke",Vector3(cos(a)*.05,1.38+sin(a)*.05,.044),Vector3(cos(a)*.227,1.38+sin(a)*.227,-.008),.0017,"brushed_metal")
	for i in 3:
		var a:float=TAU*float(i)/3
		var blade:=s("FanBlade",Vector3(cos(a)*.10,1.38+sin(a)*.10,-.02),Vector3(.22,.085,.015),"orange")
		blade.rotation.z=a+.35
		_fan_blades.append(blade)
	s("FanHub",Vector3(0,1.38,.05),Vector3(.09,.09,.065),"orange")
	RoomGeo.collider(self,"FanCollision",Vector3(0,.81,0),Vector3(.48,1.62,.35))

func _desk() -> void:
	if desk_variant == "shelf":
		_secondary_desk()
		return
	var d: Vector3 = _dimensions(Vector3(1.4781, .75, .5633))
	bb("Desktop", Vector3(0, d.y, 0), Vector3(d.x, .055, d.z), "dark", .009, true)
	for x in [-d.x / 2 + .06, d.x / 2 - .06]:
		for z in [-d.z / 2 + .035, d.z / 2 - .035]:
			# The detailed case occupies the source blockout's front-left leg.
			# Inset this support beneath the desktop instead of intersecting the case.
			var leg_x: float = -.34 if x < 0 and z > 0 else x
			bb("DeskLeg", Vector3(leg_x, .36, z), Vector3(.035, .72, .035), "brushed_metal", .003, true)
			bb("DeskFoot", Vector3(leg_x, .012, z), Vector3(.038, .022, .038), "rubber", .004)
	r("RearBrace", Vector3(-d.x / 2 + .06, .20, -d.z / 2 + .035), Vector3(d.x / 2 - .06, .67, -d.z / 2 + .035), .009, "dark")
	var monitor: Vector3 = Vector3(-.0496, 1.12, -.2037)
	bb("MonitorStandBase", Vector3(monitor.x, .795, -.15), Vector3(.23, .025, .15), "dark", .012)
	bb("MonitorStand", Vector3(monitor.x, .92, -.213), Vector3(.037, .24, .025), "dark", .006)
	bb("MonitorBezel", monitor, Vector3(.585, .38, .035), "rubber", .006)
	_screen("MonitorScreen", monitor + Vector3(0, .005, .019), Vector2(.5654, .342))
	_label("AOC", monitor + Vector3(0, -.179, .022), 10, Color("a3a8aa"))
	var power_led := c("MonitorPowerLED", monitor + Vector3(.273, -.178, .023), .002, .002, "screen")
	power_led.rotation.x = PI / 2
	_keyboard(Vector3(-.0298, .81, .156), Vector2(.4166, .1647), true)
	bb("GreenMousePad", Vector3(.4166, .788, .156), Vector3(.3373, .014, .234), "green", .008)
	s("MouseShell", Vector3(.4166, .818, .156), Vector3(.064, .036, .105), "white")
	b("MouseButtonSplit", Vector3(.4166, .836, .135), Vector3(.0015, .0015, .043), "dark")
	var wheel := c("MouseScrollWheel", Vector3(.4166, .836, .131), .006, .009, "rubber")
	wheel.rotation.z = PI / 2
	_pc_case(Vector3(-.5754, 0, .2253))
	# Cable runs and power strip stay tucked against the wall/desk frame.
	r("MonitorLead", Vector3(monitor.x, 1.02, -.225), Vector3(-.02, .68, -.255), .003, "rubber")
	r("CableDown", Vector3(-.02, .68, -.255), Vector3(.06, .05, -.255), .003, "rubber")
	r("CableFloor", Vector3(.06, .05, -.255), Vector3(-.45, .04, -.23), .003, "rubber")
	bb("PowerStrip", Vector3(.15, .045, -.23), Vector3(.23, .036, .045), "white", .006)
	for x in [.075, .13, .185, .24]:
		b("SocketSlot", Vector3(x, .064, -.23), Vector3(.003, .002, .016), "dark")
	# Headphones have a real headband arc and separate cushions.
	for i in 12:
		var a: float = PI * float(i) / 12.0
		var a2: float = PI * float(i + 1) / 12.0
		r("HeadphoneBand", Vector3(-.10 + cos(a) * .10, .81 + sin(a) * .035, .23), Vector3(-.10 + cos(a2) * .10, .81 + sin(a2) * .035, .23), .008, "rubber")
	for x in [-.20, 0.0]:
		bb("HeadphoneCushion", Vector3(x, .82, .23), Vector3(.038, .06, .064), "fabric", .015)
	_pinboard(Vector3(-.2282, 1.74, -.234))
	if include_chair:
		_chair(Vector3(-.01, 0, .5547))
	interaction("PCInteraction", monitor + Vector3(0, 0, .020), Vector3(.585, .38, .045), "pc", "Dùng máy tính", pc_name)

func _chair(origin: Vector3) -> void:
	# Mesh office chair, modeled around the seat center from the measured layout.
	bb("SeatShell", origin + Vector3(0, .428, 0), Vector3(.49, .045, .45), "rubber", .018)
	bb("SeatCushion", origin + Vector3(0, .477, -.008), Vector3(.48, .085, .455), "fabric", .035)
	b("SeatPipingFront", origin + Vector3(0, .466, -.232), Vector3(.40, .006, .005), "dark")
	c("GasCylinder", origin + Vector3(0, .26, .025), .025, .35, "chrome")
	c("GasCover", origin + Vector3(0, .21, .025), .038, .20, "rubber")
	r("BackSpine", origin + Vector3(0, .42, .16), origin + Vector3(0, .75, .245), .019, "rubber")
	var rim_points: Array[Vector3] = [
		Vector3(-.17,.55,.20), Vector3(-.215,.61,.215), Vector3(-.224,.93,.267),
		Vector3(-.195,1.09,.28), Vector3(0,1.115,.285), Vector3(.195,1.09,.28),
		Vector3(.224,.93,.267), Vector3(.215,.61,.215), Vector3(.17,.55,.20)
	]
	for i in rim_points.size() - 1:
		r("BackFrame", origin + rim_points[i], origin + rim_points[i + 1], .013, "rubber")
	r("LowerBackFrame", origin + rim_points[0], origin + rim_points[-1], .013, "rubber")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(m("chair_mesh"))
	for iy in 14:
		for ix in 12:
			var vertices: Array[Vector3] = []
			for uv: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var u: float = (ix + uv.x) / 12.0
				var v: float = (iy + uv.y) / 14.0
				var half_width: float = .175 + sin(v * PI) * .037
				var z: float = .205 + v * .075 - sin(v * PI) * .045 + sin(u * PI) * .015
				vertices.append(origin + Vector3((u * 2.0 - 1.0) * half_width, .566 + v * .527, z))
			for index in [0,2,1,0,3,2]:
				var vertex: Vector3 = vertices[index]
				st.set_uv(Vector2(vertex.x - origin.x, vertex.y - origin.y))
				st.add_vertex(vertex)
	st.generate_normals()
	st.generate_tangents()
	var back_mesh := MeshInstance3D.new()
	back_mesh.name = "TensionedMeshBack"
	back_mesh.mesh = st.commit()
	add_child(back_mesh)
	bb("LumbarAdjuster", origin + Vector3(0, .665, .19), Vector3(.29, .029, .025), "rubber", .008)
	for side in [-1.0, 1.0]:
		r("ArmSupport", origin + Vector3(side * .215, .45, .11), origin + Vector3(side * .235, .645, .09), .014, "rubber")
		r("ArmSupport", origin + Vector3(side * .235, .645, .09), origin + Vector3(side * .235, .665, -.10), .014, "rubber")
		bb("ArmPad", origin + Vector3(side * .235, .675, -.015), Vector3(.048, .026, .29), "rubber", .012)
	for i in 5:
		var a: float = TAU * float(i) / 5.0
		var tip: Vector3 = Vector3(cos(a) * .23, .078, sin(a) * .23 + .025)
		r("FiveStarLeg", origin + Vector3(0, .16, .025), origin + tip, .017, "chrome")
		var caster := c("TwinCaster", origin + tip - Vector3(0, .035, 0), .035, .055, "rubber")
		caster.rotation.z = PI / 2
	r("SeatHeightLever", origin + Vector3(.10, .40, .02), origin + Vector3(.26, .40, -.02), .008, "dark")
	RoomGeo.collider(self, "ChairCollision", origin + Vector3(0, .46, .025), Vector3(.52, .92, .52))

func _aquarium() -> void:
	# A 4 cm bezel trim and 3.18 cm tank trim resolve the v4 placeholder overlap.
	var d: Vector3 = _dimensions(Vector3(.365, .45, .416))
	bb("TankBase",Vector3(0,.012,0),Vector3(d.x,.024,d.z),"rubber",.003)
	b("Substrate",Vector3(0,.047,0),Vector3(d.x-.014,.05,d.z-.014),"sand")
	for side in [-1.0,1.0]:
		b("SideGlass",Vector3(side*(d.x/2-.003),d.y/2,0),Vector3(.006,d.y,d.z),"glass")
		b("FrontGlass",Vector3(0,d.y/2,side*(d.z/2-.003)),Vector3(d.x,d.y,.006),"glass")
		b("GlassEdge",Vector3(side*(d.x/2-.003),d.y-.002,0),Vector3(.006,.005,d.z),"water")
	b("WaterSurface",Vector3(0,d.y-.026,0),Vector3(d.x-.013,.003,d.z-.013),"water")
	for i in 9:
		var x: float = -d.x*.38 + i*d.x*.095
		var z: float = -d.z*.30 + (i%3)*d.z*.13
		var height: float = .19 + .025*(i%4)
		r("PlantStem",Vector3(x,.07,z),Vector3(x+.012,height+.07,z),.002,"leaf")
		for leaf in 5:
			var side: float = -1.0 if leaf%2 else 1.0
			var blade:=s("AquaticLeaf",Vector3(x+side*.017,.09+.041*leaf,z),Vector3(.042,.013,.018),"leaf")
			blade.rotation.z=side*.55
	for i in 18:
		s("SubstratePebble",Vector3(-d.x*.36+(i%6)*d.x*.14,.08,-d.z*.24+(i/6)*d.z*.21),Vector3(.027,.018,.023),"cream")
	for i in 3:
		var fish:=Node3D.new()
		fish.name="Fish"
		fish.position=Vector3(-.09+i*.085,.21+.045*i,.075)
		add_child(fish)
		RoomGeo.sphere(fish,"FishBody",Vector3.ZERO,Vector3(.046,.019,.014),m("orange"))
		RoomGeo.sphere(fish,"FishEye",Vector3(.014,.004,.007),Vector3(.003,.003,.003),m("dark"))
		var tail:=RoomGeo.sphere(fish,"Tail",Vector3(-.026,0,0),Vector3(.016,.026,.006),m("orange"))
		tail.rotation.z=.1
	bb("FilterHousing",Vector3(d.x/2-.046,d.y-.072,-d.z/2+.036),Vector3(.065,.13,.06),"dark",.005)
	r("FilterIntake",Vector3(d.x/2-.046,d.y-.08,-d.z/2+.037),Vector3(d.x/2-.046,.10,-d.z/2+.037),.007,"dark")
	for y in [.095,.11,.125]:
		t("IntakeGuard",Vector3(d.x/2-.046,y,-d.z/2+.037),.006,.009,"dark")
	r("LampBracket",Vector3(-.10,d.y-.02,-.17),Vector3(-.10,d.y+.065,-.17),.005,"dark")
	bb("TankLamp",Vector3(-.025,d.y+.065,-.035),Vector3(.286,.019,.0794),"dark",.005)
	b("TankLED",Vector3(-.025,d.y+.053,-.035),Vector3(.255,.004,.062),"screen")
	interaction("TankInteraction",Vector3(0,d.y/2,0),d,"aquarium","Quan sát bể cá")

func _bed() -> void:
	var d: Vector3=_dimensions(Vector3(1.456,.24,1.5277))
	bb("Mattress",Vector3(0,d.y/2,0),d,"blue_fabric",.055)
	for side in [-1.0,1.0]:
		r("MattressPipingX",Vector3(side*(d.x/2-.008),.14,-d.z/2+.035),Vector3(side*(d.x/2-.008),.14,d.z/2-.035),.003,"cream")
		r("MattressPipingZ",Vector3(-d.x/2+.035,.14,side*(d.z/2-.008)),Vector3(d.x/2-.035,.14,side*(d.z/2-.008)),.003,"cream")
	for x in [-.416,.2947]:
		bb("SleepingPillow",Vector3(x,d.y+.075,-.5952),Vector3(.4767,.14,.2976),"cream" if x<0 else "blue_fabric",.045)
		r("PillowSeam",Vector3(x-.205,d.y+.065,-.442),Vector3(x+.205,d.y+.065,-.442),.002,"cream")
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(m("blue_fabric"))
	for iz in 14:
		for ix in 24:
			var corners:Array[Vector3]=[]
			for uv:Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var x:float=-.69765+(ix+uv.x)*1.3953/24
				var z:float=.19345+(iz+uv.y)*.6051/14
				var y:float=d.y+.018+sin(x*19+z*5)*.018+sin(x*42-z*11)*.006
				if z>d.z/2-.04:
					y-=(z-(d.z/2-.04))*.7
				corners.append(Vector3(x,y,z))
			for index in [0,1,2,0,2,3]:
				st.set_uv(Vector2(corners[index].x,corners[index].z))
				st.add_vertex(corners[index])
	st.generate_normals()
	st.generate_tangents()
	var blanket:=MeshInstance3D.new()
	blanket.name="Blanket"
	blanket.mesh=st.commit()
	add_child(blanket)
	_plush(Vector3(.43,d.y+.105,.13),"cream",.30)
	_plush(Vector3(-.43,d.y+.08,.10),"orange",.23)
	interaction("BedInteraction",Vector3(0,d.y/2,0),Vector3(d.x,d.y,d.z),"bed","Gấp chăn")

func _plush(pos: Vector3, color: String, size: float) -> void:
	s("PlushBody", pos, Vector3(size, size * .95, size * .70), color)
	s("PlushHead", pos + Vector3(0, size * .52, 0), Vector3(size * .7, size * .65, size * .62), color)
	for x in [-1.0, 1.0]:
		s("PlushEar", pos + Vector3(x * size * .24, size * .79, 0), Vector3(size * .23, size * .23, size * .20), color)
		s("PlushEye", pos + Vector3(x * size * .13, size * .57, size * .28), Vector3(size * .045, size * .055, size * .025), "dark")
		s("PlushFoot", pos + Vector3(x * size * .25, -size * .26, size * .18), Vector3(size * .40, size * .32, size * .40), color)
	s("PlushNose", pos + Vector3(0, size * .44, size * .31), Vector3(size * .12, size * .07, size * .04), "dark")

func _bathroom() -> void:
	# Exact v4 service-annex origin: source-plan (1.54,2.955), root yaw=0.
	# Local +Z points toward the lower wall of the plan; no shell in this asset.
	_basin(Vector3(.52,.80,.88),Vector2(.41,.30),"white")
	c("BasinPedestal",Vector3(.52,.37,.94),.077,.73,"white")
	r("BasinTap",Vector3(.52,.82,1.015),Vector3(.52,.985,1.015),.012,"chrome")
	r("BasinSpout",Vector3(.52,.985,1.015),Vector3(.52,.985,.92),.012,"chrome")
	bb("MirrorFrame",Vector3(.52,1.51,1.14),Vector3(.425,.515,.022),"dark",.035)
	bb("MirrorSurface",Vector3(.52,1.51,1.125),Vector3(.40,.49,.005),"chrome",.025)
	RoomGeo.collider(self,"BasinCollision",Vector3(.52,.41,.88),Vector3(.41,.82,.30))
	s("ToiletPedestal",Vector3(1.16,.17,.29),Vector3(.30,.34,.39),"white")
	_basin(Vector3(1.16,.405,.35),Vector2(.42,.53),"white")
	var seat:=t("ToiletSeat",Vector3(1.16,.453,.35),.137,.188,"white")
	seat.scale.z=1.30
	var water:=c("ToiletWater",Vector3(1.16,.36,.35),.11,.005,"water")
	water.scale.z=1.35
	bb("ToiletCistern",Vector3(1.16,.605,.075),Vector3(.42,.37,.16),"white",.035)
	bb("CisternLid",Vector3(1.16,.802,.075),Vector3(.435,.029,.17),"white",.012)
	c("FlushButton",Vector3(1.25,.820,.075),.021,.007,"chrome")
	RoomGeo.collider(self,"ToiletCollision",Vector3(1.16,.405,.31),Vector3(.43,.81,.56))
	r("ShowerRail",Vector3(2.08,1.18,.22),Vector3(2.08,2.22,.22),.014,"chrome")
	r("ShowerArm",Vector3(2.08,2.20,.22),Vector3(1.91,2.22,.22),.013,"chrome")
	c("ShowerHead",Vector3(1.91,2.207,.22),.070,.024,"chrome")
	bb("Mixer",Vector3(2.08,1.06,.22),Vector3(.055,.065,.16),"chrome",.014)
	for i in 16:
		var a:float=float(i)/16*PI
		var a2:float=float(i+1)/16*PI
		r("ShowerHose",Vector3(2.08-sin(a)*.10,1.13-cos(a)*.30,.23),Vector3(2.08-sin(a2)*.10,1.13-cos(a2)*.30,.23),.006,"chrome")
	bb("Drain",Vector3(1.86,.009,.88),Vector3(.12,.013,.12),"brushed_metal",.005)
	for i in 5:
		b("DrainSlot",Vector3(1.82+i*.02,.017,.88),Vector3(.006,.002,.085),"dark")

func _cat_corner() -> void:
	bb("PetMat",Vector3(0,.008,0),Vector3(.17,.015,.28),"pink",.012)
	for z in [-.067,.067]:
		c("BowlBase",Vector3(0,.031,z),.064,.040,"pink")
		t("BowlRim",Vector3(0,.054,z),.046,.064,"pink")
		c("BowlInside",Vector3(0,.044,z),.047,.009,"chrome")
	var food:=Node3D.new()
	food.name="Food"
	food.visible=false
	add_child(food)
	for i in 14:
		var a:float=i*2.4
		var radius:float=.010*sqrt(float(i))
		RoomGeo.sphere(food,"Kibble",Vector3(cos(a)*radius,.055,-.067+sin(a)*radius),Vector3(.010,.008,.009),m("food"))
	c("BowlWater",Vector3(0,.052,.067),.046,.003,"water")
	interaction("BowlInteraction",Vector3(0,.045,0),Vector3(.17,.09,.28),"bowl","Cho Bống ăn")

func _litter_box() -> void:
	b("LitterBase", Vector3(0, .065, 0), Vector3(.38, .13, .52), "cream", true)
	b("LitterSand", Vector3(0, .134, 0), Vector3(.34, .01, .48), "sand")
	for x in [-.18, .18]:
		b("LitterWall", Vector3(x, .23, 0), Vector3(.025, .30, .49), "ceramic")
	b("LitterBack", Vector3(0, .23, -.24), Vector3(.37, .30, .025), "ceramic")
	s("LitterRoof", Vector3(0, .39, -.035), Vector3(.39, .12, .45), "ceramic")
	b("LitterLip", Vector3(0, .16, .24), Vector3(.37, .07, .025), "ceramic")

func _secondary_desk() -> void:
	var d: Vector3 = _dimensions(Vector3(1.2393, .75, .5059))
	bb("Desktop", Vector3(0, d.y, 0), Vector3(d.x, .060, d.z), "dark", .008, true)
	for x in [-.5287, .52]:
		for z in [-.2281, .1885]:
			bb("DeskLeg", Vector3(x, .35, z), Vector3(.035, .70, .035), "dark", .003, true)
	bb("KeyboardTray", Vector3(.078, .704, .10), Vector3(.56, .020, .32), "dark_wood", .005)
	r("RearBrace", Vector3(-.5287,.12,-.2281), Vector3(.52,.67,-.2281), .009, "dark")
	# V4 yaw=PI: source X2.8227 is local +.078, monitor toward local -Z.
	bb("LaptopBase", Vector3(.078, .804, -.0389), Vector3(.4767, .023, .435), "dark", .007)
	_keyboard(Vector3(.078, .817, .056), Vector2(.425, .125), false)
	bb("Touchpad", Vector3(.078, .829, .146), Vector3(.115, .001, .044), "brushed_metal", .004)
	var lid := bb("LaptopDisplayLid", Vector3(.078, 1.08, -.2579), Vector3(.5027, .395, .018), "dark", .007)
	lid.rotation.x = -.10
	var screen := _screen("LaptopScreen", Vector3(.078, 1.08, -.2459), Vector2(.4593, .35))
	screen.rotation.x = -.10
	bb("RaisedLaptopHingeSupport", Vector3(.078, .848, -.237), Vector3(.43, .068, .025), "rubber", .006)
	r("LaptopHinge", Vector3(-.16, .882, -.238), Vector3(.315, .882, -.238), .008, "brushed_metal")
	var shelf_x: float = -.4593
	var shelf_z: float = -.0595
	for x in [shelf_x - .105, shelf_x + .105]:
		for z in [shelf_z - .205, shelf_z + .205]:
			bb("ShelfUpright", Vector3(x, 1.115, z), Vector3(.025, .72, .025), "dark", .003)
	for y in [.80, 1.12, 1.46]:
		bb("ShelfBoard", Vector3(shelf_x, y, shelf_z), Vector3(.234, .024, .4464), "dark_wood", .004)
	# Open top bridge and rear posts distinguish Đức's shelf desk from PC 01.
	for x in [-.565, .56]:
		bb("RearShelfPost", Vector3(x, 1.11, -.231), Vector3(.025,.71,.025), "dark", .003)
	bb("RearShelfTop", Vector3(0, 1.46, -.17), Vector3(1.15,.025,.18), "dark_wood", .005)
	for i in 4:
		bb("ShelfBook", Vector3(shelf_x - .065 + i * .04, 1.248, shelf_z), Vector3(.029,.23,.18), "cream" if i % 2 else "blue_fabric", .002)
	# Small keepsakes on the top shelf, with one articulated desk toy.
	bb("PhotoStand", Vector3(.20,1.54,-.17), Vector3(.10,.14,.018), "dark", .004)
	b("PhotoPaper", Vector3(.20,1.54,-.158), Vector3(.085,.12,.002), "cream")
	_plush(Vector3(.40,1.52,-.17), "cream", .12)
	c("DeskMug", Vector3(.40,.83,.13), .034,.10,"white")
	var mug_handle := t("MugHandle", Vector3(.441,.84,.13),.018,.024,"white")
	mug_handle.rotation.z = PI/2
	if include_chair:
		_chair(Vector3(.1127,0,.6151))
	interaction("PCInteraction", Vector3(.078,1.08,-.23), Vector3(.5027,.395,.05), "pc", "Dùng máy tính Đức", pc_name)

func _keyboard(origin: Vector3, size: Vector2, white_keys: bool) -> void:
	bb("KeyboardChassis", origin, Vector3(size.x, .024, size.y), "white" if white_keys else "rubber", .006)
	var cols: int = 14
	var rows: int = 5
	var key_w: float = (size.x - .026) / float(cols)
	var key_d: float = (size.y - .018) / float(rows)
	for row in rows:
		for col in cols:
			if row == 4 and col > 3 and col < 9:
				continue
			var pos: Vector3 = origin + Vector3(-size.x / 2 + .013 + key_w * (col + .5), .016, -size.y / 2 + .009 + key_d * (row + .5))
			bb("Keycap", pos, Vector3(key_w - .003, .009, key_d - .003), "white" if white_keys else "dark", .0015)
	bb("Spacebar", origin + Vector3(-key_w * .5, .016, size.y / 2 - .009 - key_d * .5), Vector3(key_w * 5.8,.009,key_d-.003), "white" if white_keys else "dark", .002)

func _screen(label: String, pos: Vector3, size: Vector2) -> MeshInstance3D:
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	screen.name = label
	screen.mesh = quad
	screen.material_override = m("screen_desktop")
	screen.position = pos
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(screen)
	return screen

func _pc_case(origin: Vector3) -> void:
	var w: float = .3472
	var h: float = .60
	var depth: float = .3813
	RoomGeo.collider(self, "PCCaseCollision", origin + Vector3(0,h/2,0), Vector3(w,h,depth))
	for y in [.024,h-.018]:
		bb("CaseDeck", origin + Vector3(0,y,0),Vector3(w,.036,depth),"rubber",.006)
	bb("CaseBack",origin+Vector3(0,h/2,-depth/2+.009),Vector3(w,h-.07,.018),"dark",.003)
	bb("LeftCasePanel",origin+Vector3(-w/2+.008,h/2,0),Vector3(.016,h-.07,depth-.02),"dark",.004)
	for x in [-w/2+.008,w/2-.008]:
		for z in [-depth/2+.01,depth/2-.01]:
			bb("CasePillar",origin+Vector3(x,h/2,z),Vector3(.018,h-.05,.018),"dark",.003)
	b("GlassSidePanel",origin+Vector3(w/2+.001,h/2,0),Vector3(.004,h-.065,depth-.025),"glass")
	b("GlassFrontPanel",origin+Vector3(0,h/2,depth/2+.002),Vector3(w-.025,h-.065,.004),"glass")
	for y in [.12,.31,.49]:
		var fan := t("RGBIntakeRing",origin+Vector3(0,y,depth/2-.01),.069,.080,"rgb")
		fan.rotation.x=PI/2
		var hub := c("IntakeHub",origin+Vector3(0,y,depth/2-.004),.022,.014,"dark")
		hub.rotation.x=PI/2
		for i in 7:
			var a: float = TAU * float(i)/7.0
			var blade := bb("CaseFanBlade",origin+Vector3(cos(a)*.044,y+sin(a)*.044,depth/2-.008),Vector3(.056,.019,.006),"dark",.005)
			blade.rotation.z=a+.4
	bb("Motherboard",origin+Vector3(-w/2+.025,.36,-.025),Vector3(.012,.36,.26),"#30413b",.002)
	bb("GraphicsCard",origin+Vector3(-.015,.225,-.02),Vector3(.23,.046,.24),"dark",.004)
	bb("GPUAccent",origin+Vector3(w/2-.032,.244,-.02),Vector3(.006,.009,.20),"rgb",.002)
	bb("PowerSupply",origin+Vector3(0,.09,-.07),Vector3(.24,.12,.19),"rubber",.004)
	for z in [-.045,.005]:
		bb("MemoryStick",origin+Vector3(-.12,.41,z),Vector3(.02,.13,.018),"dark",.003)
	var cooler := t("CPUCooler",origin+Vector3(-.10,.39,-.06),.043,.052,"rgb")
	cooler.rotation.z=PI/2
	for i in 5:
		r("CaseCable",origin+Vector3(.11,.13,-.10+i*.009),origin+Vector3(.08,.28,-.07+i*.009),.003,"rubber")
	for x in [-.125,.125]:
		for z in [-.13,.13]:
			bb("CaseFoot",origin+Vector3(x,.015,z),Vector3(.036,.03,.045),"rubber",.004)

func _pinboard(origin: Vector3) -> void:
	bb("PinboardFrame",origin,Vector3(.744,.35,.022),"dark_wood",.006)
	b("CorkSurface",origin+Vector3(0,0,.014),Vector3(.71,.318,.008),"sand")
	for i in 6:
		var x: float = -.29+float(i)*.115
		b("KeepsakePaper",origin+Vector3(x,.01,.021),Vector3(.086,.24,.002),"cream")
		for row in 3:
			b("KeepsakeImage",origin+Vector3(x,.085-float(row)*.07,.023),Vector3(.065,.053,.001),"blue_fabric" if (i+row)%2 else "pink")
		var pin := c("Pin",origin+Vector3(x,.145,.026),.004,.004,"dark")
		pin.rotation.x=PI/2

func _handle(origin: Vector3, length: float) -> void:
	for side in [-1.0,1.0]:
		r("HandleMount",origin+Vector3(0,side*(length/2-.012),0),origin+Vector3(0,side*(length/2-.012),.022),.006,"brushed_metal")
	bb("HandleGrip",origin+Vector3(0,0,.025),Vector3(.014,length,.018),"brushed_metal",.005)

func _rice_cooker(origin: Vector3) -> void:
	c("CookerBase",origin+Vector3(0,.018,0),.10,.036,"white")
	c("RiceCookerBody",origin+Vector3(0,.115,0),.105,.20,"pink")
	t("CookerRim",origin+Vector3(0,.218,0),.094,.109,"white")
	c("CookerLid",origin+Vector3(0,.227,0),.108,.026,"white")
	bb("CookerHandle",origin+Vector3(0,.26,0),Vector3(.11,.035,.027),"pink",.01)
	bb("CookerSwitch",origin+Vector3(0,.095,.105),Vector3(.043,.046,.015),"white",.008)
	bb("CookerLamp",origin+Vector3(0,.095,.115),Vector3(.015,.007,.003),"orange",.002)
	for side in [-1.0,1.0]:
		bb("CookerSideGrip",origin+Vector3(side*.118,.17,0),Vector3(.03,.034,.067),"white",.008)

func _kettle(origin: Vector3) -> void:
	c("KettleBase",origin+Vector3(0,.012,0),.069,.024,"rubber")
	c("KettleBody",origin+Vector3(0,.095,0),.064,.16,"chrome")
	c("KettleLid",origin+Vector3(0,.181,0),.066,.018,"rubber")
	r("KettleSpout",origin+Vector3(.055,.13,0),origin+Vector3(.09,.17,0),.020,"chrome")
	for i in 9:
		var a: float = -PI/2+PI*float(i)/9.0
		var a2: float = -PI/2+PI*float(i+1)/9.0
		r("KettleGrip",origin+Vector3(-.055-cos(a)*.035,.105+sin(a)*.065,0),origin+Vector3(-.055-cos(a2)*.035,.105+sin(a2)*.065,0),.011,"rubber")

func _checked_cloth(origin: Vector3, size: Vector2) -> void:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	for iz in 10:
		for ix in 10:
			var corners: Array[Vector3] = []
			for uv: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var x: float = -size.x/2 + (ix+uv.x)*size.x/10
				var z: float = -size.y/2 + (iz+uv.y)*size.y/10
				corners.append(origin+Vector3(x,sin(x*35)*.0015+sin(z*28)*.001,z))
			for index in [0,1,2,0,2,3]:
				st.set_color(Color("deded4") if (ix+iz)%2 else Color("24292a"))
				st.add_vertex(corners[index])
	st.generate_normals()
	var cloth := MeshInstance3D.new()
	cloth.name="CheckerCloth"
	cloth.mesh=st.commit()
	add_child(cloth)

func _garment(material_key: String, length: float) -> MeshInstance3D:
	# Closed tailored silhouette with shaped shoulders, neckline, sleeves and hems.
	var outline := PackedVector2Array([
		Vector2(-.045,0),Vector2(-.15,-.06),Vector2(-.205,-.29),Vector2(-.15,-.32),
		Vector2(-.112,-.20),Vector2(-.12,-length),Vector2(.12,-length),Vector2(.112,-.20),
		Vector2(.15,-.32),Vector2(.205,-.29),Vector2(.15,-.06),Vector2(.045,0),
		Vector2(.033,-.04),Vector2(-.033,-.04)])
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(m(material_key))
	for side in [-1.0,1.0]:
		for i in range(0,indices.size(),3):
			var order: Array = [2,1,0] if side>0 else [0,1,2]
			for j in order:
				var p: Vector2=outline[indices[i+j]]
				var fold: float = sin(p.x*67+p.y*5)*.008 + sin(p.y*13)*.005
				st.set_uv(Vector2(p.x,p.y))
				st.add_vertex(Vector3(p.x,p.y,side*.014+fold))
	for i in outline.size():
		var a: Vector2=outline[i]
		var next: Vector2=outline[(i+1)%outline.size()]
		var quad: Array[Vector3]=[]
		for p: Vector2 in [a,next]:
			var fold: float=sin(p.x*67+p.y*5)*.008+sin(p.y*13)*.005
			quad.append(Vector3(p.x,p.y,-.014+fold))
			quad.append(Vector3(p.x,p.y,.014+fold))
		for index in [0,1,3,0,3,2]:
			st.set_uv(Vector2(quad[index].x,quad[index].y))
			st.add_vertex(quad[index])
	st.generate_normals()
	if m(material_key).normal_enabled:
		st.generate_tangents()
	var garment:=MeshInstance3D.new()
	garment.name="TailoredGarment"
	garment.mesh=st.commit()
	return garment

func _basin(origin: Vector3, size: Vector2, material_key: String) -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(m(material_key))
	for outer in [false,true]:
		for ring in 8:
			for seg in 32:
				var vertices:Array[Vector3]=[]
				for uv:Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
					var radius:float=.08+(ring+uv.y)*.92/8
					var a:float=(seg+uv.x)*TAU/32
					var y:float=-.07+.11*radius*radius
					if outer:
						y-=.012*(1-radius)
					vertices.append(origin+Vector3(cos(a)*size.x*.5*radius,y,sin(a)*size.y*.5*radius))
				var order:Array=[0,1,2,0,2,3] if outer else [0,2,1,0,3,2]
				for index in order:
					st.set_uv(Vector2(vertices[index].x,vertices[index].z))
					st.add_vertex(vertices[index])
	st.generate_normals()
	var bowl:=MeshInstance3D.new()
	bowl.name="ConcaveBasin"
	bowl.mesh=st.commit()
	add_child(bowl)
	c("BasinDrain",origin+Vector3(0,-.068,0),.018,.004,"chrome")
	var rim:=t("BasinRim",origin+Vector3(0,.04,0),size.x*.5-.006,size.x*.5+.003,material_key)
	rim.scale.z=size.y/size.x

func _cat_bed() -> void:
	s("CatCushion",Vector3(0,.052,0),Vector3(.285,.080,.34),"fabric")
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(m("cream"))
	for major in 36:
		for minor in 8:
			var points:Array[Vector3]=[]
			for uv:Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var a:float=(major+uv.x)*TAU/36
				var b_angle:float=(minor+uv.y)*TAU/8
				var raised:float=(1.0-cos(a))*.5
				var tube:float=.024+raised*.016
				points.append(Vector3(sin(a)*(.145+cos(b_angle)*tube),.075+raised*.045+sin(b_angle)*tube,cos(a)*(.17+cos(b_angle)*tube)))
			for index in [0,2,1,0,3,2]:
				st.set_uv(Vector2(points[index].x,points[index].z))
				st.add_vertex(points[index])
	st.generate_normals()
	var bolster:=MeshInstance3D.new()
	bolster.name="SoftCatBolster"
	bolster.mesh=st.commit()
	add_child(bolster)
	RoomGeo.collider(self,"CatBedCollision",Vector3(0,.055,0),Vector3(.3534,.11,.4166))

extends Node3D
## Phase 01 state. World interactions dispatch here, lights have one owner.
const Audio = preload("res://scripts/audio/room_audio.gd")
@onready var player: CharacterBody3D = $Player
@onready var ui = $UI
@onready var lighting = $Lighting
var audio: Node
var step_number := 0
var bowl_filled := false
var blanket_folded := false
var fish_fed := false

func _enter_tree() -> void:
	var keys := {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"interact":KEY_E,"pause":KEY_ESCAPE,"day_night":KEY_F6}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = keys[action]
			InputMap.action_add_event(action,key)

func _ready() -> void:
	audio = Audio.new()
	audio.name = "RoomAudio"
	add_child(audio)
	player.footstep.connect(_on_footstep)
	ui.aquarium_fed.connect(_feed_fish)
	ui.set_mode(lighting.is_night)
	ui.notify("Về nhà rồi. Khám phá căn phòng · E để tương tác · F6 đổi ngày / đêm")
	audio.add_loop("fan",$Room,$Room/StandingFan.position+Vector3.UP*.9,-34)
	audio.add_loop("pc",$Room,Vector3(3.1867,.35,-5.0382),-37)
	audio.add_loop("aquarium",$Room,$Room/Aquarium.position+Vector3.UP*.2,-36)
	# Aquarium focus remains a camera-only modal; player collider never teleports.
	for target in get_tree().get_nodes_in_group("interactable"):
		if target.action == "aquarium":
			target.set_meta("focus_point",Vector3(2.72,1.18,-4.9886))
			target.set_meta("look_at_point",Vector3(3.412,1.02,-4.9886))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("day_night"):
		lighting.toggle_day()
		ui.set_mode(lighting.is_night)
		ui.notify("19:50 · Đèn bếp và đèn phòng có công tắc riêng" if lighting.is_night else "07:50 · Ánh sáng ban ngày")
		get_viewport().set_input_as_handled()

func handle_interaction(target: Node) -> void:
	if not player.controls_enabled:
		return
	match target.action:
		"pc":
			ui.open_pc(target.payload if not target.payload.is_empty() else "Máy tính 01",player)
		"light":
			lighting.toggle_circuit(target.payload)
			audio.play_at("switch",target.global_position,-22)
			ui.notify(target.title + (" · Bật" if lighting.circuits.get(target.payload,false) else " · Tắt"))
		"door":
			var door = target.get_meta("door_root",null)
			if door != null and door.try_toggle(player):
				audio.play_at("door" if door.is_open else "door_close",door.global_position,-23)
				ui.notify(door.door_title + (" · Đã mở" if door.is_open else " · Đã đóng"))
			else:
				ui.notify("Lùi một bước để chừa khoảng mở cửa.")
		"aquarium":
			ui.open_aquarium(target,player)
		"bowl":
			bowl_filled = not bowl_filled
			var food := target.get_parent().find_child("Food",true,false)
			if food != null:
				food.visible = bowl_filled
			ui.notify("Đã đặt thức ăn cho Bống." if bowl_filled else "Đã dọn bát cho Bống.")
		"bed":
			blanket_folded = not blanket_folded
			var blanket := target.get_parent().find_child("Blanket",true,false)
			if blanket != null:
				blanket.scale.z = 0.52 if blanket_folded else 1.0
			ui.notify("Chăn đã gấp gọn. Bống lại có chỗ nằm." if blanket_folded else "Đã trải lại chăn.")
		_:
			ui.notify(target.title)

func _feed_fish(_target: Node) -> void:
	fish_fed = true
	ui.notify("Một nhúm nhỏ là đủ. Cá đã được cho ăn.")

func _on_footstep(surface: String, where: Vector3) -> void:
	step_number = 1-step_number
	audio.play_at("step_"+surface+"_"+str(step_number+1),where,-24)

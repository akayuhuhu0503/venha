extends CanvasLayer
class_name RoomUI

signal aquarium_fed(target: Node)
signal modal_closed

const INK: Color = Color("111d22")
const PAPER: Color = Color("e9ece5")
const MUTED: Color = Color("9daea9")
const ACCENT: Color = Color("c5db97")

var modal_kind: String = ""
var _root: Control
var _hud: Control
var _mode_label: Label
var _prompt: Label
var _toast: Label
var _toast_time: float = 0.0
var _modal: Control
var _active_player: Node3D
var _saved_transform: Transform3D
var _saved_head_rotation: Vector3
var _saved_camera_transform: Transform3D
var _camera_tween: Tween
var _desktop_content: VBoxContainer
var _night: bool = false
var _last_fed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.theme = _make_theme()
	_build_hud()

func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = minf(1.0, _toast_time * 2.0)
		_toast.visible = _toast_time > 0.0

func _input(event: InputEvent) -> void:
	if not modal_kind.is_empty() and event.is_action_pressed("pause"):
		close_modal()
		get_viewport().set_input_as_handled()

func _make_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_hover_color", "Button", ACCENT)
	theme.set_color("font_focus_color", "Button", ACCENT)
	theme.set_stylebox("normal", "Button", _style(Color("213339"), 8, Color("3c5154")))
	theme.set_stylebox("hover", "Button", _style(Color("30474a"), 8, ACCENT))
	theme.set_stylebox("pressed", "Button", _style(Color("172a2d"), 8, ACCENT))
	theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), 8, ACCENT))
	return theme

func _style(color: Color, radius: int = 10, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(text: String, size: int = 17, color: Color = PAPER) -> Label:
	var item: Label = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func _paragraph(text: String, size: int = 18, color: Color = PAPER) -> Label:
	var item: Label = _label(text, size, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func _button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 46
	button.pressed.connect(callback)
	return button

func _space(parent: Node, height: float) -> void:
	var space: Control = Control.new()
	space.custom_minimum_size.y = height
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(space)

func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hud)
	var identity: VBoxContainer = VBoxContainer.new()
	identity.position = Vector2(32, 24)
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(identity)
	var title: Label = _label("7:50  /  VỀ NHÀ", 25)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	identity.add_child(title)
	identity.add_child(_label("CĂN PHÒNG  ·  v0.5", 12, Color("ccd2c5")))
	_mode_label = _label("BAN NGÀY  /  F6", 13)
	_mode_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_mode_label.offset_left = -230
	_mode_label.offset_right = -32
	_mode_label.offset_top = 30
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.add_child(_mode_label)
	var crosshair: Label = _label("·", 32)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5, 23)
	crosshair.add_theme_color_override("font_shadow_color", Color.BLACK)
	crosshair.add_theme_constant_override("shadow_offset_y", 1)
	_hud.add_child(crosshair)
	_prompt = _label("", 19)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -350
	_prompt.offset_right = 350
	_prompt.offset_top = -137
	_prompt.offset_bottom = -100
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_hud.add_child(_prompt)
	var keys: Label = _label("W A S D  Di chuyển     SHIFT  Chạy     CTRL  Ngồi     E  Tương tác     ESC  Menu", 13)
	keys.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	keys.offset_left = -510
	keys.offset_right = 510
	keys.offset_top = -39
	keys.offset_bottom = -15
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_color_override("font_shadow_color", Color.BLACK)
	keys.add_theme_constant_override("shadow_offset_y", 2)
	_hud.add_child(keys)
	_toast = _label("", 18, ACCENT)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -470
	_toast.offset_right = 470
	_toast.offset_top = -92
	_toast.offset_bottom = -55
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_shadow_color", Color.BLACK)
	_toast.add_theme_constant_override("shadow_offset_y", 2)
	_toast.visible = false
	_root.add_child(_toast)

func set_prompt(text: String) -> void:
	if _prompt != null:
		_prompt.text = text

func notify(text: String) -> void:
	if _toast != null:
		_toast.text = text
		_toast.visible = true
		_toast.modulate.a = 1.0
		_toast_time = 4.0
		_root.move_child(_toast, _root.get_child_count() - 1)

func set_mode(is_night: bool) -> void:
	_night = is_night
	if _mode_label != null:
		_mode_label.text = ("BAN ĐÊM" if is_night else "BAN NGÀY") + "  /  F6"

func _begin_modal(kind: String, player: Node3D, opacity: float = 0.65) -> void:
	if not modal_kind.is_empty():
		close_modal()
	modal_kind = kind
	_active_player = player
	_saved_transform = player.global_transform
	var player_head: Node3D = player.get_node("Head") as Node3D
	_saved_head_rotation = player_head.rotation
	var player_camera: Camera3D = player.get("camera") as Camera3D
	_saved_camera_transform = player_camera.transform
	player.call("set_control_enabled", false)
	_hud.visible = false
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_modal)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.025, opacity)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(shade)

func _panel(left: float, top: float, right: float, bottom: float) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = left
	panel.anchor_top = top
	panel.anchor_right = right
	panel.anchor_bottom = bottom
	panel.add_theme_stylebox_override("panel", _style(INK, 14, Color("52645c")))
	_modal.add_child(panel)
	return panel

func open_pc(pc_name: String, player: Node3D) -> void:
	_begin_modal("pc", player, 0.80)
	var desktop: PanelContainer = _panel(0.08, 0.07, 0.92, 0.91)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	desktop.add_child(layout)
	var bar: HBoxContainer = HBoxContainer.new()
	layout.add_child(bar)
	var pc_title: Label = _label("VỀ NHÀ  /  " + pc_name.to_upper(), 14, ACCENT)
	pc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(pc_title)
	bar.add_child(_label("07:50" if not _night else "19:50", 17))
	bar.add_child(_button("Thoát  [Esc]", close_modal))
	layout.add_child(HSeparator.new())
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 28)
	layout.add_child(body)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 182
	sidebar.add_theme_constant_override("separation", 12)
	body.add_child(sidebar)
	sidebar.add_child(_label("GÓC LÀM VIỆC", 12, MUTED))
	sidebar.add_child(_button("Trang chủ", _desktop_home))
	sidebar.add_child(_button("Ghi chú", _desktop_notes))
	sidebar.add_child(_button("Bể cá nhỏ", _desktop_aquarium))
	_space(sidebar, 28)
	sidebar.add_child(_paragraph("Ba người.\nMột căn phòng.\nMột nơi để trở về.", 14, MUTED))
	var content_panel: PanelContainer = PanelContainer.new()
	content_panel.add_theme_stylebox_override("panel", _style(Color("1a2b30"), 12))
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content_panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.add_child(scroll)
	_desktop_content = VBoxContainer.new()
	_desktop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_desktop_content.add_theme_constant_override("separation", 16)
	scroll.add_child(_desktop_content)
	layout.add_child(_label("DESKTOP MÔ PHỎNG     •     Dùng chuột để mở ứng dụng     •     Esc trở lại căn phòng", 13, MUTED))
	_desktop_home()

func _clear_desktop() -> void:
	for child in _desktop_content.get_children():
		_desktop_content.remove_child(child)
		child.queue_free()

func _desktop_home() -> void:
	_clear_desktop()
	_space(_desktop_content, 10)
	_desktop_content.add_child(_label("Chào mừng về nhà.", 32))
	_desktop_content.add_child(_paragraph("Đặt túi xuống, bật máy tính. Một buổi tối bình thường trong căn phòng nhỏ ở Hà Nội.", 19, MUTED))
	_space(_desktop_content, 18)
	_desktop_content.add_child(_label("HÔM NAY", 13, ACCENT))
	_desktop_content.add_child(_paragraph("•  Cho Bống ăn.\n•  Kiểm tra bể cá cạnh màn hình.\n•  Gấp chăn trên gác.\n•  Nhớ tắt đèn bếp khi không dùng.", 20))
	_space(_desktop_content, 14)
	_desktop_content.add_child(_button("Mở ghi chú trong phòng", _desktop_notes))

func _desktop_notes() -> void:
	_clear_desktop()
	_desktop_content.add_child(_label("Ghi chú", 32))
	_desktop_content.add_child(_label("NHỮNG VIỆC RẤT NHỎ", 12, ACCENT))
	_desktop_content.add_child(_paragraph("Bống thích nằm ở góc khuất trên gác. Bát ăn đặt gần tủ gỗ.\n\nCông tắc cạnh bếp chỉ điều khiển đèn bếp; ban đêm vẫn để ánh sáng ở khu máy tính để thấy lối đi.\n\nHôm nay đã dọn bớt đồ dưới sàn. Cầu thang thoáng hơn rồi.", 20))
	_desktop_content.add_child(_paragraph("7:50 — Về nhà\nCăn phòng / v0.5", 14, MUTED))

func _desktop_aquarium() -> void:
	_clear_desktop()
	_desktop_content.add_child(_label("Bể cá nhỏ", 32))
	_desktop_content.add_child(_label("CHĂM SÓC HẰNG NGÀY", 12, ACCENT))
	_desktop_content.add_child(_paragraph("Máy lọc đang hoạt động.\nĐèn bể cá được bật cùng khu sinh hoạt.\n\nĐến gần bể và nhấn E để quan sát, sau đó cho một ít thức ăn.", 20))
	_desktop_content.add_child(_paragraph("Ghi chú chăm sóc minh họa; chưa mô phỏng chất lượng nước.", 14, MUTED))

func open_aquarium(target: Node3D, player: Node3D) -> void:
	_begin_modal("aquarium", player, 0.13)
	var player_camera: Camera3D = player.get("camera") as Camera3D
	# Optional metadata specifies an authored observation pose in WORLD space:
	# focus_point = camera location; look_at_point = tank center.
	var look_at_point: Vector3 = target.global_position
	if target.has_meta("look_at_point"):
		look_at_point = target.get_meta("look_at_point") as Vector3
	var direction: Vector3 = (player_camera.global_position - look_at_point).normalized()
	var focus_point: Vector3 = look_at_point + direction * 0.72
	if target.has_meta("focus_point"):
		focus_point = target.get_meta("focus_point") as Vector3
	var observation_pose: Transform3D = Transform3D(Basis.looking_at(look_at_point - focus_point, Vector3.UP), focus_point)
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(player_camera, "global_transform", observation_pose, 0.35)
	var panel: PanelContainer = _panel(0.63, 0.21, 0.95, 0.78)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	panel.add_child(layout)
	layout.add_child(_label("BỂ CÁ NHỎ", 12, ACCENT))
	layout.add_child(_label("Một góc yên tĩnh", 25))
	layout.add_child(_paragraph("Tiếng lọc nước rất khẽ.\nMột ít thức ăn là đủ rồi.", 18, MUTED))
	_space(layout, 8)
	var feed_button: Button = _button("Cho cá ăn", func() -> void:
		_last_fed = true
		aquarium_fed.emit(target)
		notify("Đã rắc một ít thức ăn vào bể.")
	)
	feed_button.pressed.connect(func() -> void:
		feed_button.disabled = true
		feed_button.text = "Đã cho ăn"
	)
	layout.add_child(feed_button)
	layout.add_child(_button("Trở lại  [Esc]", close_modal))

func toggle_pause(player: Node3D) -> void:
	if not modal_kind.is_empty():
		close_modal()
		return
	_begin_modal("pause", player, 0.75)
	get_tree().paused = true
	var panel: PanelContainer = _panel(0.29, 0.10, 0.71, 0.90)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 13)
	panel.add_child(layout)
	layout.add_child(_label("7:50  /  VỀ NHÀ", 29))
	layout.add_child(_label("TẠM DỪNG", 13, ACCENT))
	_space(layout, 10)
	layout.add_child(_button("Tiếp tục  [Esc]", close_modal))
	layout.add_child(_label("Độ nhạy chuột", 15, MUTED))
	var sensitivity: HSlider = HSlider.new()
	sensitivity.min_value = 0.0008
	sensitivity.max_value = 0.005
	sensitivity.step = 0.0001
	sensitivity.value = float(player.get("mouse_sensitivity"))
	sensitivity.custom_minimum_size.y = 28
	sensitivity.value_changed.connect(func(value: float) -> void: player.set("mouse_sensitivity", value))
	layout.add_child(sensitivity)
	var camera: Camera3D = player.get("camera") as Camera3D
	var fov_label := _label("Góc nhìn  ·  %d°" % camera.fov,15,MUTED)
	layout.add_child(fov_label)
	var fov_slider := HSlider.new()
	fov_slider.min_value = 75
	fov_slider.max_value = 85
	fov_slider.step = 1
	fov_slider.value = camera.fov
	fov_slider.custom_minimum_size.y = 28
	fov_slider.value_changed.connect(func(value: float) -> void:
		camera.fov = value
		fov_label.text = "Góc nhìn  ·  %d°" % value
	)
	layout.add_child(fov_slider)
	layout.add_child(_paragraph("WASD  Di chuyển · Shift  Chạy\nCtrl  Ngồi · E  Tương tác\nF6  Chuyển ngày / đêm", 15, MUTED))
	_space(layout, 7)
	layout.add_child(_button("Thoát game", func() -> void: get_tree().quit()))

func close_modal() -> void:
	if modal_kind.is_empty():
		return
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	if modal_kind == "pause":
		get_tree().paused = false
	modal_kind = ""
	if is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	if is_instance_valid(_active_player):
		_active_player.global_transform = _saved_transform
		var player_head: Node3D = _active_player.get_node("Head") as Node3D
		player_head.rotation = _saved_head_rotation
		var player_camera: Camera3D = _active_player.get("camera") as Camera3D
		player_camera.transform = _saved_camera_transform
		_active_player.call("set_control_enabled", true)
	_active_player = null
	_hud.visible = true
	modal_closed.emit()

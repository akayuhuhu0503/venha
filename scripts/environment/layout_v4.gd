@tool
extends Resource
class_name RoomLayoutV4
## Source (x, depth, height) -> Godot (x, height, -depth), 1 unit = 1 metre.
## These four dimensions remain provisional, not new measured facts.
@export var ceiling_height: float = 4.15
@export var loft_surface: float = 2.2805
@export var bathroom_depth: float = 2.21
@export var bathroom_width: float = 1.18
const SOURCE := "res://assets/layout/room_v4/7150_ROOM_LAYOUT_SOURCE.json"
const OUTLINE := [Vector2(-.47,0), Vector2(1.54,0), Vector2(1.54,2.955), Vector2(3.75,2.955), Vector2(3.75,5.435), Vector2(0,5.435), Vector2(0,1.25), Vector2(-.47,1.25)]
var source: Dictionary = {}

func read_source() -> void:
	if source.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
		if parsed is Dictionary:
			source = parsed
		else:
			push_error("Missing or invalid authoritative v4 layout JSON")

static func point(x: float, depth: float, height: float = 0.0) -> Vector3:
	return Vector3(x, height, -depth)

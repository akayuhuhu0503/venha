extends StaticBody3D
class_name RoomInteractable

## One reusable interaction endpoint; the main scene owns game state.
signal activated(target: RoomInteractable)

@export var action: String = ""
@export var title: String = "Tương tác"
@export var payload: String = ""
@export var enabled: bool = true

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0

func get_prompt() -> String:
	return "[E]  " + title if enabled else ""

func interact(_player: Node) -> void:
	if not enabled:
		return
	activated.emit(self)
	var game: Node = get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("handle_interaction"):
		game.call("handle_interaction", self)

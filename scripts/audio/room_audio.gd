class_name RoomAudio
extends Node
## Original synthesized spatial audio. All positions for play_at are world-space;
## positions for add_loop are local to its supplied parent.

const SOUND_NAMES := [
	"step_tile_1", "step_tile_2", "step_wood_1", "step_wood_2",
	"door", "door_close", "switch", "fan", "pc", "aquarium"
]
var _streams: Dictionary = {}
var _loop_streams: Dictionary = {}
var _transients: Array[AudioStreamPlayer3D] = []
var _loops: Array[AudioStreamPlayer3D] = []


func _exit_tree() -> void:
	# Loop players belong to their furniture, so detach their playback explicitly
	# before the scene/audio server shuts down (also covers the headless driver).
	for source in _loops + _transients:
		_release_player(source)
	_loops.clear()
	_transients.clear()
	_loop_streams.clear()
	_streams.clear()


func _release_player(source: AudioStreamPlayer3D) -> void:
	if is_instance_valid(source):
		source.stop()
		source.stream = null


func get_stream(sound: String) -> AudioStreamWAV:
	if not SOUND_NAMES.has(sound):
		push_warning("Unknown room sound: " + sound)
		return null
	if not _streams.has(sound):
		_streams[sound] = load("res://assets/audio/%s.wav" % sound) as AudioStreamWAV
	return _streams[sound] as AudioStreamWAV


func play_at(sound: String, pos: Vector3, volume_db: float = -18.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream := get_stream(sound)
	if stream == null:
		return
	# Bound simultaneous transients even if multiple triggers fire in one frame.
	_transients = _transients.filter(func(item: AudioStreamPlayer3D) -> bool: return is_instance_valid(item))
	if _transients.size() >= 16:
		var oldest: AudioStreamPlayer3D = _transients.pop_front()
		oldest.queue_free()
	var source := _make_player(stream, volume_db)
	add_child(source)
	source.global_position = pos
	_transients.append(source)
	source.finished.connect(source.queue_free)
	source.play()


func add_loop(sound: String, parent: Node3D, pos: Vector3, volume_db: float = -30.0) -> AudioStreamPlayer3D:
	var stream := get_stream(sound)
	if stream == null:
		return null
	if not _loop_streams.has(sound):
		var loop_stream := stream.duplicate() as AudioStreamWAV
		loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop_stream.loop_begin = 0
		loop_stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
		_loop_streams[sound] = loop_stream
	var source := _make_player(_loop_streams[sound] as AudioStreamWAV, volume_db)
	source.name = sound.capitalize() + "Audio"
	parent.add_child(source)
	source.position = pos
	_loops.append(source)
	source.tree_exiting.connect(_release_player.bind(source), CONNECT_ONE_SHOT)
	# The headless dummy driver has no audible output and can retain endless
	# WAV voices until shutdown. Keep the emitter available without starting it.
	if DisplayServer.get_name() != "headless":
		source.play()
	return source


func _make_player(stream: AudioStreamWAV, volume_db: float) -> AudioStreamPlayer3D:
	var source := AudioStreamPlayer3D.new()
	source.stream = stream
	source.volume_db = volume_db
	source.unit_size = 1.4
	source.max_distance = 12.0
	source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	source.max_db = 0.0
	return source

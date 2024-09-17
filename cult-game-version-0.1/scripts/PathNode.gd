class_name PathNode extends Node2D

@export var is_start_of_path:bool = false;
@export var next_nodes_pool:Array[PathNode] = [];

func _ready() -> void:
	if !multiplayer.is_server(): queue_free()
	add_to_group("path_node")
	if is_start_of_path: add_to_group("path_start_node")
	process_mode = PROCESS_MODE_DISABLED

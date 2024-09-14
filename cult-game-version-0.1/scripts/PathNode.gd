class_name PathNode extends Node2D

@export var next_nodes_pool:Array[PathNode] = [];

func _ready() -> void:
	if !multiplayer.is_server(): queue_free()

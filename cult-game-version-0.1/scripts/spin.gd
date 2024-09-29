extends Node2D

@export var velocity:float = 1

func _process(delta:float) -> void:
	rotation += velocity * delta

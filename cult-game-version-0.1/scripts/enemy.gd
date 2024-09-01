extends CharacterBody2D

@export var speed = 100
@export var accel = 10
var player_pos
var target_pos
@onready var player = get_parent().get_node("player")

func _process(_delta: float) -> void:
	var direction = ( player.global_position - self.global_position ).normalized()
	
	velocity.x = move_toward(velocity.x, speed * direction.x, accel)
	velocity.y = move_toward(velocity.y, speed * direction.y, accel)
	
	move_and_slide()

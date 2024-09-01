extends CharacterBody2D

@export var speed:float = 400
@export var accel:float = 7
var player_pos
var target_pos
@onready var player = get_parent().get_node("player")

func _process(delta: float) -> void:
	var direction = ( player.global_position - self.global_position ).normalized()
	
	velocity.x = move_toward(velocity.x / speed, direction.x, accel * delta) * speed
	velocity.y = move_toward(velocity.y / speed, direction.y, accel * delta) * speed
	
	move_and_slide()

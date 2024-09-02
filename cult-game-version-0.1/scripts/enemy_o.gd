extends CharacterBody2D

@export var speed:float = 150
@export var accel:float = 7
var player_pos
var target_pos
@onready var player = get_parent().get_node("player")

@export var navAgent:NavigationAgent2D;

func _process(delta: float) -> void:
	navAgent.target_position = player.global_position;
	var direction = global_position.direction_to(navAgent.get_next_path_position());
	#( player.global_position - self.global_position ).normalized()
	
	velocity.x = move_toward(velocity.x / speed, direction.x, accel * delta) * speed
	velocity.y = move_toward(velocity.y / speed, direction.y, accel * delta) * speed
	
	move_and_slide()

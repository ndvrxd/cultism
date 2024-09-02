extends CharacterBody2D

@export var speed:float = 400
@export var accel:float = 7

#@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D


#NOTE: Most fucking tutorials say use "physics_process" but use just _process to
#      avoid stupid ass camera smoothing "jittering" bugs, idk i think it treats it like a phys prop 
func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	
	velocity.x = move_toward(velocity.x / speed, direction.x, accel * delta) * speed
	velocity.y = move_toward(velocity.y / speed, direction.y, accel * delta) * speed
	
	move_and_slide()

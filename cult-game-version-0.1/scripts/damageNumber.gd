extends Node2D

@export var maxLifetime:float
var vel:Vector2
var age:float

func set_number(t):
	$Label.text = str(t)

func set_color(c:Color):
	$Label.modulate = c

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vel = Vector2(randf_range(-100, 100), -500)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += vel * delta
	vel.y += 1200 * delta
	age += delta
	$Label.scale.y = min(1, (maxLifetime-age)/0.1)
	if age > maxLifetime: queue_free()

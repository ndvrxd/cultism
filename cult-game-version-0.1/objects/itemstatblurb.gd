extends Label

func _ready() -> void:
	pivot_offset = size/2
	global_position -= size / 2

func _process(delta: float) -> void:
	position.y -= 20 * delta
	modulate.a = $Timer.time_left / ($Timer.wait_time-0.3)

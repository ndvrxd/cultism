extends Camera2D

@export var rate:float = 0.1
const refreshRate:float = 2
var refreshTimer:float = refreshRate - 0.1
var sprites;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	if Input.is_action_pressed("CameraTiltUp"):
		zoom.y += rate * delta
		for s:Node2D in sprites:
			s.scale.y = 1 / zoom.y;
	if Input.is_action_pressed("CameraTiltDown"):
		zoom.y -= rate * delta
		for s:Node2D in sprites:
			s.scale.y = 1 / zoom.y;
	

func _physics_process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	refreshTimer += delta;
	if refreshTimer > refreshRate:
		sprites = get_tree().get_nodes_in_group("upright_sprite")
		for s:Node2D in sprites:
			s.scale.y = 1 / zoom.y;

extends Camera2D

@export var rate:float = 0.5
const refreshRate:float = 2
var refreshTimer:float = refreshRate - 0.1
var sprites;
var tilting:bool=false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	tilting=false
	if Input.is_action_pressed("CameraTiltUp"):
		zoom.y += rate * delta; tilting = true
	if Input.is_action_pressed("CameraTiltDown"):
		zoom.y -= rate * delta; tilting = true
	if tilting:
		if clampf(zoom.y, 0.4, 1) == zoom.y:
			sprites = get_tree().get_nodes_in_group("upright_sprite") #this is bad but it fixes a crash
			for s:Node2D in sprites:
				s.scale.y = 1 / zoom.y;
		zoom.y = clampf(zoom.y, 0.4, 1)
	

func _physics_process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	refreshTimer += delta;
	if refreshTimer > refreshRate:
		# if theres a new sprite that hasnt been scaled yet, scale it.
		# check for that every couple of seconds
		sprites = get_tree().get_nodes_in_group("upright_sprite") 
		for s:Node2D in sprites:
			s.scale.y = 1 / zoom.y;

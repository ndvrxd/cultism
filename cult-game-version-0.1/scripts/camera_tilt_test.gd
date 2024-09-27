extends Camera2D

@export var rate:float = 0.5
const refreshRate:float = 0.3
var refreshTimer:float = refreshRate - 0.1
var sprites;
var tilting:bool=false;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	tilting=false
	#CHANGE THIS TO Input.is_action_pressed IF KEY/CLICK INPUT, 
	#OR Input.is_action_just_pressed IF SCROLL WHEEL 
	#also da 1 is 
	# -ndvr :3
	if !Chatbox.isFocused:
		if Input.is_action_pressed("CameraTiltUp"):
			zoom.y += rate * delta * 1; tilting = true
		if Input.is_action_pressed("CameraTiltDown"):
			zoom.y -= rate * delta * 1; tilting = true
		if Input.is_action_just_pressed("CameraTiltUpImpulse"):
			zoom.y += rate * 0.055; tilting = true
		if Input.is_action_just_pressed("CameraTiltDownImpulse"):
			zoom.y -= rate * 0.055; tilting = true
	if tilting:
		if clampf(zoom.y, 0.4, 1) == zoom.y:
			sprites = get_tree().get_nodes_in_group("upright_sprite")
			for s:Node2D in sprites:
				s.scale.y = 1 / zoom.y;
		zoom.y = clampf(zoom.y, 0.4, 1)

func _physics_process(delta: float) -> void:
	if NetManager.IsDedicated(): return
	sprites = get_tree().get_nodes_in_group("upright_sprite") 
	for s:Node2D in sprites:
		s.scale.y = 1 / zoom.y;

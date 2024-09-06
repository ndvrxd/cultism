extends EntityController

var direction:Vector2
var mouseLookMode = true
var lastMousePos:Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");
	ent.moveIntent = direction
	
	var cameraStickDir = Input.get_vector("LookLeft", "LookRight", "LookUp", "LookDown").normalized();
	if mouseLookMode:
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(get_global_mouse_position())
		if cameraStickDir != Vector2.ZERO: mouseLookMode = false
	else:
		ent.lookDirection = ent.lookDirection.lerp(cameraStickDir, 20*delta)
		if Input.get_last_mouse_velocity().length() > 0: mouseLookMode = true

func _process(_delta):
	if Input.is_action_just_pressed("PrimaryAttack"):
		ent.primaryFire.rpc(get_global_mouse_position())
	if Input.is_action_just_pressed("SecondaryAttack"):
		ent.secondaryFire.rpc(get_global_mouse_position())
	if Input.is_action_just_released("PrimaryAttack"):
		ent.primaryFireReleased.rpc(get_global_mouse_position())
	if Input.is_action_just_released("SecondaryAttack"):
		ent.secondaryFireReleased.rpc(get_global_mouse_position())
	if Input.is_action_just_pressed("SpecialAbility"):
		ent.activeAbility.rpc(get_global_mouse_position())

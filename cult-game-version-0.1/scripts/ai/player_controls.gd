extends EntityController

var direction:Vector2
var mouseLookMode = true

var controllerAimLength:float = 0
var controllerAimMinimum:float = 100
var controllerAimMaximum:float = 600
var controllerAimSpeed:float = 400
var lastStickDir:Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");
	ent.moveIntent = direction
	
	var cameraStickDir = Input.get_vector("LookLeft", "LookRight", "LookUp", "LookDown").normalized();
	if mouseLookMode:
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(get_global_mouse_position())
		ent.aimPosition = get_global_mouse_position()
		if cameraStickDir != Vector2.ZERO: mouseLookMode = false
	else:
		if cameraStickDir.length() > 0:
			controllerAimLength += controllerAimSpeed * cameraStickDir.length() * delta
			controllerAimLength = clampf(controllerAimLength /
					(1 + lastStickDir.distance_to(cameraStickDir) * 0.4),
					0, controllerAimMaximum)
		ent.aimPosition = ent.global_position + ent.lookDirection * \
				(controllerAimMinimum + controllerAimLength)
		if cameraStickDir.distance_to(-ent.lookDirection) > 1:
			ent.lookDirection = ent.lookDirection.lerp(cameraStickDir, 20*delta)
		elif cameraStickDir.length()>0:
			ent.lookDirection = cameraStickDir
		lastStickDir = cameraStickDir
		if Input.get_last_mouse_velocity().length() > 0: mouseLookMode = true

func _process(_delta):
	if Input.is_action_just_pressed("PrimaryAttack"):
		ent.primaryFire.rpc(ent.aimPosition)
	if Input.is_action_just_pressed("SecondaryAttack"):
		ent.secondaryFire.rpc(ent.aimPosition)
	if Input.is_action_just_released("PrimaryAttack"):
		ent.primaryFireReleased.rpc(ent.aimPosition)
	if Input.is_action_just_released("SecondaryAttack"):
		ent.secondaryFireReleased.rpc(ent.aimPosition)
	if Input.is_action_just_pressed("SpecialAbility"):
		ent.activeAbilityRpc.rpc(ent.aimPosition)

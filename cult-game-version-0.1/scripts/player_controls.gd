extends EntityController

var direction:Vector2

func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");
	ent.moveIntent = direction
	
	ent.lookDirection = ent.shoulderPoint.global_position.direction_to(get_global_mouse_position())

func _process(_delta):
	if Input.is_action_just_pressed("PrimaryAttack"):
		ent.primaryFire.rpc(get_global_mouse_position())
	if Input.is_action_just_pressed("SecondaryAttack"):
		ent.secondaryFire.rpc(get_global_mouse_position())
	if Input.is_action_just_pressed("SpecialAbility"):
		ent.activeAbility.rpc(get_global_mouse_position())

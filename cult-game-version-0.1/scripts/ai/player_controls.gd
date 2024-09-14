extends EntityController

var direction:Vector2
var mouseLookMode = true

@onready var ui_hb_over:TextureProgressBar = $"HUD STUFF/healthbar_under/healthbar_over"
@onready var ui_hb_under:TextureProgressBar = $"HUD STUFF/healthbar_under"
@onready var ui_hb_text:Label = $"HUD STUFF/healthbar_under/Label"
@onready var ui_active_cd:TextureProgressBar = $"HUD STUFF/active/cooldown"
var vignetteTween:Tween

var controllerAimLength:float = 0
var controllerAimMinimum:float = 100
var controllerAimMaximum:float = 600
var controllerAimSpeed:float = 400
var lastStickDir:Vector2 = Vector2.ZERO

func _ready():
	super._ready()
	ui_hb_over.tint_progress = ent.healthBarColor
	ent.damage_taken.connect(damageVignette)
	$"HUD STUFF/vignette".modulate = Color(Color.RED, 0)

func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");
	ent.moveIntent = direction if !Chatbox.isFocused else Vector2.ZERO
	
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
			controllerAimLength = 0
		lastStickDir = cameraStickDir
		if Input.get_last_mouse_velocity().length() > 0: mouseLookMode = true

func _process(delta):
	#region hud stuff
	ui_hb_over.value = (ent.health / ent.stat_maxHp.val)
	ui_hb_under.value = lerp(ui_hb_under.value, ui_hb_over.value, delta*7)
	ui_hb_text.text = str(int(ent.health)) + " / " + str(int(ent.stat_maxHp.val))
	ui_active_cd.value = 1 - ent.activeTimer / ent.activeCD
	#endregion
	
	#region input stuff
	if !Chatbox.isFocused:
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
		if Input.is_action_just_pressed("Interact"):
			ent.interact()
	#endregion

func damageVignette(dmg_amt, from):
	var proportion = dmg_amt / ent.stat_maxHp.val
	if proportion < $"HUD STUFF/vignette".modulate.a: return
	$"HUD STUFF/vignette".modulate = Color(Color.RED, proportion)
	if vignetteTween and is_instance_valid(vignetteTween):
		vignetteTween.kill()
	vignetteTween = get_tree().create_tween()
	vignetteTween.tween_property($"HUD STUFF/vignette", "modulate",
			Color(Color.RED, 0), 1 + proportion)

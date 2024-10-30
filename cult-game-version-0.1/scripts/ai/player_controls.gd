extends EntityController

var direction:Vector2
var mouseLookMode = true

@onready var ui_hb_over:TextureProgressBar = $"HUD STUFF/healthbar_under/healthbar_over"
@onready var ui_hb_under:TextureProgressBar = $"HUD STUFF/healthbar_under"
@onready var ui_hb_text:Label = $"HUD STUFF/healthbar_under/Label"
var vignetteTween:Tween

const spectatorBody:String = "res://objects/characters/spectator.tscn"
var statusEffectIcon = preload("res://objects/statusEffectIcon.tscn")

var controllerAimLength:float = 0
var controllerAimMinimum:float = 100
var controllerAimMaximum:float = 600
var controllerAimSpeed:float = 400
var lastStickDir:Vector2 = Vector2.ZERO

# for time elapsed
var seconds: float = 0.0
var minutes: int = 0

func _ready():
	super._ready()
	ui_hb_over.tint_progress = ent.healthBarColor
	ent.damage_taken.connect(damageVignette)
	$"HUD STUFF/vignette".modulate = Color(Color.RED, 0)
	ent.killed.connect(spectate)
	ent.effect_added.connect(_on_status_effect_added)
	ent.item_acquired.connect(_on_item_acquired)
	$"HUD STUFF/itemdialog".visible = false
	Chatbox.inst.set_username(ent.entityName)
	if ent.abilities.size() > 0 and is_instance_valid(ent.abilities[0]): 
		$"HUD STUFF/primaryIcon".set_ability(ent.abilities[0])
	if ent.abilities.size() > 1 and is_instance_valid(ent.abilities[1]): 
		$"HUD STUFF/secondaryIcon".set_ability(ent.abilities[1])
	if ent.abilities.size() > 2 and is_instance_valid(ent.abilities[2]): 
		$"HUD STUFF/specialIcon".set_ability(ent.abilities[2])
	if ent.abilities.size() > 3 and is_instance_valid(ent.abilities[3]): 
		$"HUD STUFF/meowButton".set_ability(ent.abilities[3])

func spectate(killedBy:Entity):
	var ename:String = ent.name
	Chatbox.inst.print_chat.rpc("* " + ename + " was killed by " + killedBy.entityName + ".")
	var epos:Vector2 = ent.global_position
	reparent(get_tree().current_scene)
	global_position = ent.global_position
	await get_tree().create_timer(0.1).timeout
	Entity.spawn(spectatorBody, epos, '', ename)
	await get_tree().create_timer(0.1).timeout
	queue_free()
	
	#var newEnt: Entity = get_tree().current_scene.get_node(ename)
	#reparent(newEnt)
	#attemptControl.call_deferred()

func _physics_process(delta: float) -> void:
	if !is_instance_valid(ent): return
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
		
	if !Chatbox.isFocused:
		if Input.is_action_just_pressed("Interact"):
			ent.interact()

func _process(delta):
	if !is_instance_valid(ent): return
	#region hud stuff
	ui_hb_over.value = (ent.health / ent.stat_maxHp.val)
	ui_hb_under.value = lerp(ui_hb_under.value, ui_hb_over.value, delta*7)
	ui_hb_text.text = str(int(ent.health)) + " / " + str(int(ent.stat_maxHp.val))
	$shoulder.transform = ent.shoulderPoint.transform
	#endregion
	
	#region input stuff
	if !Chatbox.isFocused:
		if Input.is_action_just_pressed("PrimaryAttack"):
			ent.setAbilityPressed.rpc(0, true)
		if Input.is_action_just_released("PrimaryAttack"):
			ent.setAbilityPressed.rpc(0, false)
		if Input.is_action_just_pressed("SecondaryAttack"):
			ent.setAbilityPressed.rpc(1, true)
		if Input.is_action_just_released("SecondaryAttack"):
			ent.setAbilityPressed.rpc(1, false)
		if Input.is_action_just_pressed("SpecialAbility"):
			ent.setAbilityPressed.rpc(2, true)
		if Input.is_action_just_released("SpecialAbility"):
			ent.setAbilityPressed.rpc(2, false)
		if Input.is_action_just_pressed("dedicated meow button"):
			ent.setAbilityPressed.rpc(3, true)
		if Input.is_action_just_released("dedicated meow button"):
			ent.setAbilityPressed.rpc(3, false)
	#endregion
	
	time_elapsed(delta)


# clock controller
# i should add in hours later if needed
func time_elapsed(delta):
	seconds += delta
	
	var seconds_str = str(int(seconds))
	
	# single digit padding
	if seconds < 10:
		seconds_str = "0" + seconds_str
	
	# updating for minutes
	if seconds >= 60:
		seconds = 0
		minutes += 1
	
	$"HUD STUFF/TimeElapsedLabel".text = str(minutes) + ":" + seconds_str


func _on_status_effect_added(effect:StatusEffect):
	var temp = statusEffectIcon.instantiate()
	temp.effect = effect
	$"HUD STUFF/statusEffectBar".add_child(temp)

func _on_item_acquired(item:PassiveItem):
	$"HUD STUFF/itemdialog".visible = true
	$"HUD STUFF/itemdialog/hflow/icon".texture = item.icon
	$"HUD STUFF/itemdialog/hflow/vflow/name".text = item.itemName
	if item.stackCount > 1:
		$"HUD STUFF/itemdialog/hflow/vflow/name".text += " (x" + str(item.stackCount) + ")"
	$"HUD STUFF/itemdialog/hflow/vflow/desc".text = item.desc
	$"HUD STUFF/itemdialog/disappear".start()

func damageVignette(dmg_amt, _from):
	if !is_instance_valid(ent): return
	var proportion = dmg_amt / ent.stat_maxHp.val
	if proportion < $"HUD STUFF/vignette".modulate.a: return
	$"HUD STUFF/vignette".modulate = Color(Color.RED, proportion)
	if vignetteTween and is_instance_valid(vignetteTween):
		vignetteTween.kill()
	vignetteTween = get_tree().create_tween()
	vignetteTween.tween_property($"HUD STUFF/vignette", "modulate",
			Color(Color.RED, 0), 1 + proportion)

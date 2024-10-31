extends EntityController

var direction:Vector2
var mouseLookMode = true

@onready var ui_hb_over:TextureProgressBar = $"HUD STUFF/healthbar_under/healthbar_over"
@onready var ui_hb_under:TextureProgressBar = $"HUD STUFF/healthbar_under"
@onready var ui_hb_text:Label = $"HUD STUFF/healthbar_under/Label"
@onready var ui_hb_effigy:TextureProgressBar = $"HUD STUFF/objective_health"
var vignetteTween:Tween

const SPECTATOR_BODY_PATH:String = "res://objects/characters/spectator.tscn"
var statusEffectIcon = preload("res://objects/statusEffectIcon.tscn")

var controllerAimLength:float = 0
var controllerAimMinimum:float = 100
var controllerAimMaximum:float = 600
var controllerAimSpeed:float = 400
var lastStickDir:Vector2 = Vector2.ZERO
var trueLookDirection:Vector2 = Vector2.ZERO

# for time elapsed
var seconds: float = 0.0
var minutes: int = 0

const ABILITY_ACTION_MAP:Array[String] = [
	"PrimaryAttack",
	"SecondaryAttack",
	"SpecialAbility",
	"dedicated meow button"
]
@onready var ABILITY_ICON_MAP:Array[Control] = [
	$"HUD STUFF/primaryIcon",
	$"HUD STUFF/secondaryIcon",
	$"HUD STUFF/specialIcon",
	$"HUD STUFF/meowButton"
]

func _ready():
	super._ready()
	
	$"HUD STUFF/vignette".modulate = Color(Color.RED, 0)
	$"HUD STUFF/itemdialog".visible = false
	
	ui_hb_over.tint_progress = ent.healthBarColor
	ent.damage_taken.connect(damageVignette)
	ent.killed.connect(spectate)
	ent.effect_added.connect(_on_status_effect_added)
	ent.item_acquired.connect(_on_item_acquired)
	Chatbox.inst.set_username(ent.entityName)
	
	for i in range(ABILITY_ICON_MAP.size()):
		if ent.abilities.size() > i and is_instance_valid(ent.abilities[i]): 
			ABILITY_ICON_MAP[i].set_ability(ent.abilities[i])

func spectate(killedBy:Entity): # This will need to change to allow respawning
	var ename:String = ent.name
	Chatbox.inst.print_chat.rpc("* " + ename + " was killed by " + killedBy.entityName + ".")
	var epos:Vector2 = ent.global_position
	reparent(get_tree().current_scene)
	global_position = ent.global_position
	await get_tree().create_timer(0.1).timeout
	Entity.spawn(SPECTATOR_BODY_PATH, epos, '', ename)
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
	
	if mouseLookMode: # if aiming with the mouse
		var mp:Vector2 = get_global_mouse_position()
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(mp)
		ent.aimPosition = mp
		if cameraStickDir != Vector2.ZERO:
			# switch off mouse aim if aiming with keyboard / controller
			$assist/shape.disabled = false
			mouseLookMode = false
		
	else: # if aiming with controller or keyboard
		
		# look direction smoothing
		# i dont remember what the thinking behind the checks is here,
		# all i know is that it works
		if cameraStickDir.distance_to(-trueLookDirection) > 1:
			# if it can be reasonably lerped to, lerp to the intended look direction
			trueLookDirection = trueLookDirection.lerp(cameraStickDir, 20*delta)
		elif cameraStickDir.length() > 0:
			# if the player is trying to snap around, there's no time to wait
			# just set their look direction to the intended aim immediately
			trueLookDirection = cameraStickDir
			controllerAimLength = 0
		
		# control the "cursor" position on screen based on how long
		# a specific direction is held & rein in based on delta in look direction
		# used for "freehand" abilities that are aimed with the mouse, such as
		# teleportation, orbital strike, or whatever
		if cameraStickDir.length() > 0:
			# increase or decrease the distance the cursor is at while
			# keeping it within a set range
			# the math here is stupid and unreadable... sorry!
			controllerAimLength += controllerAimSpeed * cameraStickDir.length() * delta
			controllerAimLength = clampf(controllerAimLength /
					(1 + lastStickDir.distance_to(cameraStickDir) * 0.4),
					0, controllerAimMaximum)
		ent.aimPosition = ent.global_position + trueLookDirection * \
				(controllerAimMinimum + controllerAimLength)

		# aim assist
		# by default, make the look direction what we intend for it to be
		# based on the lerp math...
		ent.lookDirection = trueLookDirection
		
		# ... otherwise, we need to snap it to the best available target.
		# things like cursor aim still need to be dictated by trueLookPosition
		
		if true: # have an "assist enabled for non-mouse aim" settings check here
			$assist.global_position = $shoulder.global_position
			if cameraStickDir.length() > 0:
				$assist.look_at($shoulder.global_position + trueLookDirection);
			var sucker:Entity = ent.prioritize($assist.get_overlapping_areas())
			if sucker: ent.lookDirection = ent.shoulderPoint.global_position.direction_to(
					sucker.shoulderPoint.global_position
					)
		
		lastStickDir = cameraStickDir
		
		if Input.get_last_mouse_velocity().length() > 0:
			#switch back to mouse aim mode if the mouse cursor moves at all
			mouseLookMode = true
			$assist/shape.disabled = true
		
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
	if is_instance_valid(Game.effigy):
		ui_hb_effigy.value = (Game.effigy.health / Game.effigy.stat_maxHp.val)
	
	time_elapsed(delta)
	
	#endregion
	
	#region input stuff
	if !Chatbox.isFocused:
		for i in range(ABILITY_ACTION_MAP.size()):
			if Input.is_action_just_pressed(ABILITY_ACTION_MAP[i]):
				ent.setAbilityPressed.rpc(i, true)
			if Input.is_action_just_released(ABILITY_ACTION_MAP[i]):
				ent.setAbilityPressed.rpc(i, false)
	#endregion


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

class_name Ability extends Node2D

signal fired;
signal pressed;
signal charged;
signal released;
signal offCooldown;

@export var ability_name:String = "Nothing"
@export_multiline var ability_desc:String = "Does nothing."
@export var portrait:Texture2D;

@export var is_charged_ability:bool = false
@export var block_other_abilities_while_charging:bool = true
@export var bypass_other_abilities_charging:bool = false
var isCharging:bool = false
var isCharged:bool = false
var isHeld:bool = false
var isOffCooldown:bool = true
var stat_cooldown:Stat;
var stat_chargeTime:Stat;
var cdTimer:float = 0;
var chargeTimer:float = 0;
@onready var ent:Entity = get_parent() as Entity

var isOnCooldown:bool:
	get:
		return cdTimer > 0

func _ready() -> void:
	if ent: set_multiplayer_authority(ent.get_multiplayer_authority())
	ent.ability_vars["_busy"] = false
	if !has_node("stats"):
		var temp = Node.new()
		temp.name = "stats"
		add_child(temp)
	if !has_node("stats/cooldown"):
		$stats.add_child(Stat.fromBase(1, "cooldown"))
	stat_cooldown = $stats/cooldown
	if !has_node("stats/chargeTime"):
		$stats.add_child(Stat.fromBase(1, "chargeTime"))
	stat_chargeTime = $stats/chargeTime

# hooks for child classes
func fireAction() -> void: pass
func chargeStart() -> void: pass
func chargeEnd() -> void: pass

func press() -> void:
	isHeld = true
	if !is_charged_ability:
		pressed.emit()
	
func release() -> void:
	chargeTimer = 0
	if is_charged_ability and isCharging and block_other_abilities_while_charging:
		ent.ability_vars["_busy"] = false
	isCharging = false
	isHeld = false
	if isCharged:
		fireAction()
		fired.emit()
		isCharged = false
		cdTimer = stat_cooldown.val
	released.emit()

func _process(delta: float) -> void:
	if (isHeld or isOnCooldown) and has_node("shoulder"):
		$shoulder.global_position = ent.shoulderPoint.global_position
		$shoulder.global_rotation = ent.shoulderPoint.global_rotation

func _physics_process(delta: float) -> void:
	if cdTimer > 0:
		cdTimer -= delta
		isOffCooldown = false
	if not isOffCooldown and cdTimer <= 0:
		isOffCooldown = true
		offCooldown.emit()
		if is_charged_ability and block_other_abilities_while_charging:
			ent.ability_vars["_busy"] = false
	if isHeld and cdTimer <= 0:
	# there must be a better way to do this, but im doing this for now. fuck it
		if !is_charged_ability: # for swing attacks not meant to be charged
			if not ent.ability_vars["_busy"] or bypass_other_abilities_charging:
				fireAction()
				fired.emit()
				cdTimer = stat_cooldown.val
		elif !isCharged: # for attacks that need to be charged
			chargeTimer += delta
			if not isCharging:
				chargeTimer = 0
				chargeStart()
				isCharging = true
				ent.ability_vars["_busy"] = block_other_abilities_while_charging
				pressed.emit()
			if chargeTimer >= stat_chargeTime.val:
				isCharged = true
				isCharging = false
				chargeEnd()
				charged.emit()

func alignNodeWithShoulder(node:Node2D):
	node.global_position = ent.shoulderPoint.global_position
	node.global_rotation = ent.shoulderPoint.global_rotation

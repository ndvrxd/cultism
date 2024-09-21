class_name Ability extends Node

signal fired;
signal pressed;
signal charged;
signal released;

@export var is_charged_ability:bool = false
var isCharging:bool = false
var isCharged:bool = false
var isHeld:bool = false
@export var NYI_ability_portrait:Texture2D;
var stat_cooldown:Stat;
var stat_chargeTime:Stat;
var cdTimer:float = 0;
var chargeTimer:float = 0;
@onready var ent:Entity = get_parent() as Entity

func _ready() -> void:
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
	pressed.emit()
	
func release() -> void:
	chargeTimer = 0
	isCharging = false
	isHeld = false
	if isCharged:
		fireAction()
		isCharged = false
		cdTimer = stat_cooldown.val
	released.emit()

func _physics_process(delta: float) -> void:
	if cdTimer > 0: cdTimer -= delta
	
	# there must be a better way to do this, but im doing this for now. fuck it
	if !is_charged_ability: # for swing attacks not meant to be charged
		if isHeld and cdTimer <= 0:
			fireAction()
			fired.emit()
			cdTimer = stat_cooldown.val
	elif !isCharged and isHeld and cdTimer <= 0: # for attacks that need to be charged
		chargeTimer += delta
		if not isCharging:
			chargeTimer = 0
			chargeStart()
			isCharging = true
		if chargeTimer >= stat_chargeTime.val:
			isCharged = true
			isCharging = false
			chargeEnd()
			charged.emit()

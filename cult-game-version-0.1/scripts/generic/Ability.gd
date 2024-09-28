class_name Ability extends Node2D
## Base class for actions that an [Entity] can perform. [br]
## Most often referenced using [member Entity.abilities] and
## [method Entity.setAbilityPressed]. [br]
## Invoked primarily by [EntityController]s. [br][br]
## When making a new Ability, make use of the parent class's provided signals: [br]
## - [signal fired][br]- [signal pressed][br]- [signal charged][br]
## - [signal released][br]- [signal offCooldown]

## Emits when the ability successfully fires.
signal fired;

## Emits when the ability is pressed by [member ent]. [br]
## For non-charged abilities, it emits immediately;
## for charged abilities, it does not emit until cooldown has ended.
signal pressed;

## Emits when the ability has charged, if [member is_charged_ability]
## is [code]true[/code].
signal charged;

## Emits when the ability is released by [member ent], regardless of charge status.
signal released;

## Emits as soon as the ability comes off cooldown.
signal offCooldown;

## The name of the ability, as shown in its tooltip.
@export var ability_name:String = "Nothing"
## The description of the ability, as shown in its tooltip.
@export_multiline var ability_desc:String = "Does nothing."
## The portrait for the ability, as shown in the cooldown timer.
@export var portrait:Texture2D;

## The cooldown between uses of this ability in seconds, as a child [Stat] node.
@export var stat_cooldown:Stat = Stat.fromBase(1, "cooldown", self);

## Set this flag if the ability is meant to be held down for a given
## length of time, then fired on release.
@export var is_charged_ability:bool = false

## The number of seconds required to charge this ability, as a child [Stat] node.
## Only used when [member is_charged_ability] is set to [code]true[/code].
@export var stat_chargeTime:Stat = Stat.fromBase(1, "chargeTime", self);

## Whether this ability should block the use of other abilities while it's charging.
@export var block_other_abilities_while_charging:bool = true

## Whether this ability should block the use of other abilities while it's cooling down.
## [br]Not yet applicable to non-charged abilities.
@export var block_other_abilities_while_cooling_down:bool = false

## Whether this ability should bypass other abilities attempting to block it.
@export var bypass_other_abilities_charging:bool = false

## Is set to [code]true[/code] while the ability is charging, and before
## it has fully charged.
var isCharging:bool = false

## Is set to [code]true[/code] after the ability has charged.
var isCharged:bool = false

## Is set to [code]true[/code] while the ability is held,
## regardless of cooldown or charge status.
var isHeld:bool = false

## Is set to [code]true[/code] while the ability is free to use, e.g. off cooldown.
var isOffCooldown:bool = true

## Time, in seconds, remaining on the cooldown. May be changed via code.
var cdTimer:float = 0;

## Time, in seconds, the ability has been charging for. Does not stop when the
## ability is fully charged.
var chargeTimer:float = 0;

## The [Entity] this ability belongs to.
## As such, this Ability is able to access [Entity] fields and methods.
## [br]By default, this is the ability's parent [Node].
@onready var ent:Entity = get_parent() as Entity

func _ready() -> void:
	if ent: set_multiplayer_authority(ent.get_multiplayer_authority())
	ent.ability_vars["_busy"] = false
	if !has_node("stats"):
		var temp = Node.new()
		temp.name = "stats"
		add_child(temp)

func _press() -> void:
	isHeld = true
	if !is_charged_ability:
		pressed.emit()
	
func _release() -> void:
	chargeTimer = 0
	if is_charged_ability and isCharging and block_other_abilities_while_charging:
		ent.ability_vars["_busy"] = false
	isCharging = false
	isHeld = false
	if isCharged:
		fired.emit()
		isCharged = false
		cdTimer = stat_cooldown.val
		if not block_other_abilities_while_cooling_down:
			ent.ability_vars["_busy"] = false
	released.emit()

func _process(delta: float) -> void:
	if (isHeld or !isOffCooldown) and has_node("shoulder"):
		$shoulder.global_position = ent.shoulderPoint.global_position
		$shoulder.global_rotation = ent.shoulderPoint.global_rotation

func _physics_process(delta: float) -> void:
	if cdTimer > 0: # if on cooldown
		cdTimer -= delta
		isOffCooldown = false
	if not isOffCooldown and cdTimer <= 0: # once off cooldown
		isOffCooldown = true
		offCooldown.emit()
		if is_charged_ability and block_other_abilities_while_cooling_down:
			ent.ability_vars["_busy"] = false
	if isHeld and cdTimer <= 0: # should fire
	# there must be a better way to do this, but im doing this for now. fuck it
		if !is_charged_ability: # for swing attacks not meant to be charged
			if not ent.ability_vars["_busy"] or bypass_other_abilities_charging:
				fired.emit()
				cdTimer = stat_cooldown.val
		elif !isCharged: # for attacks that need to be charged
			chargeTimer += delta
			if not isCharging:
				chargeTimer = 0
				isCharging = true
				ent.ability_vars["_busy"] = block_other_abilities_while_charging
				pressed.emit()
			if chargeTimer >= stat_chargeTime.val:
				isCharged = true
				isCharging = false
				charged.emit()

## Aligns the Transform of the provided [param node] with [member ent]'s [member Entity.shoulderPoint].
## Used in the absence of being able to properly parent child nodes of an Ability to
## [member ent]'s shoulder.
func alignNodeWithShoulder(node:Node2D):
	node.transform = ent.shoulderPoint.transform

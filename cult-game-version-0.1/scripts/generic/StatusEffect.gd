class_name StatusEffect extends Node2D

signal stack_added(count:int)
signal stack_removed(count:int)
signal stackCountChanged(delta:int)
signal stack_expired
signal effect_removed

## The Entity that currently has this effect.
var ent:Entity 

## The icon for this status effect, as shown above the health bar.
@export var icon:Texture2D;

## How long this effect should last, in seconds.
## Values 0 or lower last indefinitely.
@export var duration:float = 5;
var _age = 0;

## The in-game name for this effect.
@export var effectName:String = "Unnamed Effect"

## The in-game description for this effect.
@export_multiline var desc:String = "No description set."

## Whether this effect is classified as a debuff.
@export var isDebuff:bool = true

## How many stacks of this effect our Entity has.
## Do not modify with code!
var stackCount:int = 1

var addlStacks:int:
	get: return (stackCount - 1)

## Set by Entity parent class when the effect is added by its path.
## Used for network sync for joining players & the "has effect" method
var _ownPath:String

func _ready() -> void:
	ent = get_parent() as Entity;
	if not ent: queue_free(); return
	set_multiplayer_authority(ent.get_multiplayer_authority())

func _process(delta:float) -> void:
	if duration > 0:
		_age += delta
		if _age >= duration:
			_age = 0
			stack_expired.emit()
			removeStacks(1)

## Gets the current stack count of this effect.
func getStacks() -> int:
	return stackCount

## Adds a stack of this effect.
func addStacks(count:int):
	stackCount += count
	stackCountChanged.emit(count)
	stack_added.emit(count)

## Removes a stack of this effect.
func removeStacks(count:int):
	stackCount -= count
	if stackCount <= 0:
		remove()
	else:
		stackCountChanged.emit(-count)
		stack_removed.emit(count)

func remove():
	ent._statusEffects.erase(self)
	effect_removed.emit()
	# FIXME doesn't respect pause
	await get_tree().create_timer(5).timeout
	queue_free()

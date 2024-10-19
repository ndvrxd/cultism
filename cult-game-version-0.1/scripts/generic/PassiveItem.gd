class_name PassiveItem extends Node2D
# Base class for passive Item upgrades.

signal stack_added(count:int)
signal stack_removed(count:int)
signal stackCountChanged(delta:int)
signal effects_removed

## The Entity that currently has this item.
var ent:Entity 

## The icon for this item, as it should appear as a pickup & in UI.
@export var icon:Texture2D;

## The in-game name for this item.
@export var itemName:String = "Formless"

## The in-game description for this item.
@export_multiline var desc:String = "An item...? It does nothing."

## How many stacks of this item our Entity has.
## Do not modify with code!
var stackCount:int = 1

var addlStacks:int:
	get: return (stackCount - 1)

## Set by Entity parent class when the item is added, by its path.
## Used for network sync for joining players & the "has item" method
var _ownPath:String

func _ready() -> void:
	ent = get_parent() as Entity;
	if not ent: queue_free(); return
	set_multiplayer_authority(ent.get_multiplayer_authority())

## Gets the current stack count of this effect.
func getStacks() -> int:
	return stackCount

## Adds a stack of this item.
func addStacks(count:int):
	stackCount += count
	stackCountChanged.emit(count)
	stack_added.emit(count)

## Removes a stack of this item.
func removeStacks(count:int):
	stackCount -= count
	if stackCount <= 0:
		remove()
	else:
		stackCountChanged.emit(-count)
		stack_removed.emit(count)

func remove():
	ent._statusEffects.erase(self)
	effects_removed.emit()
	# FIXME doesn't respect pause
	await get_tree().create_timer(5).timeout
	queue_free()

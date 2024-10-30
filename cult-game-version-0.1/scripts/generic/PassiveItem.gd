class_name PassiveItem extends Node2D
## Base class for passive Item upgrades.

## Emitted when [param count] stacks of this item are added.
signal stack_added(count:int)

## Emitted when [param count] stacks of this item are removed.
signal stack_removed(count:int)

## Emitted when the stack count of this item changes by [param delta].
signal stackCountChanged(delta:int)

## Emits when the item and its effects should be cleaned up entirely.
signal effects_removed

## The [Entity] that currently has this item.
var ent:Entity 

static var _pickupBlurbScn = preload("res://objects/itemPickupBlurb.tscn")

## The icon for this item, as it should appear as a pickup & in UI.
@export var icon:Texture2D;

## The in-game name for this item.
@export var itemName:String = "Formless"

## The in-game description for this item.
@export_multiline var desc:String = "An item...? It does nothing."

## The little "blurb" that should be shown when this item is picked up.
@export var pickup_blurb:String = "NO PICKUP BLURB SET!!!"

## The [Color] of the [member pickup_blurb].
@export var pickup_blurb_color = Color.LIME_GREEN

## How many stacks of this item [member ent] has.
## Do not modify with code!
var stackCount:int = 1

var addlStacks:int:
	get: return (stackCount - 1)

## Set by [Entity] parent class when the item is added, by its path.
## Used for network sync for joining players & the "has item" method.
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
	
	var blurb:Label = _pickupBlurbScn.instantiate()
	blurb.text = pickup_blurb
	blurb.modulate = pickup_blurb_color
	blurb.global_position = ent.shoulderPoint.global_position + Vector2(0, -80)
	if !is_inside_tree(): await tree_entered
	get_tree().current_scene.add_child(blurb)

## Removes a stack of this item.
func removeStacks(count:int):
	stackCount -= count
	if stackCount <= 0:
		remove()
	else:
		stackCountChanged.emit(-count)
		stack_removed.emit(count)

## Remove the item from the entity entirely.
func remove():
	ent._items.erase(self)
	effects_removed.emit()
	await get_tree().create_timer(5, false).timeout
	queue_free()

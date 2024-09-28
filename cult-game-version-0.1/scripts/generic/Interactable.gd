class_name Interactable extends Area2D
## Base class for interactable objects.

## Fired when any [Entity] uses [method Entity.interact] on this object.
signal interacted_with(by:Entity)

@rpc("any_peer", "reliable", "call_local")
func _trigger_interact_rpc(by_path:String):
	interacted_with.emit(get_node(by_path))

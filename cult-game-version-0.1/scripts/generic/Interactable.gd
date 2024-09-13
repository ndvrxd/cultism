class_name Interactable extends Area2D

signal interacted_with(by:Entity)

@rpc("any_peer", "reliable", "call_local")
func trigger_interact_rpc(by_path:String):
	interacted_with.emit(get_node(by_path))

extends Control

@export var item_paths: Array[String]

var selected_item: String
var ent:Entity

# these paths can be dragged & dropped in from the scene hierarchy
@onready var list:ItemList = $InnerVBoxContainer/ItemList

func _ready() -> void:
	$AnimationPlayer.play("closed")
	visible = false
	var interact_obj:Interactable = get_parent() as Interactable
	if interact_obj:
		interact_obj.interacted_with.connect(toggle_for)

func toggle_for(entity:Entity) -> void:
	if entity == ent:
		$AnimationPlayer.play("closed")
		ent.frozen = false
		visible = false
		ent = null
	elif entity.has_node("PlayerControls"): #play nice in multiplayer
		visible = true
		$AnimationPlayer.play("open")
		ent = entity
		ent.frozen = true
		list.deselect_all()

func _on_item_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != 1: return
	selected_item = item_paths[index]
	ent.frozen = false
	ent.addItem(load(selected_item))
	$AnimationPlayer.play("selected")
	await $AnimationPlayer.animation_finished
	visible = false

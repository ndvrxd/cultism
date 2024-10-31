extends Control

var selected_item: String
var ent:Entity

@export var item_pool:ItemDropPool
@export var item_count:int = 3

var _item_paths:Array[String] = []

# these paths can be dragged & dropped in from the scene hierarchy
@onready var list:ItemList = $InnerVBoxContainer/ItemList

func _ready() -> void:
	$AnimationPlayer.play("closed")
	visible = false
	var interact_obj:Interactable = get_parent() as Interactable
	if interact_obj:
		interact_obj.interacted_with.connect(toggle_for)

func roll_items():
	list.clear()
	_item_paths.clear()
	for i in range(item_count):
		var item = item_pool.pullItem()
		_item_paths.append(item._ownPath)
		list.add_item(item.itemName, item.icon, true)
		item.queue_free()

func toggle_for(entity:Entity) -> void:
	if entity == ent:
		$AnimationPlayer.play("closed")
		ent.get_node("PlayerControls").inhibitInputEvents = false
		visible = false
		ent = null
	elif entity.has_node("PlayerControls"): #play nice in multiplayer
		visible = true
		$AnimationPlayer.play("open")
		ent = entity
		ent.get_node("PlayerControls").inhibitInputEvents = true
		list.deselect_all()
		roll_items()

func _input(_event: InputEvent) -> void:
	if is_instance_valid(ent):
		Input.is_action_just_pressed("PrimaryAttack")
		Input.is_action_just_released("PrimaryAttack")

func _on_item_list_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != 1: return
	selected_item = _item_paths[index]
	ent.addItem(load(selected_item))
	$AnimationPlayer.play("selected")
	await get_tree().create_timer(0.1, false).timeout
	ent.get_node("PlayerControls").inhibitInputEvents = false
	ent = null

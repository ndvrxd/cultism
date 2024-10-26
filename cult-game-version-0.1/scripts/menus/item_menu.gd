extends Control

@export var item_paths: Array[String]

var my_entity: Entity
var selected_item: String


func _ready() -> void:
	$AnimationPlayer.play("RESET")
	visible = false

func _process(delta: float) -> void:
	# can't confirm without something selected
	if not %ItemList.is_anything_selected():
		%ConfirmButton.disabled = true
	else:
		%ConfirmButton.disabled = false
	
	# TODO: fix this
	#if Input.is_action_just_pressed("Interact") and visible:
		#visible = false


func setup(entity: Entity) -> void:
	my_entity = entity


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	selected_item = item_paths[index]


func _on_confirm_button_pressed() -> void:
	my_entity.addItem(load(selected_item))
	$MarginContainer.process(false)
	hide_me()


func show_me() -> void:
	visible = true
	%ItemList.deselect_all()
	%AnimationPlayer.play("blur")
	# this SHOULD work, but for some reason
	# the items arent selectable
	if multiplayer.is_server() and NetManager.players.size() < 2:
		get_tree().paused = true


func hide_me() -> void:
	%AnimationPlayer.play_backwards("blur")
	await get_tree().create_timer(0.3).timeout
	visible = false
	
	if get_tree().paused:
		get_tree().paused = false

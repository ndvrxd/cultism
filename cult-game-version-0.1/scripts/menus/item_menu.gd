extends Control

@export var item_paths: Array[String]

var my_entity: Entity
var selected_item: String


# todo: add a close on e function
func setup(entity: Entity) -> void:
	my_entity = entity


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	selected_item = item_paths[index]


func _on_confirm_button_pressed() -> void:
	my_entity.addItem(load(selected_item))
	queue_free()

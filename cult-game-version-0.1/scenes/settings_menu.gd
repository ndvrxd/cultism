class_name Settings
extends Control


@onready var exit_button = $MarginContainer/VBoxContainer/Exit_Button as Button


signal exit_settings_menu

func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)
	

func on_exit_pressed() -> void:
	exit_settings_menu.emit()
	set_process(false)


func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1280,720))
			get_window().move_to_center()
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
			get_window().move_to_center()
		2:
			DisplayServer.window_set_size(Vector2i(1920,1080))
			get_window().move_to_center()



func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

extends Control




func _on_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)


func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0,toggled_on)
	

func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
			get_window().move_to_center()
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
			get_window().move_to_center()
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
			get_window().move_to_center()


func _on_check_button_toggled(button_toggled):
	if button_toggled == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

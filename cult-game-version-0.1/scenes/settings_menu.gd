class_name Settings
extends Control


@onready var exit_button = $MarginContainer/VBoxContainer/Exit_Button as Button


#needed to make these variables so i could pull the slider value to save to settings :D
@onready var master = $"MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/Hbox Master/Master" as Slider
@onready var sfx = $"MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/Hbox SFX/sfx" as Slider
@onready var music = $"MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/Hbox Music/music" as Slider

@onready var fullscreen_checkbutton = $"MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/Hbox Fullscreen/Fullscreen"
@onready var resolution_selected = $"MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/Hbox Resolution/Resolutions"


signal exit_settings_menu

func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)
	
	
	#loads settings
	var video_settings = ConfigFileHandler.load_video_settings()
	fullscreen_checkbutton.button_pressed = video_settings.fullscreen
	#first line sets the setting to reflect the resolution its loading, second actually calls the function to set it
	resolution_selected.select(video_settings.resolution)
	_on_resolutions_item_selected(video_settings.resolution)
	
	var audio_settings = ConfigFileHandler.load_audio_settings()
	master.value = min(audio_settings.master_volume, 1.0)
	sfx.value = min(audio_settings.sfx_volume, 1.0)
	music.value = min(audio_settings.music_volume, 1.0)
	
	
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
			
	ConfigFileHandler.save_video_settings("resolution", index)




### everything below this is for saving settings to a settings file
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	ConfigFileHandler.save_video_settings("fullscreen", toggled_on)


func _on_master_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_settings("master_volume", master.value)


func _on_sfx_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_settings("sfx_volume", sfx.value)


func _on_music_drag_ended(value_changed: bool) -> void:
	if value_changed:
		ConfigFileHandler.save_audio_settings("music_volume", music.value)

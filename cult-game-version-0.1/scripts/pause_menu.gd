extends Control
@onready var settings_button: Button = $PanelContainer/VBoxContainer/Settings as Button
@onready var settingslol: Settings = $Settings as Settings
@onready var panel_container: PanelContainer = $PanelContainer as PanelContainer

func _ready():
	$AnimationPlayer.play("RESET")
	grab_focus()
	settingslol.visible = false
	handle_connecting_signals()
	

#func resize():
	#size() = OS.get_screen_size()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	panel_container.visible = true

func testEsc():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		settingslol.visible = false
		resume()

func _on_resume_pressed() -> void:
	resume()
	
	
########### NEW STUFF ##############



func handle_connecting_signals() -> void:
	settings_button.button_down.connect(_on_settings_pressed)
	settingslol.exit_settings.connect(on_exit_settings)

func _on_settings_pressed() -> void:
	panel_container.visible = false
	settingslol.visible = true

func on_exit_settings() -> void:
	pass


##############################
func _on_main_menu_pressed() -> void:
	pass # Replace with function body.
#### kinda this too ^^^^
func _on_quit_pressed() -> void:
	get_tree().quit()

func _process(_delta):
	testEsc()
	#resize()

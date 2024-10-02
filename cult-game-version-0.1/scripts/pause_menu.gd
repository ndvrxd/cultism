extends Control

@onready var settings_button: Button = $PanelContainer/VBoxContainer/Settings as Button
@onready var settings_menu = $settings_menu as Settings
@onready var panel_container: PanelContainer = $PanelContainer as PanelContainer

func _ready():
	$AnimationPlayer.play("RESET")
	grab_focus.call_deferred()
	settings_menu.visible = false
	panel_container.visible = false
	visible = false
	#panel_container.set_process(false)
	handle_connecting_signals()
	
	


func resume():
	$AnimationPlayer.play_backwards("blur")
	await get_tree().create_timer(0.25).timeout
	visible = false
	if get_tree().paused: get_tree().paused = false
func pause():
	visible = true
	$PanelContainer.visible = true
	$PanelContainer/VBoxContainer/Resume.grab_focus()
	$AnimationPlayer.play("blur")
	if multiplayer.is_server() and NetManager.players.size() < 2:
		get_tree().paused = true

func testEsc():
	if Input.is_action_just_pressed("esc") and !visible:
		pause()
		panel_container.set_process(true)
	elif Input.is_action_just_pressed("esc") and visible:
		settings_menu.visible = false
		resume()

func _on_resume_pressed() -> void:
	panel_container.set_process(false)
	resume()
	
	
########### NEW STUFF (SETTINGS MENU) ##############


func handle_connecting_signals() -> void:
	settings_button.button_down.connect(on_settings_pressed)
	settings_menu.exit_settings_menu.connect(on_exit_settings)
	$"PanelContainer/VBoxContainer/Main Menu".pressed.connect(NetManager.leave_game)

func on_settings_pressed() -> void:
	panel_container.visible = false
	settings_menu.set_process(true)
	settings_menu.visible = true


func on_exit_settings() -> void:
	panel_container.visible = true
	settings_menu.visible = false
	

##############################
func _on_main_menu_pressed() -> void:
	pass # Replace with function body.
#### kinda this too ^^^^
func _on_quit_pressed() -> void:
	get_tree().quit()

func _process(_delta):
	testEsc()
	#resize()

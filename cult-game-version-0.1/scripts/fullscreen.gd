extends Node

# kinda stupid that this is its own global thing but like. i want it to
# sync with the settings menu and the F11 key so global script it is i guess!
var enabled:bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS #run while paused
	# if this is a release build, fullscreen by default
	setEnabled(!OS.is_debug_build())

func setEnabled(value:bool) -> void:
	enabled = value
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _input(e:InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle Fullscreen"):
		setEnabled(!enabled)

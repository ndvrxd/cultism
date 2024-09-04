class_name Chatbox extends Control

@export var chatLabel:Label
@export var chatInput:LineEdit
@export var username:String = "Player"

static var inst:Chatbox # real unity singleton bullshit

signal chatbox_focus_changed(focused:bool)

func _enter_tree():
	inst = self

func _ready():
	chatLabel.text=''

func _input(event):
	if Input.is_action_just_pressed("Chat"):
		var vp:Viewport = get_viewport()
		if vp.gui_get_focus_owner() != chatInput:
			chatbox_focus_changed.emit(true)
			chatInput.grab_focus()
		else:
			chatbox_focus_changed.emit(false)
			chatInput.release_focus()
			if chatInput.text.length() > 0:
				print_chat.rpc(username + ": " + chatInput.text)
			chatInput.text = ""

@rpc('reliable','call_local', 'any_peer')
func print_chat(msg:String):
	if msg.length() > 0:
		chatLabel.text += '\n' + msg;
		
func set_username(username:String):
	self.username = username if !username.is_empty() else "Player"

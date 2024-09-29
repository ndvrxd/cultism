extends Node

@export var nameBox:LineEdit;
@export var addressBox:LineEdit;
@export var portBox:LineEdit;
@export var errorMsg:Label;
@export var charBodySel:ItemList;

@export var path:String = "res://objects/characters/{}.tscn"

func _ready():
	NetManager.connection_refused.connect(emsgCallback)
	charBodySel.select(0)
	
func onJoinClicked():
	NetManager.playerinfo_local["name"] = nameBox.text;
	NetManager.playerinfo_local["charbody"] = path.format(
		[charBodySel.get_item_text(charBodySel.get_selected_items()[0])],
		"{}"
		);
	#NetManager.playerinfo_local["color"] = color.color;
	NetManager.join_game(addressBox.text, portBox.text.to_int());
	
func onCreateClicked():
	NetManager.playerinfo_local["name"] = nameBox.text;
	NetManager.playerinfo_local["charbody"] = path.format(
		[charBodySel.get_item_text(charBodySel.get_selected_items()[0])],
		"{}"
		);
	print(NetManager.playerinfo_local["charbody"])
	#NetManager.playerinfo_local["color"] = color.color;
	NetManager.start_listen_server("localhost", portBox.text.to_int());

func emsgCallback(reason):
	errorMsg.text = reason;


func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/title.tscn")

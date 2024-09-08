extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal connection_refused(reason)

var gameinfo = {};
var playerinfo_local = {"name":"Server"};
var players = {};

const MAP = "res://scenes/levels/world.tscn"
const PLAYERCONTROLSOBJ = "res://objects/controllers/player_controls.tscn"
#var playerBodyPath = "res://objects/enemy.tscn";

# THIS IS ALL VERY TRUSTING OF THE CLIENT
# BAD OPSEC BUT SUFFICIENT FOR PLAYTESTING

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(onPlayerConnect)
	multiplayer.peer_disconnected.connect(onPlayerDisconnect)
	multiplayer.connected_to_server.connect(onConnectionSuccess)
	multiplayer.connection_failed.connect(onConnectionFailed)
	multiplayer.server_disconnected.connect(onServerDisconnect)
	if IsDedicated():
		start_listen_server();

func IsDedicated():
	return multiplayer.is_server() and (OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless")

func join_game(address="localhost", port=24500):
	if IsDedicated(): return;
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func start_listen_server(_hostname="localhost", port=24500, maxplayers=16):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, maxplayers)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	if !IsDedicated():
		#players[1] = playerinfo_local
		player_connected.emit(1, playerinfo_local)
		onPlayerConnect(1);
	else:
		load_game(MAP);

func onPlayerConnect(id): # all clients, NOT JUST server
	if !IsDedicated(): # send local player info to newly connected remote peer
		recvPeerInfoCallback.rpc_id(id, playerinfo_local);

@rpc("reliable")
func setDisconnectMessage(reason):
	print("Disconnected: " + reason)
	connection_refused.emit(reason)

@rpc("any_peer", "reliable", "call_local")
func recvPeerInfoCallback(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	
	if multiplayer.is_server():
		var discReason = ""
		for p in players:
			if new_player_info["name"] == players[p]["name"]:
				discReason = "Another player already has that name."
		
		if discReason.is_empty():
			load_game.rpc_id(new_player_id, MAP)
		else:
			setDisconnectMessage.rpc_id(new_player_id, discReason);
			await get_tree().create_timer(0.1).timeout
			multiplayer.multiplayer_peer.disconnect_peer(new_player_id);
	if Chatbox.inst:
		Chatbox.inst.print_chat(new_player_info["name"] + " connected.")
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

@rpc("any_peer", "call_remote", "reliable")
func askForEntities():
	var id = multiplayer.get_remote_sender_id()
	if multiplayer.is_server():
		var ents = get_tree().get_nodes_in_group("entity")
		for i in ents:
			if not i is Entity: continue
			var e = i as Entity
			spawnEntityRpc.rpc_id(id, e.objPath, e.global_position, "", e.name,
				e.name == e.entityName); # very stupid bandaid fix this is BAD.
				# this only nametags an entity & considers it a player if the
				# node name is the same as the entity name.
				# i really need to do some cleanup around here
			e.changeHealth.rpc_id(id, e.health, 0) # sync enemy health when player joins

@rpc("any_peer", "call_local", "reliable")
func spawnEntityRpc(scnPath:String, pos:Vector2 = Vector2.ZERO, ctlPath:String="", eName:String="", isPlayer=false):
	var id = multiplayer.get_remote_sender_id()
	if id:
		if eName != "":
			if get_tree().current_scene.get_node("spawns").has_node(eName): return
		var ebody:Entity = load(scnPath).instantiate();
		ebody.global_position = pos
		if eName != "":
			ebody.name = eName;
			if isPlayer:
				ebody.entityName = eName;
				ebody.team = 1;
				addNametagToEntity.call_deferred(ebody)
		get_tree().current_scene.get_node("spawns").add_child.call_deferred(ebody)
		if id == multiplayer.get_unique_id():
			var ectl:EntityController
			if ctlPath != "":
				ectl = load(ctlPath).instantiate();
			elif ebody.controllerPath != "":
				ectl = load(ebody.controllerPath).instantiate();
			else: return
			ebody.add_child.call_deferred(ectl)
			#ectl.attemptControl.call_deferred();

func addNametagToEntity(ebody): # here so i can call this deferred clientside
	await get_tree().create_timer(0.1).timeout
	var nametag = preload("res://objects/nameTag.tscn").instantiate();
	ebody.add_child(nametag)
	nametag.get_child(0).position.y = (ebody.shoulderPoint.global_position.y - ebody.global_position.y) * 2.3
	nametag.get_child(0).text = ebody.entityName

# When the server decides to start the game from a UI scene,
# do load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)
	await get_tree().create_timer(0.1).timeout
	if !IsDedicated():
		Entity.spawn.call_deferred(playerinfo_local["charbody"], Vector2.ZERO, '', playerinfo_local["name"])
		if !multiplayer.is_server(): askForEntities.rpc_id.call_deferred(1)
		Chatbox.inst.set_username(playerinfo_local["name"])

func onPlayerDisconnect(id): # all clients, NOT JUST server
	if get_tree().current_scene.get_node("spawns") and get_tree().current_scene.get_node("spawns").get_node(players[id]["name"]):
		get_tree().current_scene.get_node("spawns").get_node(players[id]["name"]).queue_free()
	if Chatbox.inst:
		Chatbox.inst.print_chat(players[id]["name"] + " disconnected.")
	players.erase(id)
	player_disconnected.emit(id)

func onConnectionSuccess(): # clientside only
	if !IsDedicated():
		var peer_id = multiplayer.get_unique_id()
		players[peer_id] = playerinfo_local
		player_connected.emit(peer_id, playerinfo_local)

func onConnectionFailed(): # clientside only
	multiplayer.multiplayer_peer = null

func onServerDisconnect(): # clientside only
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

@rpc("authority", "reliable", "call_local")
func transferAuthority(nodepath:String, cid:int, recursive:bool=false) -> void: # use this later
	# make sure all clients are in agreement over who controls what
	var node:Node
	node = get_tree().get_node(nodepath)
	node.set_multiplayer_authority(cid, recursive);

extends Node

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal connection_refused(reason)

var gameinfo = {};
var playerinfo_local = {"name":"Server"};
var players = {};

const MAP = "res://scenes/levels/world_tilemap.tscn"
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
	multiplayer.multiplayer_peer.disconnect_peer(1)
	multiplayer.multiplayer_peer.close()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func leave_game():
	if IsDedicated(): return;
	if multiplayer.is_server(): players.clear()
	get_tree().paused = false
	multiplayer.multiplayer_peer.disconnect_peer(1)
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://scenes/connectScreen.tscn")

@rpc("authority", "call_remote", "reliable")
func kick_rpc(reason:String = "No reason given"):
	leave_game()
	setDisconnectMessage(reason);

func start_listen_server(_hostname="localhost", port=24500, maxplayers=16):
	multiplayer.multiplayer_peer.disconnect_peer(1)
	multiplayer.multiplayer_peer.close()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, maxplayers)
	print(error)
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

@rpc("reliable", "call_local")
func setDisconnectMessage(reason):
	print("Disconnected: " + reason)
	connection_refused.emit(reason)

## Called by [b]every peer[/b] when a new player joins.
## Each peer uses [method Callable.rpc_id] to send their player
## data specifically to the newly connected client.
## This method then runs on the connecting client's side for every
## other connected peer.
@rpc("any_peer", "reliable", "call_local")
func recvPeerInfoCallback(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	
	if multiplayer.is_server():
		var discReason = ""
		for p in players:
			if new_player_info["name"] == players[p]["name"]:
				discReason = "Another player already has that name."
				new_player_info["name"] = "(NAME ALREADY TAKEN)"
		
		if discReason.is_empty():
			load_game.rpc_id(new_player_id, MAP)
		else:
			setDisconnectMessage.rpc_id(new_player_id, discReason);
			await get_tree().create_timer(0.1).timeout
			multiplayer.multiplayer_peer.disconnect_peer(new_player_id);
	if Chatbox.inst and is_instance_valid(Chatbox.inst):
		Chatbox.inst.print_chat(new_player_info["name"] + " connected.")
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

## Called by newly connected clients to request every [Entity] from the server.
## The server calls [method spawnEntityRpc] for specifically that client,
## placing a copy of every (server subjective) [Entity] into their game, with the
## same [NodePath] to ensure network sync.
@rpc("any_peer", "call_remote", "reliable")
func askForEntities():
	# this runs basically only as the server
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id() #id of requesting client
		# try to send the requesting client commands to spawn
		# every entity that currently exists
		var ents = get_tree().get_nodes_in_group("entity")
		for i in ents:
			if not i is Entity: continue
			var e = i as Entity
			# if this entity's node name is the same as its in-game name,
			# assume it's a player. this is stupid and dumb but theres no other
			# indication on our end
			spawnEntityRpc.rpc_id(id, e.objPath, e.global_position, "", e.name,
				e.name == e.entityName);
			e.changeHealth.rpc_id(id, e.health, 0) # sync enemy health when player joins

## RPC-decorated method to spawn an [Entity] into someone else's game. [br]
## [b]In general, DO NOT use this to spawn entities.[\b] Instead, use
## the static method [method Entity.spawn], which determines the [NodePath]
## of the newly spawned entity [i]clientside[/i] before sending the RPC call.
@rpc("any_peer", "call_local", "reliable")
func spawnEntityRpc(scnPath:String, pos:Vector2 = Vector2.ZERO, ctlPath:String="", eName:String="", isPlayer=false):
	var id = multiplayer.get_remote_sender_id()
	if id:
		if eName != "":
			if get_tree().current_scene.has_node(eName):
				if is_instance_valid(get_tree().current_scene.get_node(eName)): return
		var ebody:Entity = load(scnPath).instantiate();
		get_tree().current_scene.add_child(ebody)
		ebody.global_position = pos
		#await ebody.ready # ready dddnever emits for some godforsaken reason
		#print("ready")
		await get_tree().create_timer(0.1).timeout #FIXME find a way around this
		if eName != "":
			ebody.name = eName;
			if isPlayer:
				ebody.entityName = eName;
				ebody.changeTeam(1); # set to "allies" team
				# make sure that, subjectively, this node should be controlled by the invoking party
				ebody.set_multiplayer_authority(id) 
				if id != multiplayer.get_unique_id():
					var nametag = preload("res://objects/nameTag.tscn").instantiate();
					ebody.add_child(nametag)
					nametag.get_child(0).position.y = (ebody.shoulderPoint.global_position.y
							- ebody.global_position.y) * 2.3
					nametag.get_child(0).text = ebody.entityName
		if is_multiplayer_authority():
			var ectl:EntityController
			if ctlPath != "":
				ectl = load(ctlPath).instantiate();
			elif ebody.controllerPath != "":
				ectl = load(ebody.controllerPath).instantiate();
			else: return
			ebody.add_child(ectl)
			ectl.attemptControl.call_deferred();

func _addNametagToEntity(ebody): # here so i can call this deferred clientside
	await get_tree().create_timer(0.1).timeout

# When the server decides to start the game from a UI scene,
# do load_game.rpc(filepath)
## Loads a scene for all players by its resource path. 
## Callable only by the server.
@rpc("call_local", "reliable")
func load_game(game_scene_path:String):
	get_tree().change_scene_to_file(game_scene_path)
	# wait for the scene to load completely
	await get_tree().tree_changed
	await get_tree().current_scene.ready
	if !IsDedicated():
		# pick somewhere to spawn
		var spawnpoints = get_tree().get_nodes_in_group("player_spawnpoint") 
		var sp:Vector2 = spawnpoints.pick_random().global_position
		Entity.spawn.call_deferred(playerinfo_local["charbody"], sp, '', playerinfo_local["name"])
		# ask the server to spawn all entities into your game
		if !multiplayer.is_server(): askForEntities.rpc_id(1)
		# set your name for the chatbox
		# TODO: redo the chatbox entirely, you bitch
		Chatbox.inst.set_username(playerinfo_local["name"])

func onPlayerDisconnect(id): # all clients, NOT JUST server
	# destroy the disconnecting client's Entity body, if there is any
	if get_tree().current_scene.get_node(players[id]["name"]):
		get_tree().current_scene.get_node(players[id]["name"]).queue_free()
	if Chatbox.inst:
		Chatbox.inst.print_chat(players[id]["name"] + " disconnected.")
	players.erase(id) # no more entry in player data table
	player_disconnected.emit(id)

func onConnectionSuccess(): # clientside only
	if !IsDedicated():
		var peer_id = multiplayer.get_unique_id()
		players[peer_id] = playerinfo_local
		player_connected.emit(peer_id, playerinfo_local)

func onConnectionFailed(): # clientside only
	leave_game()
	
	setDisconnectMessage("Dropped from server.");

func onServerDisconnect(): # clientside only
	multiplayer.multiplayer_peer.close()
	players.clear()
	server_disconnected.emit()

extends Node

const SERVER_IP = "127.0.0.1";
const PORT = 9000;
const SERVER_ID = 1;

var players = {};
@onready var username_field = $"CanvasLayer/Control/Username Field";
@onready var join_button = $"CanvasLayer/Control/Join Button";
@onready var leave_button = $"CanvasLayer/Control/Leave Button";

func _ready():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, PORT)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected)

	multiplayer.connection_failed.connect(func():
		print("Falha ao conectar ao servidor.")
	)
	
	join_button.pressed.connect(_on_join_pressed);
	leave_button.pressed.connect(_on_leave_pressed);
	
	leave_button.disabled = true;
	leave_button.focus_mode = Control.FOCUS_NONE;

func _on_connected():
	print("Conectado ao servidor!");
	rpc_id(SERVER_ID, "check_other_players", players);

@rpc("any_peer", "reliable")
func check_other_players(_players: Dictionary):
	pass;

@rpc("authority", "reliable")
func spawn_other_players(not_spawned_players: Array):
	for not_spawned_player in not_spawned_players:
		var peer_id = not_spawned_player.peer_id;
		var username = not_spawned_player.username;
		var player = preload("res://scenes/player.tscn").instantiate();
		player.set_multiplayer_authority(peer_id);
		player.name = str(peer_id);
		player.username = username;
		get_tree().current_scene.add_child(player);
		players[peer_id] = player;

@rpc("authority", "reliable")
func despawn_player(peer_id: int):
	if peer_id == multiplayer.get_unique_id():
		username_field.editable = true;
		username_field.selecting_enabled = true;
		username_field.focus_mode = Control.FOCUS_ALL;
		
		join_button.disabled = false;
		join_button.focus_mode = Control.FOCUS_ALL;
		
		leave_button.disabled = true;
		leave_button.focus_mode = Control.FOCUS_NONE;
		leave_button.release_focus();
	
	if players.has(peer_id):
		players[peer_id].queue_free();
		players.erase(peer_id);

func _on_join_pressed():
	var username = username_field.text;
	rpc_id(SERVER_ID, "spawn_request", username);
	
@rpc("any_peer", "reliable")
func spawn_request():
	pass;

@rpc("authority", "reliable")
func spawn_player(peer_id: int, username: String):
	var player = preload("res://scenes/player.tscn").instantiate();
	player.set_multiplayer_authority(peer_id);
	player.name = str(peer_id);
	player.username = username;
	get_tree().current_scene.add_child(player);
	players[peer_id] = player;
	
	if peer_id == multiplayer.get_unique_id():
		username_field.editable = false;
		username_field.selecting_enabled = false;
		username_field.focus_mode = Control.FOCUS_NONE;
		username_field.release_focus();
		
		join_button.disabled = true;
		join_button.focus_mode = Control.FOCUS_NONE;
		join_button.release_focus();
		
		leave_button.disabled = false;
		leave_button.focus_mode = Control.FOCUS_ALL;
		
func _on_leave_pressed():
	rpc_id(SERVER_ID, "despawn_request");
	
@rpc("any_peer", "reliable")
func despawn_request():
	pass;

extends CharacterBody2D

const SERVER_ID: int = 1;

@export var username: String = "";
@onready var username_label = $Username;
@onready var sprite = $Sprite2D;

func _ready():
	username_label.text = username;

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return;
		
	var turn = Input.get_action_strength("right") - Input.get_action_strength("left");
	var thrust = Input.is_action_pressed("forward");
	
	rpc_id(SERVER_ID, "receive_player_input", turn, thrust);

@rpc("any_peer", "unreliable")
func receive_player_input(_turn: float, _thrust: bool):
	pass;
	
@rpc("any_peer", "unreliable")
func update_player_state(pos: Vector2, rot: float):
	position = position.lerp(pos, 0.5)
	sprite.rotation = rot;

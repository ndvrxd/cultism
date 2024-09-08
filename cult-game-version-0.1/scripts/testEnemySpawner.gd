extends Node2D

const bodypath:String = "res://objects/characters/enemy.tscn"

@export var spawnEvery:float = 5.0;
var spawnTimer:float = spawnEvery - 1;

func _ready():
	if !multiplayer.is_server(): queue_free()

func _physics_process(delta):
	spawnTimer += delta
	if spawnTimer > spawnEvery:
		Entity.spawn(bodypath, global_position)
		spawnTimer = 0

extends Node2D

const bodypath:String = "res://objects/enemy.tscn"

@export var spawnEvery:float = 5.0;
var spawnTimer:float = spawnEvery - 0.1;

func _ready():
	if !multiplayer.is_server(): queue_free()

func _physics_process(delta):
	spawnTimer += delta
	if spawnTimer > spawnEvery:
		var ename = str(randi_range(0, 999999999999))
		NetManager.spawnEntity(bodypath, global_position, ename)
		spawnTimer = 0

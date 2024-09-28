class_name Projectile extends Area2D
## Base class for all Projectiles. [br]
## Projectiles are spawned using [method Entity.create_projectile].

## Emitted when the Projectile exceeds its [member ttl]. This should
## lead into a [method Node.queue_free] - if not, the Projectile will do so
## itself after [b]10 seconds.[/b]
signal expire

## Emitted when the Projectile collides with a wall.
signal hit_wall

## Emitted when the Projectile collides with an enemy [Entity].
signal hit_enemy(ent:Entity)

## The default speed this projectile should have when spawned.
@export var default_speed:float = 100;

## The default acceleration this projectile should have when spawned.
@export var default_accel:float = 0;

## Set if this projectile should ignore walls entirely.
## [signal hit_wall] will not emit.
@export var pierceWalls:bool = false;

## The velocity of the projectile.
var velocity:Vector2 = Vector2.ZERO;

## The acceleration of the projectile, to be applied over time.
var accel:Vector2 = Vector2.ZERO;

## The [Entity] that fired this projectile. As such, it can access [Entity]
## fields and methods.
@onready var ent:Entity = get_node("../..") # us -> "projectiles" node -> Entity

## @experimental
## The [Ability] that fired this projectile, if any.
var ability:Ability = null;

## Maximum time-to-live for the Projectile, in seconds. Afterwards,
## the Projectile will emit [signal expire], allowing any expiration effects
## to play out, then automatically call [method Node.queue_free] if it hasn't
## done so already after 10 seconds.
@export var ttl:float = 5
var _lifeTimer:Timer = Timer.new()
var _streamPosTimer:Timer = Timer.new()

## The age of the projectile, in seconds.
var age:float:
	get: return ttl - _lifeTimer.time_left

## The remaining [member ttl] for the projectile, in seconds.
var timeLeft:float:
	get: return _lifeTimer.time_left

func _ready():
	# intangible to everything else - we want only to scan for collisions,
	# not create them.
	collision_layer = 0
	# scan for collisions with the world (1), as well as any characters not on
	# our team
	if is_multiplayer_authority():
		_streamPosTimer.one_shot = false
		_streamPosTimer.timeout.connect(_streamMovement)
		add_child(_streamPosTimer)
		_streamPosTimer.start(0.1)
		collision_mask = (0 if pierceWalls else 1) | 0xFFFFFFC0 ^ (32 << ent.team)
		area_entered.connect(_on_area_entered)
		body_entered.connect(_on_body_entered)
	else:
		collision_mask = 0 # not our job to scan this thing's collisions
	
	_lifeTimer.one_shot = true
	add_child(_lifeTimer)
	_lifeTimer.start(ttl)
	_lifeTimer.timeout.connect(_startDying)

func _process(delta:float) -> void:
	global_position += velocity * delta
	velocity += accel * delta

func _startDying():
	expire.emit()
	_lifeTimer.timeout.disconnect(_startDying)
	# if we haven't removed ourself after 10 seconds just do it already
	_lifeTimer.start(10)
	_lifeTimer.timeout.connect(queue_free)

func _streamMovement():
	_streamMovementRpc.rpc(global_position, velocity)

@rpc("authority", "call_remote", "unreliable_ordered")
func _streamMovementRpc(pos:Vector2, vel:Vector2): 
	global_position = pos
	velocity = vel

# wall hits and enemy hits need to be client authoritative
# these signals will only fire when the authority says so, on all clients 

func _on_area_entered(area:Area2D):
	var e:Entity = area.get_parent() as Entity
	if e:
		_sync_entity_hit.rpc(e.get_path())

@rpc("authority", "call_local", "reliable")
func _sync_entity_hit(path:NodePath):
	hit_enemy.emit(get_node(path))

func _on_body_entered(body:Node2D):
	if body.collision_layer & 1:
		_sync_wall_hit.rpc()

@rpc("authority", "call_local", "reliable")
func _sync_wall_hit():
	hit_wall.emit()

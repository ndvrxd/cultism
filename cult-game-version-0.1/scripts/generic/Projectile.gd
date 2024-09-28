class_name Projectile extends CharacterBody2D
## Base class for all Projectiles.

## Emitted when the Projectile exceeds its [member ttl]. This should
## lead into a [method Node.queue_free] - if not, the Projectile will do so
## itself after [b]10 seconds.[/b]
signal expire

## Emitted when the Projectile collides with a wall.
signal hit_wall

## Emitted when the Projectile collides with an enemy [Entity].
signal hit_enemy(ent:Entity)

## The [Entity] that fired this projectile. As such, it can access [Entity]
## fields and methods.
@onready var ent:Entity = get_node("../..") # us -> "projectiles" node -> Entity

## @experimental
## The [Ability] that fired this projectile, if any.
var ability:Ability = null;

## Maximum time-to-live for the Projectile, in seconds. Afterwards,
## the Projectile will fire [signal expire], allowing any expiration effects
## to play out, then automatically call [method Node.queue_free] if it hasn't
## done so already after 10 seconds.
@export var ttl:float = 5
var _age:float = 0
var _dying:bool = false

func _ready():
	# intangible to everything else - we want only to scan for collisions,
	# not create them
	collision_layer = 0
	# scan for collisions with the world (1), as well as any characters not on
	# our team
	collision_mask = 1 | 0xFFFFFFC1 ^ (32 << ent.team)

func _physics_process(delta:float) -> void:
	pass

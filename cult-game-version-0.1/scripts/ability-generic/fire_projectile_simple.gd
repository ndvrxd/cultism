extends Ability

## The [Projectile] this Ability should fire.
@export var projectileScn:PackedScene
## Whether to fire this Projectile from the foot point
## instead of the shoulder point.
@export var fromFeet:bool = false

func _ready():
	super._ready()
	fired.connect(_on_fired)

func _on_fired() -> void:
	ent.create_projectile(projectileScn, self, 
		global_position if fromFeet else Vector2.ZERO)

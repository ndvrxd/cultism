extends Ability

## The [Projectile] this Ability should fire.
@export var projectileScn:PackedScene

func _ready():
	fired.connect(_on_fired)

func _on_fired() -> void:
	ent.create_projectile(projectileScn)

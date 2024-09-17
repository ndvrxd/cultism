extends Entity

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")
var lockInDirection:Vector2

#any special functionality for the enemy can be overridden here
func _ready():
	super._ready();
	hit_landed.connect(onHit)

func _process(delta:float) -> void:
	if lockInDirection != Vector2.ZERO:
		lookDirection = lockInDirection
	super._process(delta)
	$upright_anchor.scale.x = 1 if lookDirection.x > 0 else -1
	$upright_anchor/eyes.position = Vector2(randf_range(-1.5, 1.5), 3+randf_range(-1.5, 1.5))

func primaryFireAction():
	$telegraph.start()
	$upright_anchor/tell.restart()
	lockInDirection = lookDirection
	stat_speed.modifyMultFlat(-0.99)
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	if is_multiplayer_authority():
		var ent = lineCastFromShoulder(lockInDirection, 100)["entity"]
		if ent:
			if team != ent.team:
				ent.changeHealth.rpc(ent.health, -30, get_path())
	await get_tree().create_timer(0.2).timeout
	stat_speed.modifyMultFlat(0.99)
	lockInDirection = Vector2.ZERO

func onHit(at:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = at
	temp.modulate = Color.RED
	get_parent().add_child(temp)

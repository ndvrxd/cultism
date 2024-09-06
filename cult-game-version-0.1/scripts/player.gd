extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
var swordRange = 100
var swordDamage = 34

var swordHitFx:PackedScene = preload("res://objects/vfx/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)

@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	super.primaryFire(target)
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id(): return
	# everything beyond this point happens clientside
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	for e:Entity in ents:
		if team != e.team:
			e.changeHealth.rpc(e.health, -swordDamage, get_path())
			
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

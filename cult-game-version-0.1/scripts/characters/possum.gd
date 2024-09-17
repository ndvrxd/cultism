extends Entity

@export var gunRange = 3000
@export var gunDamage = 20

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")
var hitscanTracer:PackedScene = preload("res://vfx/objects/hitscan_fx.tscn")

func _ready():
	super._ready()
	hit_landed.connect(onHit)
	primaryCD = 0.4

func _process(delta):
	super._process(delta)
	$Node2D/Sprite2D.flip_h = lookDirection.x < 0

func primaryFireActionAuthority():
		var hit = lineCastFromShoulder(lookDirection, gunRange)
		var ent = hit["entity"]
		if ent:
			if team != ent.team:
				ent.changeHealth.rpc(ent.health, -gunDamage, get_path())

func primaryFireAction():
		$sfx/gunshot.play()
		var hit = lineCastFromShoulder(lookDirection, gunRange, false) #don't trigger hit effects
		var tr = hitscanTracer.instantiate()
		tr.global_position = shoulderPoint.global_position
		tr.setDirection(lookDirection)
		tr.setRange(shoulderPoint.global_position.distance_to(hit["pos"]), 70)
		get_tree().current_scene.add_child(tr)
			
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	temp.modulate = Color.GOLD
	get_parent().add_child(temp)

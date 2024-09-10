extends Entity

var meleeShape:CircleShape2D = CircleShape2D.new()
var aoeShape:CircleShape2D = CircleShape2D.new()
@export var guitarRange = 100
@export var guitarDamage = 20

@export var maxHits = 8;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")
var wololoHitFx:PackedScene = preload("res://vfx/objects/wololo_flash.tscn")
var aoeFx:PackedScene = preload("res://vfx/objects/aoe_burst.tscn")

func _ready():
	super._ready()
	stat_speed = Stat.fromBase(300)
	stat_maxHp = Stat.fromBase(120)
	meleeShape.radius = 100;
	aoeShape.radius = 200;
	hit_landed.connect(onHit)
	primaryCD = 0.9
	activeCD = 25

func _process(delta):
	$Node2D/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)

func primaryFireAction():
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	
func primaryFireActionAuthority():
	var ents = shapeCastFromShoulder(lookDirection*guitarRange, meleeShape, false)
	var hits = 0
	for e:Entity in ents:
		triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
		if team != e.team:
			e.changeHealth.rpc(e.health, -guitarDamage, get_path())
			hits += 1
		if hits >= maxHits:
			break

func activeAbilityAction():
	$AoeBurst.restart()
	var ents = shapeCastFromShoulder(Vector2.ZERO, meleeShape, false)
	for e:Entity in ents:
		if team != e.team:
			var temp = wololoHitFx.instantiate()
			temp.global_position = e.shoulderPoint.global_position
			get_tree().current_scene.add_child(temp)

func activeAbilityActionAuthority():
	var ents = shapeCastFromShoulder(Vector2.ZERO, meleeShape, false)
	for e:Entity in ents:
		if team != e.team:
			e.changeTeam.rpc(team)
	
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

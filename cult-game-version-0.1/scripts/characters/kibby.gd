extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var guitarRange = 100
@export var guitarDamage = 20

@export var maxHits = 8;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")

func _ready():
	super._ready()
	stat_speed = Stat.fromBase(300)
	stat_maxHp = Stat.fromBase(120)
	swordShape.radius = 100;
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
	var ents = shapeCastFromShoulder(lookDirection*guitarRange, swordShape, false)
	var hits = 0
	for e:Entity in ents:
		triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
		if team != e.team:
			e.changeHealth.rpc(e.health, -guitarDamage, get_path())
			hits += 1
		if hits >= maxHits:
			break

func activeAbilityAction():
	pass #wololo aoe here
	
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

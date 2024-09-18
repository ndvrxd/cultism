extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordRange = 76
@export var swordDamage = 20
@export var dmgRange = 5 #set this to 0 for consistent damage (boring imo but yk..) - ndvr :3
@export var maxHits = 7;

# KNIFE THROW, CHANGE EVENTUALLY
@export var gunRange = 3000
@export var gunDamage = 5

@export var maxGunHits = 10;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)
	primaryCD = 0.17
	secondaryCD = 0.25

func _process(delta):
	super._process(delta)
	$upright_anchor/Sprite2D.flip_h = lookDirection.x < 0

func primaryFireAction():
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y

func primaryFireActionAuthority():
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	var hits = 0
	for e:Entity in ents:
		if team != e.team:
			e.changeHealth.rpc(e.health, -randf_range(swordDamage-dmgRange,swordDamage+dmgRange), get_path())
			hits += 1
		if hits >= maxHits:
			break
			
func secondaryFireAction():
	$shoulder/GPUParticles2D.restart()

func secondaryFireActionAuthority():
	var hit = lineCastFromShoulder(lookDirection, gunRange)
	var ent = hit["entity"]
	if ent:
		if team != ent.team:
			ent.changeHealth.rpc(ent.health, -gunDamage, get_path())
			
func onHit(pos:Vector2, _normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

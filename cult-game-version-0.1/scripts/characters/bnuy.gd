extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordRange = 100
@export var swordDamage = 35

@export var maxHits = 3;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)
	primaryCD = 0.65

func _process(delta):
	$upright_anchor/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)

func primaryFireAction():
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	
func primaryFireActionAuthority():
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	var hits = 0
	for e:Entity in ents:
		if team != e.team:
			e.changeHealth.rpc(e.health, -swordDamage, get_path())
			hits += 1
		if hits >= maxHits:
			break 

func secondaryFireAction():
	$shoulder/swordflurry.restart()
	$shoulder/swordflurry2.restart()
	
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordRange = 100
@export var swordDamage = 35

var swingTimer = 0;
@export var swingDelay = 0.65;
@export var maxHits = 3;

var swordHitFx:PackedScene = preload("res://objects/vfx/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)

func _process(delta):
	$upright_anchor/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)
	if swingTimer > 0: swingTimer -= delta

@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	super.primaryFire(target)
	if swingTimer <= 0:
		$shoulder/swordwoosh.restart()
		$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
		swingTimer = swingDelay
		if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id(): return
	# everything beyond this point happens clientside
		var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
		var hits = 0
		for e:Entity in ents:
			if team != e.team:
				e.changeHealth.rpc(e.health, -swordDamage, get_path())
				hits += 1
			if hits >= maxHits:
				break 
			
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

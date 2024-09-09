extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordRange = 100
@export var swordDamage = 35

@export var maxHits = 3;

var charged:bool = false;
@export var chargeSlashDamage = 8;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)
	primaryCD = 0.65
	$chargeblink.timeout.connect(chargeblink)
	$chargetimer.timeout.connect(chargetimer_end)
	$chargeslash_hit.timeout.connect(chargeslash_hit)
	$chargeslash_end.timeout.connect(chargeslash_end)

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

@rpc("any_peer", "call_local", "reliable")
func secondaryFire(target:Vector2) -> void:
	super.secondaryFire(target)
	if $chargeslash_end.time_left <= 0:
		$chargetimer.start()
		$chargeblink.start()

@rpc("any_peer", "call_local", "reliable")
func secondaryFireReleased(target:Vector2) -> void:
	super.secondaryFireReleased(target)
	$chargetimer.stop()
	$chargeblink.stop()
	if charged:
		$shoulder/swordflurry.restart()
		$shoulder/swordflurry2.restart()
		$shoulder/charged_loop.emitting = false
		if is_multiplayer_authority():
			$chargeslash_hit.start()
			$chargeslash_end.start()
	charged=false

func chargeblink():
	var temp = $upright_anchor/Sprite2D.modulate
	$upright_anchor/Sprite2D.modulate = Color.YELLOW
	await get_tree().create_timer(0.05).timeout
	$upright_anchor/Sprite2D.modulate = temp

func chargetimer_end():
	charged = true
	$chargeblink.stop()
	$shoulder/charged.restart()
	$shoulder/charged_loop.emitting=true

func chargeslash_end():
	$chargeslash_hit.stop()

func chargeslash_hit():
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	for e:Entity in ents:
		if team != e.team:
			e.changeHealth.rpc(e.health, -chargeSlashDamage, get_path())
	
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

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
	stat_speed = Stat.fromBase(300)
	swordShape.radius = 50;
	hit_landed.connect(onHit)
	primaryCD = 0.65
	activeCD = 12
	$chargeblink.timeout.connect(chargeblink)
	$chargetimer.timeout.connect(chargetimer_end)
	$chargeslash_hit.timeout.connect(chargeslash_hit)

func _process(delta):
	$upright_anchor.scale.x = -1 if lookDirection.x < 0 else 1
	#$upright_anchor/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)

func primaryFireAction():
	if charged or $chargetimer.time_left > 0: return
	$sfx_swordwoosh.play()
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	await get_tree().create_timer(0.1).timeout
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape, false)
	var hits = 0
	for e:Entity in ents:
		if is_multiplayer_authority():
			triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
		if team != e.team:
			if is_multiplayer_authority():
				e.changeHealth.rpc(e.health, -swordDamage, get_path())
			hits += 1
		if hits >= maxHits:
			break
	if hits > 0:
		$sfx_swordhit.play()
	elif !ents.is_empty():
		$sfx_swordping.play()

func activeAbilityAction():
	stat_speed.modifyBase(100)
	$upright_anchor/speedup.emitting=true
	await get_tree().create_timer(6).timeout
	stat_speed.modifyBase(-100)
	$upright_anchor/speedup.emitting=false

#region secondary fire methods

@rpc("any_peer", "call_local", "reliable")
func secondaryFire(target:Vector2) -> void:
	super.secondaryFire(target)
	# charging an attack needs to be cancelable - use an existing Timer node
	$sfx_chargestance.play()
	$chargetimer.start()
	$chargeblink.start()
	chargeblink()

func chargeblink():
	var temp = $upright_anchor/Sprite2D.modulate
	$upright_anchor/Sprite2D.modulate = Color.YELLOW
	await get_tree().create_timer(0.05).timeout
	$upright_anchor/Sprite2D.modulate = temp

func chargetimer_end():
	charged = true
	$sfx_chargecomplete.play()
	$chargeblink.stop()
	$upright_anchor/charged.restart()
	$upright_anchor/charged_loop.emitting=true

@rpc("any_peer", "call_local", "reliable")
func secondaryFireReleased(target:Vector2) -> void:
	super.secondaryFireReleased(target)
	$chargetimer.stop()
	$chargeblink.stop()
	if charged:
		charged = false
		primaryTimer = 0.65 # lock other abilities for the duration
		secondaryTimer = 0.65
		$shoulder/swordflurry.restart()
		$shoulder/swordflurry2.restart()
		$upright_anchor/charged_loop.emitting = false
		$chargeslash_hit.start()
		await get_tree().create_timer(0.65).timeout
		$chargeslash_hit.stop()

func chargeslash_hit():
	# play a sound effect here?
	$sfx_swordflurry.play()
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	if !ents.is_empty():
		$sfx_flurryhit.play()
	if is_multiplayer_authority():
		for e:Entity in ents:
			if team != e.team:
				e.changeHealth.rpc(e.health, -chargeSlashDamage, get_path())

#endregion

func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

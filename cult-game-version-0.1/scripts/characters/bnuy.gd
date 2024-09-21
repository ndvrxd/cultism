extends Entity

@export var maxHits = 3;

func _process(delta):
	$upright_anchor.scale.x = -1 if lookDirection.x < 0 else 1
	super._process(delta)

func primaryFireAction():
	$sfx_swordwoosh.play()
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	await get_tree().create_timer(0.1).timeout
	var ents = []#shapeCastFromShoulder(lookDirection*swordRange, swordShape, false)
	var hits = 0
	for e:Entity in ents:
		if is_multiplayer_authority():
			triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
		if team != e.team:
			if is_multiplayer_authority():
				pass#e.changeHealth.rpc(e.health, -swordDamage, get_path())
			hits += 1
		if hits >= maxHits:
			break
	if hits > 0:
		$sfx_swordhit.play()
	elif !ents.is_empty():
		$sfx_swordping.play()

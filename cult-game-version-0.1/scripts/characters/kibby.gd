extends Entity

var meleeShape:CircleShape2D = CircleShape2D.new()
var aoeShape:CircleShape2D = CircleShape2D.new()
@export var guitarRange = 50
@export var guitarDamage = 18
@export var lightningDamage = 30

@export var maxHits = 8;

@onready var snd_lightning:AudioStreamMP3 = load("res://sound/fx/thunder.mp3")

var lightningMeter = 0;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")
var wololoHitFx:PackedScene = preload("res://vfx/objects/wololo_flash.tscn")
var aoeFx:PackedScene = preload("res://vfx/objects/aoe_burst.tscn")
var aoeDmg:PackedScene = preload("res://objects/aoe_dmg.tscn")

var tween:Tween;

func _ready():
	super._ready()
	meleeShape.radius = 100;
	aoeShape.radius = 200;
	hit_landed.connect(onHit)
	primaryCD = 0.9
	activeCD = 25
	$AoeHitboxTick.timeout.connect(starstruckTick)

func _process(delta):
	$Node2D.scale.x = -1 if lookDirection.x < 0 else 1
	$Node2D/lightningbar.value = lightningMeter * 100
	if $AoePreview.visible:
		$AoePreview.global_position = aimPosition
	super._process(delta)

@rpc("authority", "call_local", "reliable")
func syncLightningMeter(value:float) -> void:
	lightningMeter = value

func primaryFireAction():
	$snd_whiff.play()
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	await get_tree().create_timer(0.15).timeout
	var ents = shapeCastFromShoulder(lookDirection.normalized()*guitarRange, meleeShape, false)
	var hits = 0
	for e:Entity in ents:
		if team != e.team:
			lightningMeter += 0.04
			if is_multiplayer_authority():
				e.changeHealth.rpc(e.health, -guitarDamage, get_path())
				triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
				syncLightningMeter.rpc(lightningMeter)
			if lightningMeter >= 1 and not $Node2D/m2readyloop.emitting:
				$snd_secondarycharged.play()
				$Node2D/m2readyloop.emitting = true
				$Node2D/m2readycue.restart()
			hits += 1
		if hits > 0:
			$snd_guitarhit.play()
		if hits >= maxHits:
			break

@rpc("any_peer", "call_local", "reliable")
func secondaryFire(target:Vector2):
	super.secondaryFire(target)
	$AoePreview.global_position = aimPosition
	if is_multiplayer_authority():
		syncLightningMeter.rpc(lightningMeter)
	#await get_tree().create_timer(0.1).timeout
	$AoePreview.visible = true;

@rpc("any_peer", "call_local", "reliable")
func secondaryFireReleased(target:Vector2):
	super.secondaryFireReleased(target)
	if lightningMeter < 1 or !$AoePreview.visible:
		$Node2D/lightningbar.tint_under = Color.RED
		if is_instance_valid(tween):
			tween.kill()
		tween = get_tree().create_tween()
		tween.tween_property($Node2D/lightningbar, "tint_under",
			Color(Color.RED, 0), 0.5)
		$AoePreview.visible=false
		return
	var temp = aoeFx.instantiate()
	temp.global_position = aimPosition
	temp.scale = Vector2(aoeShape.radius / 50, aoeShape.radius / 50)
	temp.modulate = Color.DEEP_SKY_BLUE
	temp.lifetime = 0.2
	temp.fixed_fps = 60
	get_tree().current_scene.add_child(temp)
	var sfx:AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sfx.stream = snd_lightning
	sfx.global_position = aimPosition
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	lightningMeter = 0
	$Node2D/m2readyloop.emitting = false
	$AoePreview.visible = false
	if is_multiplayer_authority():
		temp = aoeDmg.instantiate()
		temp.global_position = aimPosition
		temp.scale = Vector2(aoeShape.radius, aoeShape.radius)
		temp.damage = lightningDamage
		temp.team = team
		temp.inflictor = get_path()
		get_tree().current_scene.add_child(temp)
	await get_tree().create_timer(5).timeout
	sfx.queue_free()

func activeAbilityAction():
	$AoeBurst.restart()
	$AoeHitboxTick.start()
	$snd_starstruck.play()
	primaryTimer = 2
	if is_multiplayer_authority(): stat_speed.modifyMultFlat(-0.99)
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.65).timeout
	$AoeHitboxTick.stop()
	await get_tree().create_timer(1.45).timeout
	if is_multiplayer_authority(): stat_speed.modifyMultFlat(0.99)

func starstruckTick():
	var ents = shapeCastFromShoulder(Vector2.ZERO, aoeShape, false)
	for e:Entity in ents:
		if team != e.team:
			var temp = wololoHitFx.instantiate()
			temp.global_position = e.shoulderPoint.global_position
			get_tree().current_scene.add_child(temp)
			if is_multiplayer_authority():
				e.changeTeam.rpc(team)
	
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

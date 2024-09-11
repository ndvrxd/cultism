extends Entity

var meleeShape:CircleShape2D = CircleShape2D.new()
var aoeShape:CircleShape2D = CircleShape2D.new()
@export var guitarRange = 100
@export var guitarDamage = 18
@export var lightningDamage = 30

@export var maxHits = 8;

@onready var snd_lightning:AudioStreamMP3 = load("res://sound/fx/thunder.mp3")

var lightningMeter = 0;

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")
var wololoHitFx:PackedScene = preload("res://vfx/objects/wololo_flash.tscn")
var aoeFx:PackedScene = preload("res://vfx/objects/aoe_burst.tscn")
var aoeDmg:PackedScene = preload("res://objects/aoe_dmg.tscn")

func _ready():
	super._ready()
	stat_speed = Stat.fromBase(300)
	stat_maxHp = Stat.fromBase(120)
	meleeShape.radius = 100;
	aoeShape.radius = 200;
	hit_landed.connect(onHit)
	primaryCD = 0.9
	activeCD = 25
	$AoeHitboxTick.timeout.connect(starstruckTick)

func _process(delta):
	$Node2D.scale.x = sign(lookDirection.x)
	$Node2D/lightningbar.value = lightningMeter * 100
	super._process(delta)

@rpc("authority", "call_local", "reliable")
func syncLightningMeter(value:float) -> void:
	lightningMeter = value

func primaryFireAction():
	$snd_whiff.play()
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	await get_tree().create_timer(0.15).timeout
	var ents = shapeCastFromShoulder(lookDirection*guitarRange, meleeShape, false)
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

func secondaryFireAction():
	if lightningMeter < 1: return
	var temp = aoeFx.instantiate()
	temp.global_position = aimPosition
	temp.scale = Vector2(aoeShape.radius / 50, aoeShape.radius / 50)
	temp.modulate = Color.CORNFLOWER_BLUE
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
	stat_speed.modifyMultFlat(-0.99)
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.65).timeout
	$AoeHitboxTick.stop()
	await get_tree().create_timer(1.45).timeout
	stat_speed.modifyMultFlat(0.99)

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

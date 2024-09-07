extends Entity


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	stat_speed = Stat.fromBase(500);
	stat_maxHp = Stat.fromBase(75);
	swordShape.radius = 50;
	hit_landed.connect(onHit)

#EVERYTHING BENEATH THIS I COPIED FROM PLAYER.GD TO MAKE POSSUM PLAYABLE
#ITS PROLLY INEFFICIENT BUT IT WORKS FOR NOW ANIMATIONS AND ALL
#-ndvr :3 
#(ps this proly fukin sux i dont see why i cant just extend player.gd or smthn butttt im just playin around here)

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordWoosh:GPUParticles2D;
@export var swordRange = 100
@export var swordDamage = 34

var swingTimer = 0;
@export var swingDelay = 0.65;
@export var maxHits = 3;

var swordHitFx:PackedScene = preload("res://objects/vfx/sword_hit.tscn")



func _process(delta):
	super._process(delta)
	if swingTimer > 0: swingTimer -= delta

@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	super.primaryFire(target)
	if swingTimer <= 0:
		$shoulder/swordwoosh.restart()
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
		swingTimer = swingDelay
			
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	get_parent().add_child(temp)

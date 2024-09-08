extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var swordRange = 75
@export var swordDamage = 20
@export var dmgRange = 5 #set this to 0 for consistent damage (boring imo but yk..) - ndvr :3

var swingTimer = 0;
@export var swingDelay = 0.17;
@export var maxHits = 7;

# KNIFE THROW, CHANGE EVENTUALLY
@export var gunRange = 3000
@export var gunDamage = 5

var gunTimer = 0;
@export var gunDelay = 0.25;
@export var maxGunHits = 10;

var holdingPrimary:bool = false
var holdingSecondary:bool = false

var swordHitFx:PackedScene = preload("res://vfx/objects/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)

func _process(delta):
	$upright_anchor/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)
	if swingTimer > 0: swingTimer -= delta
	if gunTimer > 0: gunTimer -= delta #NOT GOOD SOLUTION, CLEAN UP LATER

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if swingTimer <= 0 and holdingPrimary:
		primaryFireAction()
	elif gunTimer <= 0 and holdingSecondary:
		secondaryFireAction()

#PLAYER INPUT HANDLERS
@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	super.primaryFire(target)
	holdingPrimary = true;
	
@rpc("any_peer", "call_local", "reliable")
func primaryFireReleased(target:Vector2) -> void:
	super.primaryFire(target)
	holdingPrimary = false;
	
@rpc("any_peer", "call_local", "reliable")
func secondaryFire(target:Vector2) -> void:
	super.secondaryFire(target)
	holdingSecondary = true;
	
@rpc("any_peer", "call_local", "reliable")
func secondaryFireReleased(target:Vector2) -> void:
	super.secondaryFire(target)
	holdingSecondary = false
	
#ON PLAYER INPUT
func primaryFireAction():
	$shoulder/swordwoosh.restart()
	$shoulder/swordwoosh.scale.y = -$shoulder/swordwoosh.scale.y
	swingTimer = swingDelay
	#if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id(): return
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	# TODO: until we have proper authority handling implemented,
	# this makes hit calculations happen serverside. Fuck,
# everything beyond this point happens clientside
	var ents = shapeCastFromShoulder(lookDirection*swordRange, swordShape)
	var hits = 0
	for e:Entity in ents:
		if team != e.team:
			e.changeHealth.rpc(e.health, -randf_range(swordDamage-dmgRange,swordDamage+dmgRange), get_path())
			hits += 1
		if hits >= maxHits:
			break
				
func secondaryFireAction():
	#EVENTUALLY ABSTRACT OUT BASIC COMBAT OPERATIONS LIKE SWINGS OR GUNSHOTS
	$shoulder/GPUParticles2D.restart()
	gunTimer = gunDelay
	
	if get_multiplayer_authority() != multiplayer.get_unique_id(): return
	
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

extends Entity

var swordShape:CircleShape2D = CircleShape2D.new()
@export var gunRange = 3000
@export var gunDamage = 20

var swingTimer = 0;
@export var swingDelay = 0.4;
var holdingPrimary:bool = false

var swordHitFx:PackedScene = preload("res://objects/vfx/sword_hit.tscn")

func _ready():
	super._ready()
	swordShape.radius = 50;
	hit_landed.connect(onHit)

func _process(delta):
	$Node2D/Sprite2D.flip_h = lookDirection.x < 0
	super._process(delta)
	if swingTimer > 0: swingTimer -= delta

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if swingTimer <= 0 and holdingPrimary:
		$shoulder/GPUParticles2D.restart()
		swingTimer = swingDelay
		#if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id(): return
		if get_multiplayer_authority() != multiplayer.get_unique_id(): return
		# TODO: until we have proper authority handling implemented,
		# this makes hit calculations happen serverside. Fuck,
	# everything beyond this point happens clientside
		var hit = lineCastFromShoulder(lookDirection, gunRange)
		var ent = hit["entity"]
		if ent:
			if team != ent.team:
				ent.changeHealth.rpc(ent.health, -gunDamage, get_path())

@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	super.primaryFire(target)
	holdingPrimary = true;
	
@rpc("any_peer", "call_local", "reliable")
func primaryFireReleased(target:Vector2) -> void:
	super.primaryFire(target)
	holdingPrimary = false;
			
func onHit(pos:Vector2, normal:Vector2):
	var temp = swordHitFx.instantiate()
	temp.emitting = true
	temp.global_position = pos
	temp.modulate = Color.GOLD
	get_parent().add_child(temp)

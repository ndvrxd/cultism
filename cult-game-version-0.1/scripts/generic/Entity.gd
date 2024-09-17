class_name Entity extends CharacterBody2D

# Base class for all Entities - networked actors with stats, health bars,
# and the like. Movement code & health stuff is handled here

#signals & hooks for passive items and upgrades and anything else that needs it
signal damage_taken(amount:float, from:Entity)
signal damage_dealt(amount:float, to:Entity)
signal healed(amount:float, by:Entity)
signal hit_landed(at:Vector2, normal:Vector2)
signal killed(by:Entity)

@export var entityName:String = "Entity";
@export var team:int = 0;
@export var objPath:String = ""
@export var controllerPath:String = ""
@export var healthBarColor:Color = Color.LIME_GREEN;
var controllerAttached:bool = false;

var healthBar:TextureProgressBar
var healthBarTimer:float = 0;
var healthBarShakeTimer:float = 0;
 
const damageNumberScn:PackedScene = preload("res://objects/damageNumber.tscn")
const healthBarScn:PackedScene = preload("res://objects/healthBar.tscn")

var moveIntent:Vector2 = Vector2.ZERO;
var lookDirection:Vector2 = Vector2.UP;
# TODO: allow lookDirection into lookAngle conversion
	# NOTE: this may not actually be necessary
var aimPosition:Vector2 = Vector2.ZERO;

var stat_maxHp:Stat
var stat_speed:Stat
var stat_accel:Stat
var stat_regen:Stat
# "aggro" stats get used by entity controllers for target selection
var stat_aggroRange:Stat
var stat_aggroNoise:Stat

# TODO replace these with Stats when the Stat rework rolls around
@export var primaryCD:float = 1;
@export var secondaryCD:float = 1;
@export var activeCD:float = 20;
var primaryTimer:float = 0;
var secondaryTimer:float = 0;
var activeTimer:float = 0;
var holdingPrimary:bool = false;
var holdingSecondary:bool = false;

var health:float = 1
var regenTimer:float = 0

var shoulderPoint:Node2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("entity"); # for polling all active entities
	
	var defaultStats = {
		"stat_maxHp": 100,
		"stat_speed": 400,
		"stat_accel": 8.5,
		"stat_regen": 0,
		"stat_aggroRange": 250,
		"stat_aggroNoise": 0
	}
	for key in defaultStats:
		if !has_node(key):
			add_child(Stat.fromBase(defaultStats[key], key))
	stat_maxHp = $stat_maxHp
	stat_speed = $stat_speed
	stat_accel = $stat_accel
	stat_regen = $stat_regen
	stat_aggroRange = $stat_aggroRange
	stat_aggroNoise = $stat_aggroNoise
	
	shoulderPoint = get_node("shoulder")
	if shoulderPoint == null:
		var temp = Node2D.new();
		temp.name = "shoulder";
		add_child(temp);
		shoulderPoint = temp;
		
	# health bars only need to be shown in visible game windows
	# otherwise, we don't need to instantiate or drive them
	if !NetManager.IsDedicated():
		var hbscn = healthBarScn.instantiate()
		add_child(hbscn)
		healthBar = hbscn.get_node("healthbar")
		healthBar.position.y = (shoulderPoint.global_position.y - global_position.y) * 2
		healthBar.tint_progress = healthBarColor
		healthBar.visible = false;
	
	# ensure any stat changes by child class are reflected,
	# regardless of super._ready() being called before or after:
	afterStatsSet.call_deferred()

func afterStatsSet():
	health = stat_maxHp.val

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.x = move_toward(velocity.x / stat_speed.val, moveIntent.x, stat_accel.val * delta) * stat_speed.val
	velocity.y = move_toward(velocity.y / stat_speed.val, moveIntent.y, stat_accel.val * delta) * stat_speed.val
	move_and_slide()
	
	if shoulderPoint: #aiming
		shoulderPoint.look_at(shoulderPoint.global_position + lookDirection)
		
	if regenTimer > 0:
		regenTimer -= delta
	else:
		health = min(health + stat_regen.val * delta, stat_maxHp.val)
	
	if healthBarTimer > 0 && !NetManager.IsDedicated():
		if !healthBar.visible: healthBar.visible = true
		healthBarTimer -= delta
		healthBar.value = (health / stat_maxHp.val) * 100
		if healthBarShakeTimer > 0:
			var tc = healthBar.tint_under
			if healthBarShakeTimer > 0.25 or (healthBarShakeTimer <= 0.25 and tc.r > 0.5):
				healthBar.set_tint_under(Color(1-tc.r, 1-tc.g, 1-tc.b, tc.a))
			healthBarShakeTimer -= delta
			healthBar.rotation = sin(Time.get_unix_time_from_system()*70) * healthBarShakeTimer * 0.3
		else:
			healthBar.rotation = 0;
	elif healthBarTimer < 0:
		healthBar.visible = false
		healthBarTimer = 0

func _physics_process(delta: float) -> void:
	moveIntent = moveIntent.normalized();
	lookDirection = lookDirection.normalized();
	# if a controller is attached that PROBABLY means our client has control over this bitch
	# so we need to be the one to stream the movement
	if controllerAttached: streamMovement.rpc(global_position, moveIntent,
									lookDirection, aimPosition)
	
	if holdingPrimary and primaryTimer <= 0:
		primaryFireAction()
		if get_multiplayer_authority() == multiplayer.get_unique_id():
			primaryFireActionAuthority()
		primaryTimer = primaryCD
	if holdingSecondary and secondaryTimer <= 0:
		secondaryFireAction()
		if get_multiplayer_authority() == multiplayer.get_unique_id():
			secondaryFireActionAuthority()
		secondaryTimer = secondaryCD
	if primaryTimer > 0: primaryTimer -= delta
	if secondaryTimer > 0: secondaryTimer -= delta
	if activeTimer > 0: activeTimer -= delta


# what i'm thinking is that the authority for each entity
# can attach a controller to it clientside, and the controller can make
# Entity RPC calls from within itself so shit gets synced for everyone
# from within a script that ISNT synced for everyone

# static "spawn" method for all entities
# use this instead of NetManager.spawnEntityRpc.rpc
# exists to ensure network sync by determining the entity's name & nodepath clientside
static func spawn(scnPath:String, pos:Vector2=Vector2.ZERO, ctlPath:String="", playerName:String=""):
	var isPlayer:bool = false;
	if playerName == "":
		playerName = str(randi_range(0, 999999999999))
	else:
		ctlPath = NetManager.PLAYERCONTROLSOBJ
		isPlayer = true;
	NetManager.spawnEntityRpc.rpc(scnPath, pos, ctlPath, playerName, isPlayer) 

@rpc("any_peer", "call_local", "reliable")
func changeTeam(newTeam:int) -> void:
	team = newTeam

# networked callbacks for use by controller and items
@rpc("any_peer", "call_local", "reliable")
func primaryFire(target:Vector2) -> void:
	aimPosition = target
	holdingPrimary = true

@rpc("any_peer", "call_local", "reliable")
func secondaryFire(target:Vector2) -> void:
	aimPosition = target
	holdingSecondary = true

@rpc("any_peer", "call_local", "reliable")
func primaryFireReleased(target:Vector2) -> void:
	aimPosition = target
	holdingPrimary = false

@rpc("any_peer", "call_local", "reliable")
func secondaryFireReleased(target:Vector2) -> void:
	aimPosition = target
	holdingSecondary = false

@rpc("any_peer", "call_local", "reliable")
func activeAbilityRpc(target:Vector2) -> void:
	if activeTimer > 0: return
	aimPosition = target
	activeAbilityAction()
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		activeAbilityActionAuthority()
	activeTimer = activeCD;

# mmmmaybe use these hooks from now on
func primaryFireAction() -> void: pass
func secondaryFireAction() -> void: pass
func primaryFireActionAuthority() -> void: pass
func secondaryFireActionAuthority() -> void: pass
func activeAbilityAction() -> void: pass
func activeAbilityActionAuthority() -> void: pass

@rpc("any_peer", "call_local", "reliable")
func chat(_msg:String) -> void:
	pass #I FULLY INTEND TO USE THIS OUR CURRENT CHATBOX IS PLACEHOLDER

@rpc("any_peer", "call_local", "reliable")
func spawn_something() -> void:
	pass # idk how to make this work
	# TODO: split network spawn-something rpc off into like 3 things -> ...
		# - spawnEffect for particles and such, any_peer
		# - spawnProjectile for projectiles, any_peer
		# - hitscan can be clientside, it feels better that way in coop
		# - and SpawnEntity i guess can be a thing but only host authoritative-
		# it'd only run it for everyone when called within an RPC 
		# on the server side. when we start to enforce client/host authority,
		# we'll need to do this!!!
			# TODO, again: ALSO RESEARCH CLIENT AUTHORITY RULES
			# how do i hand off authority to a specific client
			# to call entity network methods like streamMovement and such,
			# without anyone else being able to do it on their behalf?
			# any_peer is, after all, callable by *any peer*

@rpc("any_peer", "call_local", "reliable")
func changeHealth(current:float, by:float, inflictor_path:String="") -> void:
	# current health needs to be passed in to sync health between clients!
	health = current;
	health += by;
	healthBarTimer = 2;
	var inflictor = get_node(inflictor_path)
	var dn:Node2D = damageNumberScn.instantiate()
	dn.set_number(int(abs(by)))
	dn.global_position = shoulderPoint.global_position
	get_tree().current_scene.add_child(dn)
	if sign(by) == -1:
		regenTimer = 2
		damage_taken.emit(-by, inflictor)
		if team == 1: dn.set_color(Color.RED) #red is bad for players & allies
		if inflictor != null:
			inflictor.damage_dealt.emit(-by, self)
		healthBarShakeTimer = 0.3
	elif sign(by) == 1:
		healed.emit(by, inflictor)
		dn.set_color(Color.GREEN)
	else:
		# when the host is syncing entity health for joining players,
		# it'll pass in their current health with a delta of 0.
		# this ensures every entity has the correct amount of health on all clients,
		# from the very beginning of the game, or dropping in midway through.
		# no healthbar needs to be shown for this
		healthBarTimer = 0
		#dn.queue_free()
	if health <= 0:
		health = 0
		die(inflictor_path) # needs to be called on the clientside, since we're already in an RPC

@rpc("any_peer", "call_local", "reliable")
func die(killedBy_path:String="") -> void:
	killed.emit(get_node(killedBy_path))
	queue_free() # ideally, play some effects on death

@rpc("any_peer", "call_remote", "unreliable_ordered")
func streamMovement(pos:Vector2, intent:Vector2, lookDir:Vector2, aimPos:Vector2):
	global_position = pos;
	moveIntent = intent.normalized();
	lookDirection = lookDir.normalized();
	aimPosition = aimPos;

@rpc("any_peer", "call_local", "reliable")
func triggerHitEffectsRpc(at:Vector2, normal:Vector2=Vector2.ZERO) -> void:
	hit_landed.emit(at, normal)

func lineCastFromShoulder(direction:Vector2, range:float, triggerHitEffects=true) -> Dictionary:
	# hitscan. turns out shape/linecast in godot is tedious as fuck,
	# so i'm making a nice clean method for it instead.
	# returns the Entity hit, if any, the position hit, if any,
	# and the normal of the surface hit, if any.
	var endpoint:Vector2 = shoulderPoint.global_position + direction.normalized() * range
	
	var physics_query = PhysicsRayQueryParameters2D.create(
			shoulderPoint.global_position,
			endpoint
			# TODO: set collision flags here
		)
	physics_query.set_collide_with_areas(true);
	
	var hit = get_world_2d().direct_space_state.intersect_ray(
		physics_query
	)
	if hit.is_empty():
		return {
			"entity": null,
			"pos": endpoint,
			"normal": Vector2.ZERO
		} #all this may not be necessary
	if triggerHitEffects:
		triggerHitEffectsRpc.rpc(hit["position"], hit["normal"])
	return {
		"entity": hit["collider"].get_parent() as Entity,
		"pos": hit["position"],
		"normal": hit["normal"]
	}

func shapeCastFromShoulder(motion:Vector2, shape:Shape2D=null, triggerHitEffects=true) -> Array[Entity]:
	# see above. why do i have to do this
	var params:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.set_collide_with_bodies(false)
	params.set_collide_with_areas(true)
	
	var fuck:Transform2D = Transform2D(Vector2.RIGHT, Vector2.DOWN, shoulderPoint.global_position)
	if shape == null:
		shape = CircleShape2D.new();
		shape.radius = 50
		
	params.shape = shape
	params.transform = fuck
	params.motion = motion
	
	var hits = get_world_2d().direct_space_state.intersect_shape(params)
	var result:Array[Entity] = []
	for i in hits:
		var collider = i["collider"].get_parent()
		if collider is Entity:
			var e:Entity = collider as Entity
			if not self == e:
				if triggerHitEffects:
					triggerHitEffectsRpc.rpc(e.shoulderPoint.global_position)
				result.append(e)
	return result;

func interact() -> Interactable:
	# see above. why do i have to do this
	var params:PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.set_collide_with_bodies(false)
	params.set_collide_with_areas(true)
	
	var fuck:Transform2D = Transform2D(Vector2.RIGHT, Vector2.DOWN, shoulderPoint.global_position)
	
	var shape = CircleShape2D.new();
	shape.radius = 50
		
	params.shape = shape
	params.transform = fuck
	params.motion = lookDirection * 100
	
	var hits = get_world_2d().direct_space_state.intersect_shape(params)
	for i in hits:
		var collider = i["collider"]
		if collider is Interactable:
			var intr = collider as Interactable
			intr.trigger_interact_rpc.rpc(get_path())
			return intr
	return null;

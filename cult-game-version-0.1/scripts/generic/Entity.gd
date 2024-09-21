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
@export var aggroPriority:int = 0
@export var healthBarColor:Color = Color.LIME_GREEN;
@export var frozen:bool = false

@export var abilities:Array[Ability] = []
var ability_vars:Dictionary = {}

var controllerAttached:bool = false;

var healthBar:TextureProgressBar
var healthBarTimer:float = 0;
var healthBarShakeTimer:float = 0;
 
const damageNumberScn:PackedScene = preload("res://objects/damageNumber.tscn")
const healthBarScn:PackedScene = preload("res://objects/healthBar.tscn")

var moveIntent:Vector2 = Vector2.ZERO;
var lookDirection:Vector2 = Vector2.UP; #lookDirection is a Vector2, not an angle!
var aimPosition:Vector2 = Vector2.ZERO;

#there is 100% a cleaner way to write this but right now i don't care to find it
@onready var stat_maxHp:Stat = $stat_maxHp if has_node("stat_maxHp") \
		else Stat.fromBase(100, "stat_maxHp", self) # both returns the Stat and adds it to the tree
@onready var stat_speed:Stat = $stat_speed if has_node("stat_speed") \
		else Stat.fromBase(400, "stat_speed", self)
@onready var stat_accel:Stat = $stat_accel if has_node("stat_accel") \
		else Stat.fromBase(8.5, "stat_accel", self)
@onready var stat_regen:Stat = $stat_regen if has_node("stat_regen") \
		else Stat.fromBase(0, "stat_regen", self)
@onready var stat_aggroRange:Stat = $stat_aggroRange if has_node("stat_aggroRange") \
		else Stat.fromBase(250, "stat_aggroRange", self)
@onready var stat_aggroNoise:Stat = $stat_aggroNoise if has_node("stat_aggroNoise") \
		else Stat.fromBase(0, "stat_aggroNoise", self)
@onready var stat_swingSpeed:Stat = $stat_swingSpeed if has_node("stat_swingSpeed") \
		else Stat.fromBase(1, "stat_swingSpeed", self)
@onready var stat_baseDamage:Stat = $stat_baseDamage if has_node("stat_baseDamage") \
		else Stat.fromBase(30, "stat_baseDamage", self)

var health:float = 1
var regenTimer:float = 0

var shoulderPoint:Node2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("entity"); # for polling all active entities
	
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
	
	if shoulderPoint: #aiming
		shoulderPoint.look_at(shoulderPoint.global_position + lookDirection)
		
	if regenTimer > 0:
		regenTimer -= delta
	else:
		health = min(health + stat_regen.val * delta, stat_maxHp.val)
	
	#really, this should be an Animation of some kind
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
	if !frozen:
		velocity.x = move_toward(velocity.x / stat_speed.val, moveIntent.x, stat_accel.val * delta) * stat_speed.val
		velocity.y = move_toward(velocity.y / stat_speed.val, moveIntent.y, stat_accel.val * delta) * stat_speed.val
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	moveIntent = moveIntent.normalized();
	lookDirection = lookDirection.normalized();
	# if a controller is attached that PROBABLY means our client has control over this bitch
	# so we need to be the one to stream the movement
	if controllerAttached: streamMovement.rpc(global_position, moveIntent,
									lookDirection, aimPosition)

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

@rpc("any_peer", "call_local", "reliable")
func setAbilityPressed(id:int, pressed:bool, target:Vector2=Vector2.ZERO):
	if target != Vector2.ZERO:
		aimPosition = target
	if id < abilities.size() and abilities[id] != null and is_instance_valid(abilities[id]):
		abilities[id].press() if pressed else abilities[id].release()

@rpc("any_peer", "call_local", "reliable")
func chat(_msg:String) -> void:
	pass #I FULLY INTEND TO USE THIS OUR CURRENT CHATBOX IS PLACEHOLDER

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
			"pos": Vector2.ZERO,
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

class_name Entity extends CharacterBody2D

# Base class for all Entities - networked actors with stats, health bars,
# and the like. Movement code & health stuff is handled here

#signals & hooks for passive items and upgrades and anything else that needs it
signal damage_taken(amount:float, from:Entity)
signal damage_dealt(amount:float, to:Entity)
signal healed(amount:float, by:Entity)
signal hit_landed(at:Vector2)
signal killed(by:Entity)

@export var entityName:String = "Entity";
@export var team:int = 0;
@export var objPath:String = ""
@export var controllerPath:String = ""
@export var healthBarColor:Color = Color(1, 1, 1);
var controllerAttached:bool = false;

const HEALTHBAR_SCENE = "res://objects/healthBar.tscn"
var healthBar:TextureProgressBar
var healthBarTimer:float = 0;
var healthBarShakeTimer:float = 0;

var moveIntent:Vector2 = Vector2.ZERO;
var lookDirection:Vector2 = Vector2.UP;
# TODO: allow lookDirection into lookAngle conversion
	# NOTE: this may not actually be necessary

@export var stat_maxHp:Stat = Stat.fromBase(100);
@export var stat_speed:Stat = Stat.fromBase(400);
@export var stat_accel:Stat = Stat.fromBase(8.5);
@export var stat_regen:Stat = Stat.fromBase(0);
# "aggro" stats get used by entity controllers for target selection
@export var stat_aggroRange:Stat = Stat.fromBase(1000);
@export var stat_aggroNoise:Stat = Stat.fromBase(0);

var health:float = 1

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
		var hbscn = preload(HEALTHBAR_SCENE).instantiate()
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
	
	if healthBarTimer > 0 && !NetManager.IsDedicated():
		if !healthBar.visible: healthBar.visible = true
		healthBarTimer -= delta
		healthBar.value = (health / stat_maxHp.val) * 100
		if healthBarShakeTimer > 0:
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
	if controllerAttached: streamMovement.rpc(global_position, moveIntent, lookDirection)

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

# networked callbacks for use by controller and items
@rpc("any_peer", "call_local", "reliable")
func primaryFire(_target:Vector2) -> void:
	pass

@rpc("any_peer", "call_local", "reliable")
func secondaryFire(_target:Vector2) -> void:
	pass

@rpc("any_peer", "call_local", "reliable")
func activeAbility(_target:Vector2) -> void:
	pass

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
func changeHealth(current:float, by:float, inflictor:Entity=null) -> void:
	# current health needs to be passed in to sync health between clients!
	health = current;
	health += by;
	healthBarTimer = 2;
	if sign(by) == -1:
		damage_taken.emit(-by, inflictor)
		if inflictor != null:
			inflictor.damage_dealt.emit(-by, self)
		healthBarShakeTimer = 0.3
	elif sign(by) == 1:
		healed.emit(by, inflictor)
	else:
		# when the host is syncing entity health for joining players,
		# it'll pass in their current health with a delta of 0.
		# this ensures every entity has the correct amount of health on all clients,
		# from the very beginning of the game, or dropping in midway through.
		# no healthbar timer needs to be shown for this
		healthBarTimer = 0
	if health <= 0:
		health = 0
		die(inflictor) # needs to be called on the clientside, since we're already in an RPC

@rpc("any_peer", "call_local", "reliable")
func die(killedBy:Entity=null) -> void:
	killed.emit(killedBy)
	queue_free() # ideally, play some effects on death

@rpc("any_peer", "call_remote", "unreliable_ordered")
func streamMovement(pos:Vector2, intent:Vector2, lookDir:Vector2):
	global_position = pos;
	moveIntent = intent.normalized();
	lookDirection = lookDir.normalized();

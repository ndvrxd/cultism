class_name Entity extends CharacterBody2D

# Base class for all Entities - networked actors with stats, health bars,
# and the like. Movement code & health stuff is handled here

#signals & hooks for passive items and upgrades and anything else that needs it
signal damage_taken(amount:float, from:Entity)
signal damage_dealt(amount:float, to:Entity)
signal healed(amount:float, by:Entity)
signal hit_landed(at:Vector2, normal:Vector2)
signal killed(by:Entity)
signal effect_added(effect:StatusEffect)
signal item_acquired(item:PassiveItem)

## The in-game name for this Entity.
@export var entityName:String = "Entity";

## The "faction" this entity belongs to. Used to prevent friendly fire & infighting. [br]
## [b]Do not change this property directly with code. Use [method changeTeam] instead.[/b]
@export var team:int = 0;

## The resource path to the [PackedScene] this entity resides in.
## Used when new clients request & replicate all Entities in the scene.
## [br][b]Must be set for this Entity to function in multiplayer![/b]
@export var objPath:String = ""

## The resource path to the [EntityController] this entity should be driven by,
## if spawned as a non-player character.
@export var controllerPath:String = "res://objects/controllers/basic_enemy_ai.tscn"

## Quantifies how much attention this Entity should demand, or how much of a threat it poses.
## Used in enemy aggro logic and aim assist. Directly affects [method Entity.prioritize].
@export var aggroPriority:int = 0

## The color of this Entity's health bar.[br][b]Note[/b]: Setting this property with code
## does not automatically update the health bar's color.
@export var healthBarColor:Color = Color.LIME_GREEN;

## Disables the entity's movement completely. Not automatically replicated across clients.
@export var frozen:bool = false

## Indexed list of every [Ability] attached to this Entity.
@export var abilities:Array[Ability] = []
## Acts as a "registry" of state variables to be shared between every [Ability] on this Entity.
## [br]Example: One [Ability] charges a meter on hit, the other [Ability] expends the meter to fire.
## The state of the meter will be stored here, under an arbitrary name.
var ability_vars:Dictionary = {}

var _controllerAttached:bool = false;
var _statusEffects:Array[StatusEffect] = [];
var _items:Array[PassiveItem] = [];

var _healthBar:TextureProgressBar
var _healthBarTimer:float = 0;
var _healthBarShakeTimer:float = 0;
 
const _damageNumberScn:PackedScene = preload("res://objects/damageNumber.tscn")
const _healthBarScn:PackedScene = preload("res://objects/healthBar.tscn")

## The direction this entity intends to move.
## The direction it actually moves is handled by movement code.
var moveIntent:Vector2 = Vector2.ZERO;

## The direction this entity is looking, as a [Vector2], [b]not an angle.[/b]
var lookDirection:Vector2 = Vector2.UP;

## Where this entity's "cursor" is on the screen. Used for "place anywhere" [Ability]
## moves on players and enemies alike. Does not necessarily dictate [member lookDirection].
var aimPosition:Vector2 = Vector2.ZERO;

## How long it should take, in seconds, before this Entity begins to regenerate [member health].
@export var regenDelay:float = 2
var _regenTimer:float = 0

## Reference to a child [Stat] node that dictates how much maximum [member health] this Entity should have.
## [br]Defaults to 100.
@export var stat_maxHp:Stat = Stat.fromBase(100, "stat_maxHp", self)

## Reference to a child [Stat] node that dictates how many pixels this Entity should move per second.
## [br]Defaults to 400.
@export var stat_speed:Stat = Stat.fromBase(400, "stat_speed", self)

## Reference to a child [Stat] node that dictates what proportion of its top speed this Entity gains or loses per second.
## [br]Defaults to 8.5 (850%).
@export var stat_accel:Stat = Stat.fromBase(8.5, "stat_accel", self)

## Reference to a child [Stat] node that dictates how much health this Entity should regain per second.
## [br]Defaults to 0. Best used only on player characters.
@export var stat_regen:Stat = Stat.fromBase(0, "stat_regen", self)

## Reference to a child [Stat] node that dictates how far away this Entity should notice enemies.
## [br]Used primarily in enemy aggro logic. Defaults to 250.
@export var stat_aggroRange:Stat = Stat.fromBase(250, "stat_aggroRange", self)

## Reference to a child [Stat] node that dictates how much further away this Entity is noticed by
## enemies than their default range.
## [br]Can be set to a negative number for "stealthy" characters. Defaults to 0.
@export var stat_aggroNoise:Stat = Stat.fromBase(0, "stat_aggroNoise", self)

## @experimental
## Reference to a child [Stat] node that dictates how much damage this Entity should do,
## before [Ability] damage calculations. [br]Defaults to 100.
@export var stat_baseDamage:Stat = Stat.fromBase(30, "stat_baseDamage", self)

## The current health that this entity has. Synced via [method changeHealth],
## when invoked using [method Callable.rpc].
var health:float = 1

## Reference to a [Node2D] that acts as the "eye level" of an entity.
## This will always be a child [Node2D] named [code]shoulder[/code]. If it does not exist,
## it will be created.
## [br] This node's position is used to determine the height of name tags and health bars,
## and its rotation corresponds to the [member lookDirection] of the Entity.
var shoulderPoint:Node2D;
## Reference to a [Node2D] that acts as the "foot point" of an entity.
## This will always be a child [Node2D] named [code]feet[/code]. If it does not exist,
## it will be created. This node is visually flipped based on [member lookDirection].
var footPoint:Node2D;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("entity"); # for polling all active entities
	
	shoulderPoint = get_node("shoulder")
	if shoulderPoint == null:
		var temp = Node2D.new();
		temp.name = "shoulder";
		add_child(temp);
		shoulderPoint = temp;
	
	footPoint = $feet if has_node("feet") else Node2D.new();
	
	# create a "projectiles" node for all of this entity's projectiles to be kept under
	if !has_node("projectiles"):
		var temp = Node.new();
		temp.name = "projectiles"
		add_child(temp)
		
	# health bars only need to be shown in visible game windows
	# otherwise, we don't need to instantiate or drive them
	if !NetManager.IsDedicated():
		var hbscn = _healthBarScn.instantiate()
		add_child(hbscn)
		_healthBar = hbscn.get_node("healthbar")
		_healthBar.position.y = (shoulderPoint.global_position.y - global_position.y) * 2
		_healthBar.tint_progress = healthBarColor
		_healthBar.visible = false;
	
	# ensure any stat changes by child class are reflected,
	# regardless of super._ready() being called before or after:
	_afterStatsSet.call_deferred()

func _afterStatsSet():
	health = stat_maxHp.val

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if shoulderPoint: #aiming
		shoulderPoint.look_at(shoulderPoint.global_position + lookDirection)
	if footPoint: # visual look direction
		footPoint.scale.x = 1 if lookDirection.x > 0 else -1
		
	if _regenTimer > 0:
		_regenTimer -= delta
	else:
		health = min(health + stat_regen.val * delta, stat_maxHp.val)
	
	#really, this should be an Animation of some kind
	if _healthBarTimer > 0 && !NetManager.IsDedicated():
		if !_healthBar.visible: _healthBar.visible = true
		_healthBarTimer -= delta
		_healthBar.value = (health / stat_maxHp.val) * 100
		if _healthBarShakeTimer > 0:
			var tc = _healthBar.tint_under
			if _healthBarShakeTimer > 0.25 or (_healthBarShakeTimer <= 0.25 and tc.r > 0.5):
				_healthBar.set_tint_under(Color(1-tc.r, 1-tc.g, 1-tc.b, tc.a))
			_healthBarShakeTimer -= delta
			_healthBar.rotation = sin(Time.get_unix_time_from_system()*70) * _healthBarShakeTimer * 0.3
		else:
			_healthBar.rotation = 0;
	elif _healthBarTimer < 0:
		_healthBar.visible = false
		_healthBarTimer = 0

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
	# FIXME: PLEASE replace this with multiplayer authority
	if _controllerAttached: streamMovement.rpc(global_position, moveIntent,
									lookDirection, aimPosition)

# what i'm thinking is that the authority for each entity
# can attach a controller to it clientside, and the controller can make
# Entity RPC calls from within itself so shit gets synced for everyone
# from within a script that ISNT synced for everyone

## Static "spawn" method for all entities.
## Use this instead of [method NetManager.spawnEntityRpc].
## Exists to ensure network sync by determining the entity's name & nodepath clientside first.[br]
## [br] If [param ctlPath] is specified, the entity will be spawned with the appropriate
## [EntityController] instead of their default.
## [br] If [param playerName] is specified, the Entity will be spawned as a player,
## with the invoking client's(?) perspective controlling it.
static func spawn(scnPath:String, pos:Vector2=Vector2.ZERO, ctlPath:String="", playerName:String=""):
	var isPlayer:bool = false;
	if playerName == "":
		playerName = str(randi_range(0, 999999999999)) #fuck it
	else:
		ctlPath = NetManager.PLAYERCONTROLSOBJ
		isPlayer = true;
	NetManager.spawnEntityRpc.rpc(scnPath, pos, ctlPath, playerName, isPlayer) 

## RPC-decorated method to change the entity's faction. Use this instead of
## setting [member team] with code. Sets the Entity's collision layers to the
## appropriate ones for their team, and may be used to reliably replicate
## the change across clients (though, so far, it typically isn't.)
## @experimental: The RPC decorator may be removed later down the line, once status conditions are implemented.
@rpc("any_peer", "call_local", "reliable")
func changeTeam(newTeam:int) -> void:
	var foo:Array[Node] = find_children("*", "Area2D", false)
	var hitbox:Area2D = null if foo.is_empty() else (foo[0] as Area2D)
	# flip the appropriate bit off for our current team
	collision_layer = collision_layer ^ 32 << team
	# set the appropriate bits for new team
	# (32, for all characters, as well as 32 << newTeam for factions)
	# (layer 6, bit 32, should pretty much always be set)
	var newBits:int = (32 | (32 << newTeam))
	collision_layer |= newBits
	if hitbox: hitbox.collision_layer = newBits # completely replace collision layer for hurtbox
	# make sure if they were meant to collide with teammates before, they still do that(?)
	if collision_mask & (32 << team):
		collision_mask = collision_mask ^ (32 << team)
		collision_mask |= 32 << newTeam
	team = newTeam

## RPC-decorated method to invoke an [Ability]. Primarily used within [EntityController]s.
## Invoke using [method Callable.rpc]. [br]
## Requires an index for the [member abilities] array, and a boolean "pressed"
## state for the [Ability], for whether or not it's being held down.
## [param target] may be used to sync [member aimPosition] before firing.
@rpc("authority", "call_local", "reliable")
func setAbilityPressed(id:int, pressed:bool, target:Vector2=Vector2.ZERO):
	if target != Vector2.ZERO:
		aimPosition = target
	if id < abilities.size() and abilities[id] != null and is_instance_valid(abilities[id]):
		abilities[id]._press() if pressed else abilities[id]._release()

## @experimental: Does nothing. I fully intend to use this later, our current chatbox is placeholder.
@rpc("authority", "call_local", "reliable")
func chat(_msg:String) -> void:
	pass

## RPC-decorated method used to damage or heal an entity. May be invoked by anyone
## using [method Callable.rpc].
## Needs the client's current subjective health of the Entity to ensure network sync.
## Damage may be traced back to an inflicting Entity by its [NodePath].
@rpc("any_peer", "call_local", "reliable")
func changeHealth(current:float, delta:float, inflictor:NodePath="") -> void:
	health = current;
	health += delta;
	_healthBarTimer = 2;
	var opp = get_node(inflictor)
	var dn:Node2D = _damageNumberScn.instantiate()
	dn.set_number(int(abs(delta)))
	dn.global_position = shoulderPoint.global_position
	get_tree().current_scene.add_child(dn)
	if sign(delta) == -1:
		_regenTimer = 2
		damage_taken.emit(-delta, opp)
		if team == 1: dn.set_color(Color.RED) #red is bad for players & allies
		if opp != null:
			opp.damage_dealt.emit(-delta, self)
		_healthBarShakeTimer = 0.3
	elif sign(delta) == 1:
		healed.emit(delta, opp)
		dn.set_color(Color.GREEN)
	else:
		# when the host is syncing entity health for joining players,
		# it'll pass in their current health with a delta of 0.
		# this ensures every entity has the correct amount of health on all clients,
		# from the very beginning of the game, or dropping in midway through.
		# no _healthBar needs to be shown for this
		_healthBarTimer = 0
		#dn.queue_free()
	if health <= 0:
		health = 0
		kill(inflictor) # needs to be called on the clientside, since we're already in an RPC

## @experimental: This method's behavior sorely needs an update.
## RPC-decorated method to "kill" an entity.
## At the moment, immediately removes the Entity from the scene,
## preventing "on-death" effects from playing through as necessary.
## [b]This will change in the future.[/b]
@rpc("authority", "call_local", "reliable")
func kill(killedBy:NodePath="") -> void:
	killed.emit(get_node(killedBy))
	queue_free() # ideally, play some effects on death

## RPC-decorated method to stream an Entity's movement to other clients.
## Set to [code]unreliable_ordered[/code] for efficiency.
@rpc("authority", "call_remote", "unreliable_ordered")
func streamMovement(pos:Vector2, intent:Vector2, lookDir:Vector2, aimPos:Vector2):
	global_position = pos;
	moveIntent = intent.normalized();
	lookDirection = lookDir.normalized();
	aimPosition = aimPos;

## Syncs the state of this Entity to other clients when a new client connects.
func _sync_effects_tx(cid:int, _playerinfo):
	for effect:StatusEffect in _statusEffects:
		_addEffectStackRpc.rpc_id(cid, effect._ownPath, effect.getStacks(), effect.name, effect._age)

## CHECK FOR AUTHORITY BEFORE USING - RELAYS TO EVERYONE ELSE
func addEffectStack(effectScene:PackedScene, count:int):
	var path:String = effectScene.resource_path
	var fxname:String = str(randi_range(0, 999999999999))
	_addEffectStackRpc.rpc(path, count, fxname, -1)

@rpc("any_peer", "reliable", "call_local")
func _addEffectStackRpc(resource_path:String, count:int, fxname:String, age:float):
	var effect:StatusEffect = getEffect(resource_path)
	if !effect:
		effect = load(resource_path).instantiate()
		effect._ownPath = resource_path
		effect.ent = self
		effect.stackCount = 0
		effect.addStacks(count)
		if age >= 0:
			effect._age = age
		effect.name = fxname
		_statusEffects.append(effect)
		add_child(effect)
		effect_added.emit(effect)
	else:
		effect.name = fxname
		effect.addStacks(count)

func getEffect(path:String) -> StatusEffect:
	for e:StatusEffect in _statusEffects:
		if path == e._ownPath: return e;
	return null;

func addItem(itemScene:PackedScene, count:int=1):
	var path:String = itemScene.resource_path
	var nodename:String = str(randi_range(0, 999999999999))
	if is_multiplayer_authority():
		_addItemStackRpc.rpc(path, count, nodename)

@rpc("authority", "reliable", "call_local")
func _addItemStackRpc(resource_path:String, count:int, nodename:String):
	var item:PassiveItem = getItem(resource_path)
	if !item:
		item = load(resource_path).instantiate()
		item._ownPath = resource_path
		item.ent = self
		item.stackCount = 0
		item.addStacks(count)
		item.name = nodename
		_items.append(item)
		add_child(item)
		item_acquired.emit(item)
	else:
		item.name = nodename
		item.addStacks(count)

func getItem(path:String) -> PassiveItem:
	for i:PassiveItem in _items:
		if path == i._ownPath: return i;
	return null;

## @experimental
@rpc("authority", "call_local", "reliable")
func triggerHitEffectsRpc(at:Vector2, normal:Vector2=Vector2.ZERO) -> void:
	hit_landed.emit(at, normal)

## Prioritizes a set of other Entities based on their [member team], proximity &
## [member aggroPriority]. [br]
## [param ents] may be passed in as a collection of either [Entity], [CharacterBody2D], or
## [Area2D], for ease of use with the 2 different types of collision box an Entity has.
## If an item is invalid, it will be ignored. [br]
## Returns a single Entity as a "recommendation" on who to attack.
## Used for aim assist and enemy aggro logic.
## @experimental: This should return [code]Array[Entity][/code] in the future.
func prioritize(ents:Array) -> Entity:
	var result:Entity = null;
	var closest:float = INF
	var highestPrio:int = -INF
	
	for hitbox:CollisionObject2D in ents:
		
		var candidate:Entity;
		if hitbox is Entity:
			candidate = hitbox as Entity
		elif hitbox is Area2D:
			candidate = hitbox.get_parent() as Entity
		if not candidate or team == candidate.team or candidate.team == 0: continue
		
		var dist = global_position.distance_to(candidate.global_position)
		var dir = shoulderPoint.global_position.direction_to(hitbox.global_position)
		if candidate.aggroPriority > highestPrio:
			highestPrio = candidate.aggroPriority
			closest = dist
			result = candidate
		elif dist < closest and candidate.aggroPriority == highestPrio:
			closest = dist
			result = candidate
			
	return result;

## Creates a [Projectile] owned and simulated by this Entity. [br]
## Is automatically replicated across clients. Ignored if called as
## non-authority. [br] [br]
## [param Ability] may be the [Ability] that fired this projectile, or null. [br]
## [param from] is the point this projectile fires from. Defaults to the [member shoulderPoint]. [br]
## [param facing] is direction this projectile faces when spawned. Defaults to [member lookDirection]. [br]
## [param vel] is the initial velocity of the projectile.
## Defaults to [member Projectile.default_speed] * [member lookDirection]. [br]
## [param accel] is the initial acceleration of the projectile.
## Defaults to [member Projectile.default_accel] * [member lookDirection].
func create_projectile(scn:PackedScene, ability:Ability=null, from:Vector2=Vector2.ZERO, facing:Vector2=Vector2.ZERO, vel:Vector2=Vector2.ZERO, accel:Vector2=Vector2.ZERO):
	if !is_multiplayer_authority(): return
	var pname:String = str(randi_range(0, 999999999999))
	from = from if from != Vector2.ZERO else shoulderPoint.global_position
	facing = facing if facing != Vector2.ZERO else lookDirection
	_create_projectile_rpc.rpc(scn.resource_path, get_path(), ability.get_path() if ability else "",
			 pname, from, facing, vel, accel)

@rpc("authority", "reliable", "call_local")
func _create_projectile_rpc(scnPath:String, entPath:NodePath, abilPath:NodePath, nodeName:String, from:Vector2, facing:Vector2, vel:Vector2, accel:Vector2):
	var temp:Node = load(scnPath).instantiate()
	if not temp is Projectile:
		temp.queue_free()
		return
	var proj:Projectile = temp as Projectile
	proj.set_multiplayer_authority(multiplayer.get_remote_sender_id())
	proj.name = nodeName
	proj.look_at(facing)
	proj.global_position = from
	proj.velocity = vel if vel != Vector2.ZERO else facing * proj.default_speed
	proj.accel = accel if accel != Vector2.ZERO else facing * proj.default_accel
	proj.ent = get_node(entPath)
	if abilPath != ("" as NodePath):
		proj.ability = get_node(abilPath)
	$projectiles.add_child(proj)


## hitscan. turns out shape/linecast in godot is tedious as fuck,
## so i'm making a nice clean method for it instead.
## returns the Entity hit, if any, the position hit, if any,
## and the normal of the surface hit, if any.
func lineCastFromShoulder(direction:Vector2, range:float, triggerHitEffects=true, friendlyFire = false) -> Dictionary:
	
	var endpoint:Vector2 = shoulderPoint.global_position + direction.normalized() * range
	
	var physics_query = PhysicsRayQueryParameters2D.create(
			shoulderPoint.global_position,
			endpoint
			# TODO: set collision flags here
		)
	physics_query.set_collide_with_areas(true);
	if friendlyFire:
		# use the "world" and "all characters" collision layers
		physics_query.collision_mask = 33
	else:
		# use "world" + all allowed "character" collision layers except team
		physics_query.collision_mask = 0xFFFFFFC1 ^ (32 << team)
	
	var hit = get_world_2d().direct_space_state.intersect_ray(
		physics_query
	)
	if hit.is_empty():
		return {
			"entity": null,
			"pos": Vector2.ZERO,
			"normal": Vector2.ZERO
		} #all this may not be necessary
	if triggerHitEffects and is_multiplayer_authority():
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

## Checks clientside for any [Interactable]s in range, and emits
## [signal Interactable.interacted_with] for all clients on the first one found.
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
	params.collision_mask = 8 # only collide with Interactable layer
	
	var hits = get_world_2d().direct_space_state.intersect_shape(params)
	for i in hits:
		var collider = i["collider"]
		if collider is Interactable:
			var intr = collider as Interactable
			intr._trigger_interact_rpc.rpc(get_path())
			return intr
	return null;

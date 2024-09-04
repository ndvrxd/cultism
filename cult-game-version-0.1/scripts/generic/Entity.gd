class_name Entity extends CharacterBody2D

# Base class for all Entities - networked actors with stats, health bars,
# and the like. Movement code & health stuff is handled here

@export var entityName:String = "Entity";
@export var team:int = 0;
@export var objPath:String = ""
@export var controllerPath:String = ""
@export var controllerAttached:bool = false;

@export var moveIntent:Vector2 = Vector2.ZERO;
@export var lookDirection:Vector2 = Vector2.UP;
# TODO: allow lookDirection into lookAngle conversion

@export var stat_maxHp:Stat = Stat.fromBase(100);
@export var stat_speed:Stat = Stat.fromBase(400);
@export var stat_accel:Stat = Stat.fromBase(8.5);
# "aggro" stats get used by entity controllers for target selection
@export var stat_aggroRange:Stat = Stat.fromBase(1000);
@export var stat_aggroNoise:Stat = Stat.fromBase(0);

@export var health:float = stat_maxHp.val;

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.x = move_toward(velocity.x / stat_speed.val, moveIntent.x, stat_accel.val * delta) * stat_speed.val
	velocity.y = move_toward(velocity.y / stat_speed.val, moveIntent.y, stat_accel.val * delta) * stat_speed.val
	move_and_slide()
	
	if shoulderPoint:
		shoulderPoint.look_at(shoulderPoint.global_position + lookDirection)

func _physics_process(_delta: float) -> void:
	moveIntent = moveIntent.normalized();
	lookDirection = lookDirection.normalized();
	if controllerAttached: streamMovement.rpc(global_position, moveIntent, lookDirection)

# what i'm thinking is that the authority for each entity
# can attach a controller to it clientside, and the controller can make
# Entity RPC calls from within itself so shit gets synced for everyone
# from within a script that ISNT synced for everyone

# exists to determine the entity's name clientside
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
	pass

@rpc("any_peer", "call_local", "reliable")
func spawn_something() -> void:
	pass # idk how to make this work

@rpc("any_peer", "call_local", "reliable")
func changeHealth(by:float) -> void:
	health += by; #maybe take a moment to show a health bar above

@rpc("any_peer", "call_local", "reliable")
func die() -> void:
	pass # ideally, remove self from the scene

@rpc("any_peer", "call_remote", "unreliable_ordered") # netcode stuff testing ???
func streamMovement(pos:Vector2, intent:Vector2, lookDir:Vector2):
	global_position = pos;
	moveIntent = intent.normalized();
	lookDirection = lookDir.normalized();

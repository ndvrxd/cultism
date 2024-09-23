extends EntityController

var timer_navdest:Timer = Timer.new()
var timer_aggro:Timer = Timer.new()

func _ready():
	super._ready()
	timer_navdest.timeout.connect(update_target_loc)
	timer_navdest.wait_time = 0.2
	add_child(timer_navdest)
	timer_navdest.start()
	
	timer_aggro.timeout.connect(update_aggro)
	add_child(timer_aggro)
	update_aggro()

@export var attackRange:float = 70;
var attacking:bool = false
var navdest:Vector2 = Vector2.ZERO;

func update_aggro()->void:
	var e_old:Entity = target;
	var e:Entity = findNewTarget();
	if e_old != null and e == null: #if de-aggroing from an enemy
		attacking = false
		ent.setAbilityPressed(0, false)
		seekNearestPathNode()
	# try to counteract the O(n^2) nature of this algorithm
	# by increasing the interval between retargets based on how many
	# entities are currently active. this may also help gameplay somewhat
	var ecount = get_tree().get_node_count_in_group("entity")
	timer_aggro.start(1 + 0.03 * ecount)

func update_target_loc()->void:
	navdest = nav.get_next_path_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if target != null: # pursuing anyone?
		nav.target_position = target.global_position;
		ent.moveIntent = ent.global_position.direction_to(navdest)
		ent.aimPosition = target.shoulderPoint.global_position
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(ent.aimPosition)
		
		if not attacking and global_position.distance_to(target.global_position) <= attackRange:
			attacking = true
			ent.setAbilityPressed(0, true)
		elif attacking and global_position.distance_to(target.global_position) > attackRange:
			attacking = false
			ent.setAbilityPressed(0, false)
		
	else: # if not aggroed, move toward the next node in the path
		updateIdlePathing()
		nav.target_position = nextPathNode.global_position;
		ent.moveIntent = ent.global_position.direction_to(navdest)
		ent.lookDirection = ent.moveIntent

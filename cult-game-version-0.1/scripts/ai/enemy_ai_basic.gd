extends EntityController

const aggroCheckMaxTime:float = 1;
var aggroCheckTimer:float = aggroCheckMaxTime-0.1;

@export var attackRange = 70;
var attacking:bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if target != null: # pursuing anyone?
		nav.target_position = target.global_position;
		var dir = ent.global_position.direction_to(nav.get_next_path_position())
		ent.moveIntent = dir if !attacking else Vector2.ZERO
		var shoulderOffset = Vector2.DOWN * (target.shoulderPoint.global_position - target.global_position)
		var targetPos = target.shoulderPoint.global_position - shoulderOffset * 0.3
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(targetPos)
		ent.aimPosition = targetPos
		
		if not attacking and global_position.distance_to(target.global_position) <= attackRange:
			attacking = true
			ent.primaryFire.rpc(ent.aimPosition)
		if attacking and global_position.distance_to(target.global_position) > attackRange:
			attacking = false
			ent.primaryFireReleased.rpc(ent.aimPosition)
		
	else: # if not aggroed, move toward the next node in the path
		updateIdlePathing()
		nav.target_position = nextPathNode.global_position;
		ent.moveIntent = ent.global_position.direction_to(nav.get_next_path_position())
		ent.lookDirection = ent.moveIntent
		
	aggroCheckTimer += delta;
	if aggroCheckTimer > aggroCheckMaxTime:
		var e_old:Entity = target;
		var e:Entity = findNewTarget();
		if e_old != null and e == null: #if de-aggroing from an enemy
			attacking = false
			seekNearestPathNode()
		aggroCheckTimer = 0;

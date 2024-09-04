extends EntityController

const aggroCheckMaxTime:float = 2;
var aggroCheckTimer:float = aggroCheckMaxTime-0.1;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if target != null: # pursuing anyone?
		nav.target_position = target.global_position;
		var dir = ent.global_position.direction_to(nav.get_next_path_position())
		ent.moveIntent = dir
		var targetPos = target.global_position + Vector2(0, -40) # stupid hardcode but w/e
		ent.lookDirection = ent.shoulderPoint.global_position.direction_to(targetPos)
		
	else: # dick around
		ent.moveIntent = Vector2.ZERO
		
		var time = Time.get_unix_time_from_system();
		ent.lookDirection.x = sin(time);
		ent.lookDirection.y = cos(time);
		
	aggroCheckTimer += delta;
	if aggroCheckTimer > aggroCheckMaxTime:
		findNewTarget();
		aggroCheckTimer = 0;

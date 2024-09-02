extends EntityController

const aggroCheckMaxTime:float = 1;
var aggroCheckTimer:float = 0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if target != null:
		nav.target_position = target.global_position;
		var dir = ent.global_position.direction_to(nav.get_next_path_position());
		ent.setMoveIntent(dir);
	else:
		ent.setMoveIntent(Vector2.ZERO)
	aggroCheckTimer += delta;
	if aggroCheckTimer > aggroCheckMaxTime:
		findNewTarget();
		aggroCheckTimer = 0;

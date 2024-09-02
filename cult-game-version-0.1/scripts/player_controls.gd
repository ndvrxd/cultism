extends EntityController

var direction:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down");

func _physics_process(delta: float) -> void:
	# every physics tick, or however often we want to stream movement changes
	ent.setMoveIntent(direction)

extends Entity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	stat_speed = Stat.fromBase(500);
	stat_maxHp = Stat.fromBase(75);

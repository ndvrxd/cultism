extends Entity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	stat_speed = Stat.fromBase(1);
	stat_maxHp = Stat.fromBase(5000);
	stat_regen = Stat.fromBase(1)
	stat_aggroNoise = Stat.fromBase(8000)

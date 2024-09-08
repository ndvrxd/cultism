extends Entity

#any special functionality for the enemy can be overridden here
func _ready():
	super._ready();
	stat_speed = Stat.fromBase(200);

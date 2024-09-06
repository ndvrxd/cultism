extends Entity

var takeDamageIn = 1

#any special functionality for the enemy can be overridden here
func _ready():
	super._ready();
	stat_speed = Stat.fromBase(200);

func _physics_process(delta:float):
	super._physics_process(delta)
	if !multiplayer.is_server(): return
	takeDamageIn -= delta
	if takeDamageIn < 0:
		changeHealth.rpc(health, -3)
		takeDamageIn = 1

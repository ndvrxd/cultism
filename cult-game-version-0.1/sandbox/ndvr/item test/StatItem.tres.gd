extends PassiveItem


@export var SpeedModify:float = 0
@export var LuckModify:float = 0
@export var Cooldown:float = 0
@export var HealthModify:float = 0
@export var DamageModify:float = 0
@export var RegenModify:float = 0
@export var AggroModify:float = 0


func _on_stack_count_changed(delta: int) -> void:
	#commenting all this cus i still wanna mess around with it l8r! -ndvr :3
	#var temp:String = ""
	#for i in range(stackCount):
	#	temp += "+10 Speed\n"
	#$Label.text = temp
	ent.stat_speed.modifyMultFlat(SpeedModify * delta)
	ent.stat_luck.modifyMultFlat(LuckModify * delta)
	ent.stat_cooldown.modifyMultFlat(Cooldown * delta)
	ent.stat_maxHp.modifyMultFlat(HealthModify * delta)
	ent.stat_baseDamage.modifyMultFlat(DamageModify * delta)
	ent.stat_regen.modifyMultFlat(RegenModify * delta)
	ent.stat_aggroNoise.modifyMultFlat(AggroModify * delta)
	
	

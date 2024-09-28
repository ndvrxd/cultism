extends Ability

## The [PackedScene] for the hitscan tracer this ability should use.
## Not automatically cleaned up; the tracer should [method Node.queue_free] itself.
@export var hitscanTracer:PackedScene
## The [PackedScene] for the VFX this ability should use on impact.
## Not automatically cleaned up; the impact VFX should [method Node.queue_free] itself.
@export var impactVfx:PackedScene
## Maximum range of hitscan.
@export var gunRange:float = 2000
## @experimental: Damage calculations will very likely change drastically in the future.
## How much to multiply [member Entity.stat_baseDamage] by in damage calculations.
@export var gunDamageCoeff:float = 2
## An [Area2D], meant to be a cone protruding from the shoulder. Should face right
## by default, and be placed on the world origin. Can be left unset for no
## aim assist.
@export var aimAssistZone:Area2D

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if aimAssistZone:
		alignNodeWithShoulder(aimAssistZone)

func fireAction():
	var aimAssist:Vector2 = ent.lookDirection
	if aimAssistZone:
		var sucker:Entity = ent.prioritize(aimAssistZone.get_overlapping_areas())
		if sucker: aimAssist = ent.shoulderPoint.global_position.direction_to(
				sucker.shoulderPoint.global_position
				)
	
	var hit = ent.lineCastFromShoulder(aimAssist, gunRange)
	var tr = hitscanTracer.instantiate()
	tr.global_position = ent.shoulderPoint.global_position
	tr.setDirection(aimAssist)
	tr.setRange(ent.shoulderPoint.global_position.distance_to(hit["pos"]), 70)
	get_tree().current_scene.add_child(tr)
	if is_multiplayer_authority():
		if hit["pos"] != Vector2.ZERO:
			_doHitVfx.rpc(hit["pos"])
		var target:Entity = hit["entity"] as Entity
		if target and target.team != ent.team:
			target.changeHealth.rpc(target.health, 
				-ent.stat_baseDamage.val*gunDamageCoeff, ent.get_path())

@rpc("authority", "call_local", "reliable")
func _doHitVfx(pos:Vector2) -> void:
	var temp = impactVfx.instantiate()
	temp.global_position = pos
	temp.modulate = Color.GOLD
	get_tree().current_scene.add_child(temp)

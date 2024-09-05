class_name EntityController extends Node2D

var nav:NavigationAgent2D = null;
var ent:Entity;
var target:Entity = null;

func _ready():
	attemptControl()

func attemptControl() -> void:
	var parent = get_parent();
	if not parent is Entity: return
	ent = parent
	if nav == null or not ent.is_ancestor_of(nav):
		nav = NavigationAgent2D.new();
		ent.add_child.call_deferred(nav)
	#nav.debug_enabled = true;
	ent.controllerAttached = true;

func findNewTarget(friendlyfire=false) -> void:
	## stock aggro mechanics for all enemies
	## don't call every frame
	# maybe don't do this every time, maybe just cache valid targets
	target = null;
	var closest = INF;
	var ents = get_tree().get_nodes_in_group("entity")
	for i in ents:
		if not i is Entity: continue
		var e = i as Entity
		nav.target_position = e.global_position;
		if (e.team != ent.team or friendlyfire) and not e.team == 0:
			var dist:float = ent.global_position.distance_to(e.global_position)
			if dist < closest: #nav.is_target_reachable() and dist < closest:
				if dist < (ent.stat_aggroRange.val + e.stat_aggroNoise.val):
					target = e;
					closest = dist;

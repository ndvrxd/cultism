class_name EntityController extends Node2D

var nav:NavigationAgent2D = null;
var ent:Entity;
var target:Entity = null;
var nextPathNode:PathNode = null;

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

func findNewTarget(friendlyfire=false) -> Entity:
	## stock aggro mechanics for all enemies
	## don't call every frame
	# maybe don't do this every time, maybe just cache valid targets
	target = null;
	var closest = INF;
	var highestPriority = -INF;
	var ents = get_tree().get_nodes_in_group("entity")
	for i in ents:
		if not i is Entity: continue
		var e = i as Entity
		nav.target_position = e.global_position;
		if (e.team != ent.team or friendlyfire) and not e.team == 0:
			var dist:float = ent.global_position.distance_to(e.global_position)
			if dist < closest or e.aggroPriority > highestPriority: #nav.is_target_reachable() and dist < closest:
				if dist < (ent.stat_aggroRange.val + e.stat_aggroNoise.val) and e.aggroPriority >= highestPriority:
					target = e;
					closest = dist;
					highestPriority = e.aggroPriority
	return target;

func updateIdlePathing():
	if nextPathNode != null:
		var dist:float = nextPathNode.global_position.distance_to(ent.global_position)
		if dist < 100: getNextPathNode()
	else:
		getNextPathNode()

func getNextPathNode():
	if nextPathNode == null:
		# get the nearest "path start" node
		var points = get_tree().get_nodes_in_group("path_start_node")
		if points.is_empty(): return; #jump ship if there's nothing
		var closest:PathNode = points[0];
		var closestDist:float = INF;
		for p:PathNode in points:
			var dist:float = p.global_position.distance_to(ent.global_position)
			if dist < closestDist:
				closest = p
				closestDist = dist
		nextPathNode = closest
	else: # select the next node in the path
		var temp:PathNode = nextPathNode.next_nodes_pool.pick_random()
		nextPathNode = temp

func seekNearestPathNode():
	var points = get_tree().get_nodes_in_group("path_node")
	var closest:PathNode;
	var closestDist:float = INF;
	for p:PathNode in points:
		var dist:float = p.global_position.distance_to(ent.global_position)
		if dist < closestDist:
			closest = p
			closestDist = dist
	nextPathNode = closest

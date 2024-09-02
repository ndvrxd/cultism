class_name EntityController extends Node2D

var nav:NavigationAgent2D;
@onready var ent:Entity = get_parent();
var target:Entity = null;

func ready():
	nav = NavigationAgent2D.new();
	ent.add_child(nav)

func findNewTarget(friendlyfire=false):
	## stock aggro mechanics for all enemies
	## don't call every frame
	# maybe don't do this every time, maybe just cache valid targets
	target = null;
	var closest = INF;
	for i:Entity in get_tree().get_nodes_in_group("entity"):
		nav.target_position = i.global_position;
		if i.team != ent.team or friendlyfire:
			if nav.is_target_reachable() and nav.distance_to_target() < closest:
				target = i;

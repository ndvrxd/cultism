class_name ItemDropPool extends Resource
## Abstract data type to represent a pool of [PassiveItem]s that can drop,
## as well as their weights. Note: Weights not implemented yet.

## A list of file paths to [PassiveItem] [PackedScene]s.
@export_file var items:Array[String]

## Select an item scene's resource path at random and return it as a [String]. 
func pullItemPath() -> String:
	return items.pick_random()

## Select an item at random and return it as a new [PassiveItem] instance.
func pullItem() -> PassiveItem:
	var path:String = pullItemPath()
	var item:PassiveItem = load(path).instantiate()
	item._ownPath = path
	return item

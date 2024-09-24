class_name Stat extends Node
## Meant to be used to cleanly track and modify entity stats.

signal valueChanged(value:float);

## The base value of the statistic. Modify with set only.
## May be set in the inspector.
@export var baseValue:float = 0.0;

## A flat value added to the base statistic. Modify with add/subtract only.
## Not recommended to change in the inspector.
var baseModifier:float = 0.0;

## The multiplicative modifier. Modify with multiply/divide only.
## Not recommended to change in the inspector.
var multiplier:float = 1.0;

## Flat value added to the multiplier. Modify with add/subtract only.
## Not recommended to change in the inspector.
var multFlatModifier:float = 0.0;

## A flat value added to the statistic. Modify with add/subtract only
## Not recommended to change in the inspector.
var additive:float = 0.0;

@onready var val:float = baseValue;

func _ready():
	process_mode = PROCESS_MODE_DISABLED

func mp_sync():
	if is_multiplayer_authority():
		val = (baseValue + baseModifier) *	(multiplier + multFlatModifier) + additive;
		valueChanged.emit(getValue());
		await get_tree().create_timer(0.1).timeout
		mp_sync_rpc.rpc(baseValue, baseModifier, multiplier,
				multFlatModifier, additive)

@rpc("authority", "call_remote", "reliable")
func mp_sync_rpc(base:float, baseadd:float, mult:float, multadd:float, add:float):
	baseValue = base;
	baseModifier = baseadd;
	multiplier = mult;
	multFlatModifier = multadd;
	additive = add;
	val = (baseValue + baseModifier) *	(multiplier + multFlatModifier) + additive;
	valueChanged.emit(getValue());

# custom constructor because no overloads allowed :(
static func fromBase(base:float, nodeName:String="", parent:Node=null) -> Stat:
	var newStat:Stat = Stat.new()
	newStat.setBase.call_deferred(base)
	if nodeName != "":
		newStat.name = nodeName
	if parent != null:
		parent.add_child(newStat)
	return newStat

func setBase(value:float):
	## Set the base value of the statistic.
	baseValue = value
	mp_sync()
	
func modifyBase(flatValue:float):
	## Additively modify the base value of the statistic.
	baseModifier += flatValue
	mp_sync()

func modifyMult(factor:float):
	## Multiplicatively modify the base value of the statistic.
	multiplier *= factor
	mp_sync()

func modifyMultFlat(flatValue:float):
	## Add a flat multiplicative modifier to the base value of the statistic.
	multFlatModifier += flatValue
	mp_sync()
	
func modifyFlat(flatValue:float):
	## Add a flat value to the statistic, after modifiers.
	additive += flatValue
	mp_sync()

func getValue() -> float:
	## Returns the final value of the statistic.
	return val

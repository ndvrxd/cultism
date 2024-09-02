class_name Stat extends Resource
## Meant to be used to cleanly track and modify entity stats.
	
## The base value of the statistic. Modify with set only.
## May be set in the inspector.
@export var baseValue:float = 0.0;

## A flat value added to the base statistic. Modify with add/subtract only.
## Not recommended to change in the inspector.
@export var baseModifier:float = 0.0;

## The multiplicative modifier. Modify with multiply/divide only.
## Not recommended to change in the inspector.
@export var multiplier:float = 1.0;

## Flat value added to the multiplier. Modify with add/subtract only.
## Not recommended to change in the inspector.
@export var multFlatModifier:float = 0.0;

## A flat value added to the statistic. Modify with add/subtract only
## Not recommended to change in the inspector.
@export var additive:float = 0.0;

var val:float: #getValue shorthand
	get:
		return getValue()

# appease the NDC gods
func _init(): pass

# custom constructor because no overloads allowed :(
static func fromBase(base:float) -> Stat:
	var newStat:Stat = Stat.new()
	newStat.setBase(base)
	return newStat

func setBase(value:float):
	## Set the base value of the statistic.
	baseValue = value
	
func modifyBase(flatValue:float):
	## Additively modify the base value of the statistic.
	baseModifier += flatValue

func modifyMult(factor:float):
	## Multiplicatively modify the base value of the statistic.
	multiplier *= factor

func modifyMultFlat(flatValue:float):
	## Add a flat multiplicative modifier to the base value of the statistic.
	multFlatModifier += flatValue
	
func modifyFlat(flatValue:float):
	## Add a flat value to the statistic, after modifiers.
	additive += flatValue

func getValue() -> float:
	## Returns the final value of the statistic.
	return (baseValue + baseModifier) *	(multiplier + multFlatModifier) + additive;

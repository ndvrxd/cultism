class_name Stat extends Node
## An abstract data type meant to be used to cleanly track and modify entity stats.[br]
## Serves as a solution to the roguelite problem of recalculating all of the player's
## stats after picking up an item - instead of recalculating everything at once
## in a single script, each [Stat] recalulates itself.[br][br]
## [Stat] exists as a [Node] to allow sync between clients using [NodePath]s.
## All [Stat]s' [member Node.process_mode] is forced to
## [enum Node.ProcessMode][code].PROCESS_MODE_DISABLED[/code], since it is entirely restful.
## [br][br]Each [Stat] is calculated as follows:
## [br][code]val = (baseValue + _baseModifier) * (_multiplier + _multFlatModifier) + _additive;[/code]
## [br]For performance, each Stat's value is read from [member val], and only recalculated in
## [method mp_sync].

## Emits when the value of the [Stat] is meant to be changed.
## @experimental: Currently fires when the final value of the [Stat] does not actually change.
signal valueChanged(value:float);

## Internal use only. Don't touch this.
signal _entered_tree() # needs to be awaited in mp_sync if being added to the tree outside _ready
var _waitingForTree:bool = false

## The base value of the statistic. May be set in the inspector.
## [br][b]Do not modify with code. Use [method setBase] instead.[/b]
@export var baseValue:float = 0.0;
var _baseModifier:float = 0.0;
var _multiplier:float = 1.0;
var _multFlatModifier:float = 0.0;
var _additive:float = 0.0;

## The final value of the statistic, as a quickly accessible [float].
## Calculated within [method mp_sync].
## [br]This is what should be used to read the current value of the Statistic.
## [b]Do not modify this value.[/b]
@onready var val:float = baseValue;


func _ready():
	_entered_tree.emit()
	_waitingForTree = false
	process_mode = PROCESS_MODE_DISABLED

## If the client has authority to do so, recalculates the value of the Stat and
## reliably replicates the Stat's contents across all other clients.
## Otherwise, does nothing, making it safe to use without authority. [br]
## This method is invoked automatically by [method setBase], [method modifyBase],
## [method modifyMult], [method modifyMultFlat], and [method modifyFlat].
func mp_sync():
	if _waitingForTree: #ensure the Stat has entered the tree before doing initial mp_sync
		await _entered_tree
	if is_inside_tree() and is_multiplayer_authority():
		val = (baseValue + _baseModifier) * (_multiplier + _multFlatModifier) + _additive;
		valueChanged.emit(getValue());
		await get_tree().create_timer(0.1).timeout
		_mp_sync_rpc.rpc(baseValue, _baseModifier, _multiplier,
				_multFlatModifier, _additive)

@rpc("authority", "call_remote", "reliable")
func _mp_sync_rpc(base:float, baseadd:float, mult:float, multadd:float, add:float):
	baseValue = base;
	_baseModifier = baseadd;
	_multiplier = mult;
	_multFlatModifier = multadd;
	_additive = add;
	val = (baseValue + _baseModifier) * (_multiplier + _multFlatModifier) + _additive;
	valueChanged.emit(getValue());


## A static method to act as a constructor for Stats.
## At minimum, requires a base value for the Stat. A Stat does not necessarily
## need to exist in the [SceneTree] to work, but in most cases, it will still
## be in the tree. For this, use [param nodeName] and [param parent]
## to save the trouble of using [member Node.name] and [method Node.add_child] on separate lines.
## [br][br][b]This can be used inline for fields decorated with [annotation @GDscript.@export]![/b]
static func fromBase(base:float, nodeName:String="", parent:Node=null) -> Stat:
	var newStat:Stat = Stat.new()
	newStat.setBase.call_deferred(base)
	if nodeName != "":
		newStat.name = nodeName
	if parent != null:
		newStat._waitingForTree = true
		parent.add_child.call_deferred(newStat)
	return newStat


## Set the base value of the statistic, then sync across clients.
func setBase(value:float):
	baseValue = value
	mp_sync()


## Additively modify the base value of the statistic, before multipliers, then sync across clients.
## [br]Negative numbers may be used for base stat decreases.
func modifyBase(flatValue:float):
	_baseModifier += flatValue
	mp_sync()


## Multiplicatively modify the value of the statistic, stacking multiplicatively with other
## multiplicative modifiers, then sync across clients.
## [br]Numbers below 1 may be used to divide a Stat.
## For example: [code]modifyMult(2)[/code] doubles the base value, and [code]modifyMult(0.5)[/code] halves it.
func modifyMult(factor:float):
	_multiplier *= factor
	mp_sync()


## Multiplicatively modify the value of the statistic, stacking additively with other
## multiplicative modifiers, then sync across clients.
## Negative numbers may be used for percentage-based stat decreases.
## For example, [code]modifyMultFlat(-0.8)[/code] means an 80% reduction.
func modifyMultFlat(flatValue:float):
	_multFlatModifier += flatValue
	mp_sync()


## Add a flat value to the statistic, after multipliers, then sync across clients.
## [br]Negative numbers may be used for flat stat decreases.
func modifyFlat(flatValue:float):
	_additive += flatValue
	mp_sync()


## Returns the final value of the statistic.
## Previously, this would calculate the final value of the statistic, and [member val] was meant
## to be a shorthand for this method. For performance reasons, this is no longer the case - this
## method only returns the value of [member val].
func getValue() -> float:
	return val

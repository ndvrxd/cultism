extends Control

var ability:Ability
@export var keyIcon:Texture2D;
@export var iconScale:float = 1
@onready var tooltip:Control = $"tooled tip/offset/PanelContainer"
@onready var offset:Control = $"tooled tip/offset"

func _ready():
	$icon_anchor.scale = Vector2.ONE * iconScale
	$icon_anchor/input_hint.texture = keyIcon;

func set_ability(a:Ability) -> void:
	ability = a
	$icon_anchor/TextureRect/icon.texture = ability.portrait
	$"tooled tip/offset/PanelContainer/MarginContainer/VBoxContainer/name".text = ability.ability_name
	$"tooled tip/offset/PanelContainer/MarginContainer/VBoxContainer/desc".text = ability.ability_desc
		
func _process(_delta):
	if ability and is_instance_valid(ability):
		$icon_anchor/cooldown.visible = ability.isOnCooldown or ability.isCharging
		if ability.isCharging:
			$icon_anchor/cooldown.value = 1 - ability.chargeTimer / ability.stat_chargeTime.val
		else:
			$icon_anchor/cooldown.value = 1 - ability.cdTimer / ability.stat_cooldown.val
	# keep the tooltip within the left boundary of the screen
	if get_screen_position().x < tooltip.size.x + 50:
		offset.offset_right = (tooltip.size.x - 40) - get_screen_position().x
	else:
		offset.offset_right = 0

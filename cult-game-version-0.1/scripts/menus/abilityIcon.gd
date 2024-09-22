extends Control

var ability:Ability
@export var keyIcon:Texture2D;
@export var iconScale:float = 1

func _ready():
	$icon_anchor.scale = Vector2.ONE * iconScale
	$icon_anchor/input_hint.texture = keyIcon;

func set_ability(a:Ability) -> void:
	ability = a
	$icon_anchor/TextureRect/icon.texture = ability.portrait
	$"tooled tip/PanelContainer/MarginContainer/VBoxContainer/name".text = ability.ability_name
	$"tooled tip/PanelContainer/MarginContainer/VBoxContainer/desc".text = ability.ability_desc

func _process(_delta):
	if ability and is_instance_valid(ability):
		$icon_anchor/cooldown.visible = ability.isOnCooldown or ability.isCharging
		$icon_anchor/cooldown.value = 1 - ability.cdTimer / ability.stat_cooldown.val

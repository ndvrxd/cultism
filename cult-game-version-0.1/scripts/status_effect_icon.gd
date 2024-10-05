extends Control

var effect:StatusEffect

func _ready() -> void:
	effect.effect_removed.connect(queue_free)
	$bar.texture_under = effect.icon
	$bar.texture_progress = effect.icon

func _process(_delta:float) -> void:
	$bar.value = 1 - effect._age / effect.duration

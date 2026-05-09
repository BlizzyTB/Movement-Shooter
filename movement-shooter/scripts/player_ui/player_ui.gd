extends CanvasLayer
class_name PlayerUI

@export var interaction_label: Label

@export_category("Damage UI")
@export var damage_flash: ColorRect
@export var health_label: Label
@export var reset_prompt: Label

@export var flash_fade_speed: float = 5.0

var flash_alpha: float = 0.0


func _ready() -> void:
	if interaction_label != null:
		interaction_label.text = ""

	if damage_flash != null:
		damage_flash.color = Color(1.0, 0.0, 0.0, 0.0)
		damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reset_prompt != null:
		reset_prompt.visible = false


func _process(delta: float) -> void:
	_update_damage_flash(delta)


func set_interaction_text(text: String) -> void:
	if interaction_label == null:
		return

	interaction_label.text = text


func clear_interaction_text() -> void:
	if interaction_label == null:
		return

	interaction_label.text = ""


func show_damage_flash(strength: float = 0.45) -> void:
	flash_alpha = strength

	if damage_flash != null:
		damage_flash.color = Color(1.0, 0.0, 0.0, flash_alpha)


func update_health(current_health: float, max_health: float) -> void:
	if health_label == null:
		return

	health_label.text = "HP: %d / %d" % [
		int(current_health),
		int(max_health)
	]


func show_death_prompt() -> void:
	if reset_prompt == null:
		return

	reset_prompt.visible = true
	reset_prompt.text = "PRESS R TO RESET"


func hide_death_prompt() -> void:
	if reset_prompt == null:
		return

	reset_prompt.visible = false


func _update_damage_flash(delta: float) -> void:
	if damage_flash == null:
		return

	if flash_alpha <= 0.0:
		return

	flash_alpha = max(flash_alpha - flash_fade_speed * delta, 0.0)
	damage_flash.color = Color(1.0, 0.0, 0.0, flash_alpha)
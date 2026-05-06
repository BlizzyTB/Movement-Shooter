extends CanvasLayer
class_name PlayerUI

@export var target_player: Player

@onready var crosshair_texture: TextureRect = $CenterContainer/TextureRect
@onready var prompt_label: Label = $Control/Label
@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	await get_tree().process_frame

	if target_player == null:
		var parent := get_parent()

		if parent is Player:
			target_player = parent

	if target_player == null:
		push_warning("PlayerUI: No target_player assigned.")
		return

	target_player.ray_target_changed.connect(on_ray_target_changed)

	clear_prompt_text()


func set_prompt_text(new_text: String) -> void:
	prompt_label.text = new_text
	prompt_label.visible = true


func clear_prompt_text() -> void:
	prompt_label.text = ""
	prompt_label.visible = false


func set_crosshair_texture(new_texture: Texture2D) -> void:
	crosshair_texture.texture = new_texture


func on_ray_target_changed(target: Node) -> void:
	if target == null:
		clear_prompt_text()
		return

	if target.is_in_group("interactable"):
		var prompt_text := get_prompt_text_from_target(target)

		if prompt_text != "":
			set_prompt_text(prompt_text)
		else:
			set_prompt_text("Press E to interact")

		return

	if target.is_in_group("observable"):
		set_prompt_text(target.name)
		return

	clear_prompt_text()


func get_prompt_text_from_target(target: Node) -> String:
	if "prompt_text" in target:
		return str(target.prompt_text)

	if target.has_method("get_prompt_text"):
		return str(target.get_prompt_text())

	return ""
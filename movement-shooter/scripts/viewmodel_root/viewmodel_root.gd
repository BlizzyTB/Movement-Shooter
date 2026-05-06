extends Node3D
class_name PlayerViewmodel

@onready var animation_player: AnimationPlayer = $Arms/AnimationPlayer

@export var idle_animation: StringName = &"Rest"
@export var punch_animation: StringName = &"Jab_L"


func _ready() -> void:
	print("Viewmodel ready. AnimationPlayer: ", animation_player)

	if animation_player:
		print("Animations found:")
		for anim_name in animation_player.get_animation_list():
			print("- ", anim_name)

	play_idle()


func play_idle() -> void:
	if animation_player == null:
		print("No AnimationPlayer found.")
		return

	if not animation_player.has_animation(idle_animation):
		print("Missing idle animation: ", idle_animation)
		return

	animation_player.play(idle_animation)


func play_punch() -> void:
	print("play_punch called")

	if animation_player == null:
		print("No AnimationPlayer found.")
		return

	if not animation_player.has_animation(punch_animation):
		print("Missing punch animation: ", punch_animation)
		print("Available animations: ", animation_player.get_animation_list())
		return

	animation_player.stop()
	animation_player.play(punch_animation)
	print("Playing punch animation: ", punch_animation)


func _on_animation_player_animation_finished(animation_name: StringName) -> void:
	if animation_name == punch_animation:
		play_idle()
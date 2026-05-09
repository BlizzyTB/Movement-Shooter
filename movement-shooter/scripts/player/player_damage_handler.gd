extends Node
class_name PlayerDamageHandler

@export var player: CharacterBody3D
@export var health_component: HealthComponent
@export var camera: Camera3D
@export var player_ui: Node

@export var reset_action: StringName = "reset_player"
@export var hit_camera_kick: float = 0.08

var spawn_position: Vector3
var spawn_rotation: Vector3
var is_dead: bool = false


func _ready() -> void:
	if player == null:
		player = owner as CharacterBody3D

	if player != null:
		spawn_position = player.global_position
		spawn_rotation = player.global_rotation

	if health_component == null:
		health_component = owner.get_node_or_null("HealthComponent")

	if health_component == null:
		push_error("PlayerDamageHandler needs a HealthComponent.")
		return

	if not health_component.damaged.is_connected(_on_damaged):
		health_component.damaged.connect(_on_damaged)

	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

	_update_ui_health()
	_hide_death_prompt()


func _input(event: InputEvent) -> void:
	if not is_dead:
		return

	if event.is_action_pressed(reset_action):
		reset_player()


func _on_damaged(info: DamageInfo) -> void:
	if is_dead:
		return

	_show_damage_flash()
	_update_ui_health()

	if camera != null:
		camera.rotation.x += hit_camera_kick


func _on_died(info: DamageInfo) -> void:
	if is_dead:
		return

	is_dead = true

	_update_ui_health()
	_show_death_prompt()

	if player != null:
		player.velocity = Vector3.ZERO

		if player.has_method("set_input_enabled"):
			player.set_input_enabled(false)


func reset_player() -> void:
	if player == null or health_component == null:
		return

	is_dead = false

	player.global_position = spawn_position
	player.global_rotation = spawn_rotation
	player.velocity = Vector3.ZERO

	health_component.reset_health()

	if player.has_method("set_input_enabled"):
		player.set_input_enabled(true)

	_hide_death_prompt()
	_update_ui_health()


func _show_damage_flash() -> void:
	if player_ui != null and player_ui.has_method("show_damage_flash"):
		player_ui.show_damage_flash()


func _update_ui_health() -> void:
	if health_component == null:
		return

	if player_ui != null and player_ui.has_method("update_health"):
		player_ui.update_health(
			health_component.current_health,
			health_component.max_health
		)


func _show_death_prompt() -> void:
	if player_ui != null and player_ui.has_method("show_death_prompt"):
		player_ui.show_death_prompt()


func _hide_death_prompt() -> void:
	if player_ui != null and player_ui.has_method("hide_death_prompt"):
		player_ui.hide_death_prompt()
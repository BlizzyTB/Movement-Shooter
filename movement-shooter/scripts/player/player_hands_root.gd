extends Node3D
class_name PlayerHandsRoot3D

@export_category("Weapon Slot")
@export var weapon_slot: Node3D

@export_category("Weapon Viewmodel Positioning")
@export var weapon_position_offset: Vector3 = Vector3.ZERO
@export var weapon_rotation_offset_degrees: Vector3 = Vector3.ZERO
@export var weapon_scale: Vector3 = Vector3.ONE

@export_category("Default Recoil")
@export var default_recoil_position_kick: Vector3 = Vector3(0.0, 0.03, 0.12)
@export var default_recoil_rotation_kick_degrees: Vector3 = Vector3(-6.0, 1.0, 0.0)
@export var default_recoil_snappiness: float = 28.0
@export var default_recoil_return_speed: float = 16.0

@export_category("Default Sway")
@export var default_sway_position_amount: Vector2 = Vector2(0.025, 0.018)
@export var default_sway_rotation_amount_degrees: Vector2 = Vector2(2.0, 2.0)
@export var default_sway_follow_speed: float = 14.0
@export var default_sway_return_speed: float = 10.0

@export_category("Default Bob")
@export var default_bob_position_amount: Vector3 = Vector3(0.035, 0.035, 0.0)
@export var default_bob_rotation_amount_degrees: Vector3 = Vector3(1.0, 1.5, 1.0)
@export var default_bob_walk_speed: float = 8.0
@export var default_bob_sprint_speed: float = 12.0

@export_category("Fire Visual Priority")
@export var fire_visual_buffer_time: float = 0.45
@export_range(0.0, 1.0) var fire_bob_suppression: float = 0.95

@export_category("Tactical Sprint Pose")
@export var tactical_sprint_position: Vector3 = Vector3(0.08, -0.08, -0.04)
@export var tactical_sprint_rotation_degrees: Vector3 = Vector3(35.0, 18.0, 10.0)
@export var tactical_sprint_enter_speed: float = 6.0
@export var tactical_sprint_exit_speed: float = 8.0

@export_category("Landing Kick")
@export var landing_kick_min_impact_speed: float = 6.0
@export var landing_kick_max_impact_speed: float = 22.0
@export var landing_kick_position: Vector3 = Vector3(0.0, -0.08, 0.04)
@export var landing_kick_rotation_degrees: Vector3 = Vector3(7.0, 0.0, 0.0)

var current_weapon_instance: Node3D = null
var current_weapon_data: WeaponItemData = null
var mouse_input_delta: Vector2 = Vector2.ZERO
var recoil_position_target: Vector3 = Vector3.ZERO
var recoil_position_current: Vector3 = Vector3.ZERO
var recoil_rotation_target_degrees: Vector3 = Vector3.ZERO
var recoil_rotation_current_degrees: Vector3 = Vector3.ZERO
var sway_position_current: Vector3 = Vector3.ZERO
var sway_rotation_current_degrees: Vector3 = Vector3.ZERO
var bob_time: float = 0.0
var movement_speed: float = 0.0
var is_sprinting: bool = false
var tactical_sprint_blend: float = 0.0
var fire_visual_timer: float = 0.0


func _ready() -> void:
	apply_visual_motion(0.0)


func _process(delta: float) -> void:
	if fire_visual_timer > 0.0:
		fire_visual_timer -= delta

	update_recoil(delta)
	update_sway(delta)
	update_bob(delta)
	update_tactical_sprint_pose(delta)
	apply_visual_motion(delta)

	mouse_input_delta = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input_delta += event.relative


func set_movement_state(new_movement_speed: float, new_is_sprinting: bool) -> void:
	movement_speed = new_movement_speed
	is_sprinting = new_is_sprinting


func apply_visual_motion(_delta: float) -> void:
	if weapon_slot == null:
		return

	var final_position := weapon_position_offset
	final_position += get_tactical_sprint_position() * tactical_sprint_blend
	final_position += recoil_position_current
	final_position += sway_position_current
	final_position += get_bob_position()

	var final_rotation := weapon_rotation_offset_degrees
	final_rotation += get_tactical_sprint_rotation_degrees() * tactical_sprint_blend
	final_rotation += recoil_rotation_current_degrees
	final_rotation += sway_rotation_current_degrees
	final_rotation += get_bob_rotation_degrees()

	weapon_slot.position = final_position
	weapon_slot.rotation_degrees = final_rotation
	weapon_slot.scale = weapon_scale


func update_recoil(delta: float) -> void:
	var snappiness: float = max(get_recoil_snappiness(), 0.01)
	var return_speed: float = max(get_recoil_return_speed(), 0.01)

	recoil_position_current = recoil_position_current.lerp(
		recoil_position_target,
		clamp(delta * snappiness, 0.0, 1.0)
	)

	recoil_rotation_current_degrees = recoil_rotation_current_degrees.lerp(
		recoil_rotation_target_degrees,
		clamp(delta * snappiness, 0.0, 1.0)
	)

	recoil_position_target = recoil_position_target.lerp(
		Vector3.ZERO,
		clamp(delta * return_speed, 0.0, 1.0)
	)

	recoil_rotation_target_degrees = recoil_rotation_target_degrees.lerp(
		Vector3.ZERO,
		clamp(delta * return_speed, 0.0, 1.0)
	)


func update_sway(delta: float) -> void:
	var sway_position_amount: Vector2 = get_sway_position_amount()
	var sway_rotation_amount: Vector2 = get_sway_rotation_amount_degrees()
	var sway_follow_speed: float = max(get_sway_follow_speed(), 0.01)
	var sway_return_speed: float = max(get_sway_return_speed(), 0.01)

	var normalized_mouse := mouse_input_delta * 0.01

	var target_sway_position := Vector3(
		clamp(-normalized_mouse.x * sway_position_amount.x, -sway_position_amount.x, sway_position_amount.x),
		clamp(normalized_mouse.y * sway_position_amount.y, -sway_position_amount.y, sway_position_amount.y),
		0.0
	)

	var target_sway_rotation := Vector3(
		clamp(-normalized_mouse.y * sway_rotation_amount.y, -sway_rotation_amount.y, sway_rotation_amount.y),
		clamp(-normalized_mouse.x * sway_rotation_amount.x, -sway_rotation_amount.x, sway_rotation_amount.x),
		clamp(-normalized_mouse.x * sway_rotation_amount.x, -sway_rotation_amount.x, sway_rotation_amount.x)
	)

	var follow_weight: float = clamp(delta * sway_follow_speed, 0.0, 1.0)
	var return_weight: float = clamp(delta * sway_return_speed, 0.0, 1.0)

	if mouse_input_delta.length() > 0.0:
		sway_position_current = sway_position_current.lerp(target_sway_position, follow_weight)
		sway_rotation_current_degrees = sway_rotation_current_degrees.lerp(target_sway_rotation, follow_weight)
	else:
		sway_position_current = sway_position_current.lerp(Vector3.ZERO, return_weight)
		sway_rotation_current_degrees = sway_rotation_current_degrees.lerp(Vector3.ZERO, return_weight)


func update_bob(delta: float) -> void:
	if movement_speed <= 0.1:
		bob_time = move_toward(bob_time, 0.0, delta * 6.0)
		return

	var bob_speed: float = get_bob_sprint_speed() if is_sprinting else get_bob_walk_speed()
	bob_speed = max(bob_speed, 0.01)

	bob_time += delta * bob_speed


func update_tactical_sprint_pose(delta: float) -> void:
	var target_blend := 0.0

	if is_sprinting and fire_visual_timer <= 0.0:
		target_blend = 1.0

	var blend_speed := get_tactical_sprint_enter_speed() if target_blend > tactical_sprint_blend else get_tactical_sprint_exit_speed()

	tactical_sprint_blend = move_toward(
		tactical_sprint_blend,
		target_blend,
		blend_speed * delta
	)


func get_bob_position() -> Vector3:
	if movement_speed <= 0.1:
		return Vector3.ZERO

	var bob_amount := get_bob_position_amount()
	var speed_factor: float = clamp(movement_speed / 8.0, 0.0, 1.5)
	var fire_suppression_factor := get_fire_bob_factor()

	return Vector3(
		sin(bob_time) * bob_amount.x * speed_factor * fire_suppression_factor,
		abs(cos(bob_time * 2.0)) * bob_amount.y * speed_factor * fire_suppression_factor,
		sin(bob_time * 0.5) * bob_amount.z * speed_factor * fire_suppression_factor
	)


func get_bob_rotation_degrees() -> Vector3:
	if movement_speed <= 0.1:
		return Vector3.ZERO

	var bob_amount := get_bob_rotation_amount_degrees()
	var speed_factor: float = clamp(movement_speed / 8.0, 0.0, 1.5)
	var fire_suppression_factor := get_fire_bob_factor()

	return Vector3(
		sin(bob_time * 2.0) * bob_amount.x * speed_factor * fire_suppression_factor,
		sin(bob_time) * bob_amount.y * speed_factor * fire_suppression_factor,
		sin(bob_time) * bob_amount.z * speed_factor * fire_suppression_factor
	)


func get_fire_bob_factor() -> float:
	if fire_visual_timer <= 0.0:
		return 1.0

	return 1.0 - fire_bob_suppression


func apply_recoil() -> void:
	recoil_position_target += get_recoil_position_kick()
	recoil_rotation_target_degrees += get_recoil_rotation_kick_degrees()


func apply_landing_kick(impact_speed: float) -> void:
	if impact_speed < landing_kick_min_impact_speed:
		return

	var impact_factor := inverse_lerp(
		landing_kick_min_impact_speed,
		landing_kick_max_impact_speed,
		impact_speed
	)

	impact_factor = clamp(impact_factor, 0.0, 1.0)

	recoil_position_target += landing_kick_position * impact_factor
	recoil_rotation_target_degrees += landing_kick_rotation_degrees * impact_factor


func equip_weapon_scene(scene: PackedScene, weapon_data: WeaponItemData = null) -> void:
	clear_weapon()

	current_weapon_data = weapon_data

	if weapon_slot == null:
		push_warning("PlayerHandsRoot cannot equip weapon: weapon_slot is not assigned.")
		return

	if scene == null:
		push_warning("PlayerHandsRoot cannot equip weapon: scene is null.")
		return

	var instance := scene.instantiate()

	if not instance is Node3D:
		push_warning("PlayerHandsRoot weapon scene root must be Node3D.")
		instance.queue_free()
		return

	current_weapon_instance = instance as Node3D
	weapon_slot.add_child(current_weapon_instance)

	current_weapon_instance.position = Vector3.ZERO
	current_weapon_instance.rotation = Vector3.ZERO
	current_weapon_instance.scale = Vector3.ONE
	current_weapon_instance.visible = true

	reset_procedural_motion()
	apply_visual_motion(0.0)


func clear_weapon() -> void:
	if current_weapon_instance != null:
		current_weapon_instance.queue_free()

	current_weapon_instance = null
	current_weapon_data = null

	reset_procedural_motion()


func reset_procedural_motion() -> void:
	recoil_position_target = Vector3.ZERO
	recoil_position_current = Vector3.ZERO
	recoil_rotation_target_degrees = Vector3.ZERO
	recoil_rotation_current_degrees = Vector3.ZERO
	sway_position_current = Vector3.ZERO
	sway_rotation_current_degrees = Vector3.ZERO
	bob_time = 0.0
	tactical_sprint_blend = 0.0
	fire_visual_timer = 0.0


func play_fire() -> void:
	fire_visual_timer = fire_visual_buffer_time
	apply_recoil()


func get_recoil_position_kick() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.recoil_position_kick

	return default_recoil_position_kick


func get_recoil_rotation_kick_degrees() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.recoil_rotation_kick_degrees

	return default_recoil_rotation_kick_degrees


func get_recoil_snappiness() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.recoil_snappiness, default_recoil_snappiness)

	return default_recoil_snappiness


func get_recoil_return_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.recoil_return_speed, default_recoil_return_speed)

	return default_recoil_return_speed


func get_sway_position_amount() -> Vector2:
	if current_weapon_data != null:
		return current_weapon_data.sway_position_amount

	return default_sway_position_amount


func get_sway_rotation_amount_degrees() -> Vector2:
	if current_weapon_data != null:
		return current_weapon_data.sway_rotation_amount_degrees

	return default_sway_rotation_amount_degrees


func get_sway_follow_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.sway_follow_speed, default_sway_follow_speed)

	return default_sway_follow_speed


func get_sway_return_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.sway_return_speed, default_sway_return_speed)

	return default_sway_return_speed


func get_bob_position_amount() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.bob_position_amount

	return default_bob_position_amount


func get_bob_rotation_amount_degrees() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.bob_rotation_amount_degrees

	return default_bob_rotation_amount_degrees


func get_bob_walk_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.bob_walk_speed, default_bob_walk_speed)

	return default_bob_walk_speed


func get_bob_sprint_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.bob_sprint_speed, default_bob_sprint_speed)

	return default_bob_sprint_speed


func get_tactical_sprint_position() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.tactical_sprint_position

	return tactical_sprint_position


func get_tactical_sprint_rotation_degrees() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.tactical_sprint_rotation_degrees

	return tactical_sprint_rotation_degrees


func get_tactical_sprint_enter_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.tactical_sprint_enter_speed, tactical_sprint_enter_speed)

	return tactical_sprint_enter_speed


func get_tactical_sprint_exit_speed() -> float:
	if current_weapon_data != null:
		return safe_float(current_weapon_data.tactical_sprint_exit_speed, tactical_sprint_exit_speed)

	return tactical_sprint_exit_speed


func safe_float(value, fallback: float) -> float:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)

	return fallback
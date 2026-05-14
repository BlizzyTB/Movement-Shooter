extends Node3D
class_name PlayerHandsRoot

## First-person hand/equipment visual root.
## Owns weapon viewmodel placement, procedural sway, procedural bob, and procedural recoil.

@export_category("Equipment Slots")
## Slot where the current first-person weapon viewmodel is spawned.
@export var weapon_slot: Node3D

## Slot for future left-hand tools, artifacts, carried objects, or hand visuals.
@export var left_hand_slot: Node3D


@export_category("Weapon Viewmodel Positioning")
## Base local position offset applied to WeaponSlot.
@export var weapon_position_offset: Vector3 = Vector3.ZERO

## Base local rotation offset applied to WeaponSlot, in degrees.
@export var weapon_rotation_offset_degrees: Vector3 = Vector3.ZERO

## Base local scale applied to WeaponSlot.
@export var weapon_scale: Vector3 = Vector3.ONE


@export_category("Left Hand Slot Positioning")
## Local position offset applied to LeftHandSlot.
@export var left_hand_position_offset: Vector3 = Vector3.ZERO

## Local rotation offset applied to LeftHandSlot, in degrees.
@export var left_hand_rotation_offset_degrees: Vector3 = Vector3.ZERO

## Local scale applied to LeftHandSlot.
@export var left_hand_scale: Vector3 = Vector3.ONE


@export_category("Default Recoil")
## Default recoil position kick used when no weapon data is assigned.
@export var default_recoil_position_kick: Vector3 = Vector3(0.0, 0.03, 0.12)

## Default recoil rotation kick in degrees used when no weapon data is assigned.
@export var default_recoil_rotation_kick_degrees: Vector3 = Vector3(-6.0, 1.0, 0.0)

## Default recoil snappiness used when no weapon data is assigned.
@export var default_recoil_snappiness: float = 28.0

## Default recoil return speed used when no weapon data is assigned.
@export var default_recoil_return_speed: float = 16.0


@export_category("Default Sway")
## Default maximum positional sway from mouse movement.
@export var default_sway_position_amount: Vector2 = Vector2(0.025, 0.018)

## Default maximum rotational sway from mouse movement, in degrees.
@export var default_sway_rotation_amount_degrees: Vector2 = Vector2(2.0, 2.0)

## Default sway follow speed.
@export var default_sway_follow_speed: float = 14.0

## Default sway return speed.
@export var default_sway_return_speed: float = 10.0


@export_category("Default Bob")
## Default weapon bob position amount while moving.
@export var default_bob_position_amount: Vector3 = Vector3(0.035, 0.035, 0.0)

## Default weapon bob rotation amount in degrees while moving.
@export var default_bob_rotation_amount_degrees: Vector3 = Vector3(1.0, 1.5, 1.0)

## Default bob speed while walking.
@export var default_bob_walk_speed: float = 8.0

## Default bob speed while sprinting.
@export var default_bob_sprint_speed: float = 12.0


## Current weapon viewmodel instance spawned under weapon_slot.
var current_weapon_instance: Node3D = null

## Current left-hand item/viewmodel instance spawned under left_hand_slot.
var current_left_hand_instance: Node3D = null

## Current equipped weapon data used for per-weapon procedural tuning.
var current_weapon_data: WeaponItemData = null

## Current mouse input accumulated this frame for sway.
var mouse_input_delta: Vector2 = Vector2.ZERO

## Current target recoil position.
var recoil_position_target: Vector3 = Vector3.ZERO

## Current displayed recoil position.
var recoil_position_current: Vector3 = Vector3.ZERO

## Current target recoil rotation in degrees.
var recoil_rotation_target_degrees: Vector3 = Vector3.ZERO

## Current displayed recoil rotation in degrees.
var recoil_rotation_current_degrees: Vector3 = Vector3.ZERO

## Current displayed sway position.
var sway_position_current: Vector3 = Vector3.ZERO

## Current displayed sway rotation in degrees.
var sway_rotation_current_degrees: Vector3 = Vector3.ZERO

## Running timer for weapon bob.
var bob_time: float = 0.0

## Current movement speed used for weapon bob.
var movement_speed: float = 0.0

## True when player is sprinting, used to speed up bob.
var is_sprinting: bool = false


func _ready() -> void:
	apply_visual_motion(0.0)


func _process(delta: float) -> void:
	update_recoil(delta)
	update_sway(delta)
	update_bob(delta)
	apply_visual_motion(delta)
	mouse_input_delta = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_input_delta += event.relative


## Updates movement values used by weapon bob.
##
## new_movement_speed:
## Horizontal movement speed from the player controller.
##
## new_is_sprinting:
## True when player is sprinting.
func set_movement_state(new_movement_speed: float, new_is_sprinting: bool) -> void:
	movement_speed = new_movement_speed
	is_sprinting = new_is_sprinting


## Applies all procedural motion and base offsets to equipment slots.
##
## delta:
## Frame time. Currently unused, but kept for future smoothing changes.
func apply_visual_motion(_delta: float) -> void:
	if weapon_slot != null:
		var final_position := weapon_position_offset
		final_position += recoil_position_current
		final_position += sway_position_current
		final_position += get_bob_position()

		var final_rotation := weapon_rotation_offset_degrees
		final_rotation += recoil_rotation_current_degrees
		final_rotation += sway_rotation_current_degrees
		final_rotation += get_bob_rotation_degrees()

		weapon_slot.position = final_position
		weapon_slot.rotation_degrees = final_rotation
		weapon_slot.scale = weapon_scale

	if left_hand_slot != null:
		left_hand_slot.position = left_hand_position_offset
		left_hand_slot.rotation_degrees = left_hand_rotation_offset_degrees
		left_hand_slot.scale = left_hand_scale


## Updates recoil target/current values.
##
## delta:
## Frame time.
func update_recoil(delta: float) -> void:
	var snappiness := get_recoil_snappiness()
	var return_speed := get_recoil_return_speed()

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


## Updates mouse-driven sway.
##
## delta:
## Frame time.
func update_sway(delta: float) -> void:
	var sway_position_amount := get_sway_position_amount()
	var sway_rotation_amount := get_sway_rotation_amount_degrees()
	var sway_follow_speed := get_sway_follow_speed()
	var sway_return_speed := get_sway_return_speed()

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


## Updates bob timer based on movement.
##
## delta:
## Frame time.
func update_bob(delta: float) -> void:
	if movement_speed <= 0.1:
		bob_time = lerp(bob_time, 0.0, clamp(delta * 6.0, 0.0, 1.0))
		return

	var bob_speed := get_bob_sprint_speed() if is_sprinting else get_bob_walk_speed()
	bob_time += delta * bob_speed


## Returns current procedural bob position.
func get_bob_position() -> Vector3:
	if movement_speed <= 0.1:
		return Vector3.ZERO

	var bob_amount := get_bob_position_amount()
	var speed_factor: float = clamp(movement_speed / 8.0, 0.0, 1.5)

	return Vector3(
		sin(bob_time) * bob_amount.x * speed_factor,
		abs(cos(bob_time * 2.0)) * bob_amount.y * speed_factor,
		sin(bob_time * 0.5) * bob_amount.z * speed_factor
	)


## Returns current procedural bob rotation in degrees.
func get_bob_rotation_degrees() -> Vector3:
	if movement_speed <= 0.1:
		return Vector3.ZERO

	var bob_amount := get_bob_rotation_amount_degrees()
	var speed_factor: float = clamp(movement_speed / 8.0, 0.0, 1.5)

	return Vector3(
		sin(bob_time * 2.0) * bob_amount.x * speed_factor,
		sin(bob_time) * bob_amount.y * speed_factor,
		sin(bob_time) * bob_amount.z * speed_factor
	)


## Adds recoil using the currently equipped weapon's recoil settings.
func apply_recoil() -> void:
	recoil_position_target += get_recoil_position_kick()
	recoil_rotation_target_degrees += get_recoil_rotation_kick_degrees()


## Equips a first-person weapon scene into WeaponSlot.
##
## scene:
## PackedScene used for the weapon's first-person visual model.
##
## weapon_data:
## Optional WeaponItemData used for per-weapon procedural tuning.
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


## Equips a left-hand visual scene into LeftHandSlot.
##
## scene:
## PackedScene used for future left-hand items/tools/artifacts.
func equip_left_hand_scene(scene: PackedScene) -> void:
	clear_left_hand()

	if left_hand_slot == null:
		push_warning("PlayerHandsRoot cannot equip left hand scene: left_hand_slot is not assigned.")
		return

	if scene == null:
		push_warning("PlayerHandsRoot cannot equip left hand scene: scene is null.")
		return

	var instance := scene.instantiate()

	if not instance is Node3D:
		push_warning("PlayerHandsRoot left hand scene root must be Node3D.")
		instance.queue_free()
		return

	current_left_hand_instance = instance as Node3D
	left_hand_slot.add_child(current_left_hand_instance)

	current_left_hand_instance.position = Vector3.ZERO
	current_left_hand_instance.rotation = Vector3.ZERO
	current_left_hand_instance.scale = Vector3.ONE
	current_left_hand_instance.visible = true

	apply_visual_motion(0.0)


## Removes the current weapon viewmodel.
func clear_weapon() -> void:
	if current_weapon_instance != null:
		current_weapon_instance.queue_free()
		current_weapon_instance = null

	current_weapon_data = null
	reset_procedural_motion()


## Removes the current left-hand viewmodel/item.
func clear_left_hand() -> void:
	if current_left_hand_instance != null:
		current_left_hand_instance.queue_free()
		current_left_hand_instance = null


## Resets recoil, sway, and bob back to neutral.
func reset_procedural_motion() -> void:
	recoil_position_target = Vector3.ZERO
	recoil_position_current = Vector3.ZERO
	recoil_rotation_target_degrees = Vector3.ZERO
	recoil_rotation_current_degrees = Vector3.ZERO
	sway_position_current = Vector3.ZERO
	sway_rotation_current_degrees = Vector3.ZERO
	bob_time = 0.0


## Placeholder for future procedural fire visuals.
func play_fire() -> void:
	apply_recoil()


## Placeholder for future left-hand action visuals.
func play_left_hand_action() -> void:
	pass


## Returns active recoil position kick.
func get_recoil_position_kick() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.recoil_position_kick

	return default_recoil_position_kick


## Returns active recoil rotation kick in degrees.
func get_recoil_rotation_kick_degrees() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.recoil_rotation_kick_degrees

	return default_recoil_rotation_kick_degrees


## Returns active recoil snappiness.
func get_recoil_snappiness() -> float:
	if current_weapon_data != null:
		return current_weapon_data.recoil_snappiness

	return default_recoil_snappiness


## Returns active recoil return speed.
func get_recoil_return_speed() -> float:
	if current_weapon_data != null:
		return current_weapon_data.recoil_return_speed

	return default_recoil_return_speed


## Returns active sway position amount.
func get_sway_position_amount() -> Vector2:
	if current_weapon_data != null:
		return current_weapon_data.sway_position_amount

	return default_sway_position_amount


## Returns active sway rotation amount in degrees.
func get_sway_rotation_amount_degrees() -> Vector2:
	if current_weapon_data != null:
		return current_weapon_data.sway_rotation_amount_degrees

	return default_sway_rotation_amount_degrees


## Returns active sway follow speed.
func get_sway_follow_speed() -> float:
	if current_weapon_data != null:
		return current_weapon_data.sway_follow_speed

	return default_sway_follow_speed


## Returns active sway return speed.
func get_sway_return_speed() -> float:
	if current_weapon_data != null:
		return current_weapon_data.sway_return_speed

	return default_sway_return_speed


## Returns active bob position amount.
func get_bob_position_amount() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.bob_position_amount

	return default_bob_position_amount


## Returns active bob rotation amount in degrees.
func get_bob_rotation_amount_degrees() -> Vector3:
	if current_weapon_data != null:
		return current_weapon_data.bob_rotation_amount_degrees

	return default_bob_rotation_amount_degrees


## Returns active walking bob speed.
func get_bob_walk_speed() -> float:
	if current_weapon_data != null:
		return current_weapon_data.bob_walk_speed

	return default_bob_walk_speed


## Returns active sprinting bob speed.
func get_bob_sprint_speed() -> float:
	if current_weapon_data != null:
		return current_weapon_data.bob_sprint_speed

	return default_bob_sprint_speed
extends CharacterBody3D
class_name Player

signal control_mode_changed(old_mode, new_mode)
signal movement_state_changed(old_state, new_state)
signal ray_target_changed(new_target)

enum ControlMode {
	ON_FOOT,
	IN_VEHICLE,
	LOCKED,
	MENU,
	DEAD
}

enum MovementState {
	GROUNDED,
	AIRBORNE,
	DASHING,
	SLIDING,
	WALL_SLIDING
}

@export_category("Movement")

## Base 1:1 movement speed while on foot.
## This is the normal combat movement speed.
@export var move_speed: float = 12.0

## Upward force applied when jumping.
## Higher values make jumps taller.
@export var jump_velocity: float = 6.5

## How quickly horizontal movement changes while airborne.
## Lower values feel floatier. Higher values feel snappier.
@export var air_lerp_speed: float = 2.0

## Downward force applied while airborne.
## Higher values make the player fall faster and feel heavier.
@export var gravity: float = 22.0


@export_category("Jump Feel")

## Small grace window after leaving a ledge where jumping is still allowed.
## Makes platforming feel more forgiving.
@export var coyote_time: float = 0.12

## Small window where an early jump press is remembered.
## Makes jumps trigger even if the button was pressed slightly before landing.
@export var jump_buffer_time: float = 0.12


@export_category("Wall Movement")

## Maximum downward speed while sliding on a wall.
## Lower values make the player slide down more slowly.
@export var wall_slide_fall_speed: float = 2.0

## Instant horizontal pulse away from the wall during a wall jump.
## Higher values make the wall jump pop harder.
@export var wall_jump_horizontal_speed: float = 12.0

## Upward speed applied during a wall jump.
## Higher values make wall jumps taller.
@export var wall_jump_vertical_speed: float = 12.0

## Very short time where normal 1:1 movement is paused after wall jumping.
## This preserves the wall-jump pulse before control returns.
@export var wall_jump_lock_time: float = 0.08

## Brief time after dash where wall jumps are ignored.
## Prevents dash-wall collisions from accidentally launching the player.
@export var dash_wall_jump_lock_time: float = 0.12


@export_category("Dash")

## Fixed distance covered by a dash.
## Higher values make the dash travel farther.
@export var dash_distance: float = 4.0

## How long the dash lasts in seconds.
## Shorter values feel sharper and more punchy.
@export var dash_duration: float = 0.14

## Time before another dash can be used.
## Lower values allow more frequent dashing.
@export var dash_cooldown: float = 0.35


@export_category("Slide")

## Speed of the committed slide burst.
## Higher values make slides more aggressive.
@export var slide_speed: float = 18.0

## How long the slide lasts in seconds.
## Lower values make slides snappier.
@export var slide_duration: float = 0.35

## Extra horizontal speed added when jumping out of a slide.
## Gives slide-jumps a small burst of momentum.
@export var slide_jump_boost: float = 7.0

## How long an air-pressed slide input is remembered.
## Lets the player press slide before landing and slide immediately on touchdown.
@export var slide_buffer_time: float = 1.0


@export_category("Camera Juice")

## Vertical camera bob amount while moving.
## Keep this subtle to avoid motion sickness.
@export var bob_amount: float = 0.045

## How fast the movement bob cycles.
## Higher values make the bob feel quicker.
@export var bob_speed: float = 20.0

## How quickly the camera returns to its resting position.
## Higher values snap back faster.
@export var bob_reset_speed: float = 12.0

## Tiny idle breathing motion amount.
## Keep very low for a subtle living camera feel.
@export var breathing_amount: float = 0.012

## Speed of the breathing motion.
## Lower values feel slower and calmer.
@export var breathing_speed: float = 1.6

## How far the camera dips while sliding.
## Higher values make slides feel lower and faster.
@export var slide_camera_dip: float = 0.45

## Camera roll amount when strafing left or right.
## Higher values create stronger side tilt.
@export var side_tilt_amount: float = 3.0

## Small pitch offset when moving forward or backward.
## Higher values make movement feel more physical.
@export var forward_tilt_amount: float = 1.2

## How quickly camera tilt reacts to movement input.
## Higher values feel snappier.
@export var camera_tilt_speed: float = 10.0


@export_category("Mouse Look")

## Mouse sensitivity for first-person camera control.
## Higher values turn the camera faster.
@export var mouse_sensitivity: float = 0.003

## Maximum vertical look angle in degrees.
## Prevents the camera from flipping over.
@export var max_look_angle: float = 89.0


var control_mode: ControlMode = ControlMode.ON_FOOT
var movement_state: MovementState = MovementState.GROUNDED

var look_pitch: float = 0.0

var ray_target: Node = null
var previous_ray_target: Node = null

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_recovery_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_start_position: Vector3 = Vector3.ZERO
var dash_target_position: Vector3 = Vector3.ZERO
var dash_elapsed: float = 0.0

var slide_timer: float = 0.0
var slide_direction: Vector3 = Vector3.ZERO

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var slide_buffer_timer: float = 0.0

var wall_jump_lock_timer: float = 0.0
var wall_normal: Vector3 = Vector3.ZERO

var bob_timer: float = 0.0
var breathing_timer: float = 0.0
var head_start_position: Vector3

@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var sliding_collision: CollisionShape3D = $SlidingCollision

@onready var stand_check: RayCast3D = $MovementChecks/StandCheck
@onready var wall_check_forward: RayCast3D = $MovementChecks/WallCheckForward
@onready var wall_check_back: RayCast3D = $MovementChecks/WallCheckBack
@onready var wall_check_left: RayCast3D = $MovementChecks/WallCheckLeft
@onready var wall_check_right: RayCast3D = $MovementChecks/WallCheckRight

@onready var head: Node3D = $Head
@onready var interaction_ray: RayCast3D = $Head/InteractionRay
@onready var player_camera: Camera3D = $Head/PlayerCam
@onready var debug_label: Label = $CanvasLayer/DebugLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_start_position = head.position
	set_slide_collider_active(false)
	refresh_debug_display()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_look(event)

	if Input.is_action_just_pressed("test_input_1"):
		set_control_mode(ControlMode.ON_FOOT)

	if Input.is_action_just_pressed("test_input_2"):
		set_control_mode(ControlMode.IN_VEHICLE)

	if Input.is_action_just_pressed("test_input_3"):
		set_control_mode(ControlMode.LOCKED)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if Input.is_action_just_pressed("slide"):
		slide_buffer_timer = slide_buffer_time

	if Input.is_action_just_pressed("interact"):
		handle_interact_input()


func _physics_process(delta: float) -> void:
	update_timers(delta)
	handle_interaction_ray()
	update_wall_detection()
	update_coyote_time()
	apply_gravity(delta)

	if can_move():
		handle_dash_input()
		handle_slide_input()
		handle_jump()
		handle_movement(delta)
	else:
		stop_horizontal_movement()

	if movement_state != MovementState.DASHING:
		move_and_slide()

	if movement_state == MovementState.SLIDING and get_slide_collision_count() > 0:
		cancel_slide()

	update_movement_state()
	update_camera_juice(delta)
	refresh_debug_display()


func handle_mouse_look(event: InputEventMouseMotion) -> void:
	if not can_look():
		return

	rotate_y(-event.relative.x * mouse_sensitivity)

	look_pitch -= event.relative.y * mouse_sensitivity
	look_pitch = clamp(look_pitch, deg_to_rad(-max_look_angle), deg_to_rad(max_look_angle))


func update_camera_juice(delta: float) -> void:
	breathing_timer += delta

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving_on_ground := (
		horizontal_speed > 0.1
		and is_on_floor()
		and movement_state != MovementState.SLIDING
	)

	var target_position := head_start_position

	if is_moving_on_ground:
		bob_timer += delta * bob_speed
		target_position.y += sin(bob_timer) * bob_amount
	else:
		bob_timer = 0.0

	target_position.y += sin(breathing_timer * breathing_speed) * breathing_amount

	if movement_state == MovementState.SLIDING:
		target_position.y -= slide_camera_dip

	head.position = head.position.lerp(target_position, bob_reset_speed * delta)

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var target_roll := -input_dir.x * deg_to_rad(side_tilt_amount)
	var target_pitch_offset := input_dir.y * deg_to_rad(forward_tilt_amount)

	head.rotation.x = look_pitch + lerp_angle(
		head.rotation.x - look_pitch,
		target_pitch_offset,
		camera_tilt_speed * delta
	)

	head.rotation.z = lerp_angle(
		head.rotation.z,
		target_roll,
		camera_tilt_speed * delta
	)


func update_timers(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if dash_recovery_timer > 0.0:
		dash_recovery_timer -= delta

	if slide_timer > 0.0:
		slide_timer -= delta

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	if slide_buffer_timer > 0.0:
		slide_buffer_timer -= delta


func update_wall_detection() -> void:
	if movement_state == MovementState.DASHING:
		wall_normal = Vector3.ZERO
		return

	wall_normal = Vector3.ZERO

	var checks: Array[RayCast3D] = [
		wall_check_forward,
		wall_check_back,
		wall_check_left,
		wall_check_right
	]

	for check in checks:
		check.force_raycast_update()

		if check.is_colliding():
			var normal := check.get_collision_normal()

			if abs(normal.y) < 0.2:
				wall_normal = normal
				return


func update_coyote_time() -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - get_physics_process_delta_time(), 0.0)


func apply_gravity(delta: float) -> void:
	if movement_state == MovementState.DASHING:
		return

	if is_wall_sliding():
		velocity.y = max(velocity.y - gravity * delta, -wall_slide_fall_speed)
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0


func is_wall_sliding() -> bool:
	return (
		not is_on_floor()
		and wall_normal != Vector3.ZERO
		and velocity.y <= 0.0
		and movement_state != MovementState.DASHING
		and movement_state != MovementState.SLIDING
		and dash_recovery_timer <= 0.0
	)


func handle_movement(delta: float) -> void:
	if movement_state == MovementState.DASHING:
		handle_linear_dash(delta)
		return

	if movement_state == MovementState.SLIDING:
		velocity.x = slide_direction.x * slide_speed
		velocity.z = slide_direction.z * slide_speed
		return

	if wall_jump_lock_timer > 0.0:
		return

	var move_direction := get_input_move_direction()

	if is_on_floor():
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
	else:
		var air_weight: float = clamp(air_lerp_speed * delta, 0.0, 1.0)
		velocity.x = lerp(velocity.x, move_direction.x * move_speed, air_weight)
		velocity.z = lerp(velocity.z, move_direction.z * move_speed, air_weight)


func handle_linear_dash(delta: float) -> void:
	dash_elapsed += delta

	var dash_progress: float = clamp(dash_elapsed / dash_duration, 0.0, 1.0)
	var next_position: Vector3 = dash_start_position.lerp(dash_target_position, dash_progress)

	var motion: Vector3 = next_position - global_position
	var collision: KinematicCollision3D = move_and_collide(motion)

	velocity = Vector3.ZERO

	if collision != null:
		dash_timer = 0.0
		dash_recovery_timer = dash_wall_jump_lock_time


func handle_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return

	if movement_state == MovementState.DASHING:
		return

	if movement_state == MovementState.SLIDING:
		perform_slide_jump()
		return

	if can_ground_jump():
		perform_ground_jump()
		return

	if can_wall_jump():
		perform_wall_jump()
		return


func can_ground_jump() -> bool:
	return coyote_timer > 0.0


func can_wall_jump() -> bool:
	return (
		not is_on_floor()
		and wall_normal != Vector3.ZERO
		and dash_recovery_timer <= 0.0
		and movement_state != MovementState.DASHING
	)


func perform_ground_jump() -> void:
	velocity.y = jump_velocity
	jump_buffer_timer = 0.0
	coyote_timer = 0.0


func perform_slide_jump() -> void:
	velocity.y = jump_velocity
	velocity.x = slide_direction.x * (move_speed + slide_jump_boost)
	velocity.z = slide_direction.z * (move_speed + slide_jump_boost)

	jump_buffer_timer = 0.0
	coyote_timer = 0.0

	cancel_slide()


func perform_wall_jump() -> void:
	var jump_direction := wall_normal.normalized()

	velocity.x = jump_direction.x * wall_jump_horizontal_speed
	velocity.z = jump_direction.z * wall_jump_horizontal_speed
	velocity.y = wall_jump_vertical_speed

	wall_jump_lock_timer = wall_jump_lock_time

	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	wall_normal = Vector3.ZERO


func handle_dash_input() -> void:
	if not Input.is_action_just_pressed("dash"):
		return

	if dash_cooldown_timer > 0.0:
		return

	var desired_direction := get_input_move_direction()

	if desired_direction == Vector3.ZERO:
		desired_direction = -transform.basis.z.normalized()

	dash_direction = desired_direction
	dash_start_position = global_position
	dash_target_position = global_position + dash_direction * dash_distance
	dash_elapsed = 0.0

	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_recovery_timer = 0.0
	wall_normal = Vector3.ZERO

	if movement_state == MovementState.SLIDING:
		cancel_slide()

	set_movement_state(MovementState.DASHING)


func handle_slide_input() -> void:
	if slide_buffer_timer <= 0.0:
		return

	if not is_on_floor():
		return

	if movement_state == MovementState.DASHING:
		return

	var desired_direction := get_input_move_direction()

	if desired_direction == Vector3.ZERO:
		desired_direction = -transform.basis.z.normalized()

	slide_direction = desired_direction
	slide_timer = slide_duration
	slide_buffer_timer = 0.0
	set_slide_collider_active(true)

	set_movement_state(MovementState.SLIDING)


func cancel_slide() -> void:
	slide_timer = 0.0

	if can_stand():
		set_slide_collider_active(false)
	else:
		slide_timer = 0.05


func can_stand() -> bool:
	stand_check.force_raycast_update()
	return not stand_check.is_colliding()


func get_input_move_direction() -> Vector3:
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	return (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()


func stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func update_movement_state() -> void:
	if dash_timer > 0.0:
		set_movement_state(MovementState.DASHING)
		return
	elif movement_state == MovementState.DASHING:
		dash_recovery_timer = max(dash_recovery_timer, dash_wall_jump_lock_time)

	if movement_state == MovementState.SLIDING and not is_on_floor():
		cancel_slide()
		set_slide_collider_active(false)

	if slide_timer > 0.0 and is_on_floor():
		set_movement_state(MovementState.SLIDING)
		set_slide_collider_active(true)
		return

	if movement_state == MovementState.SLIDING and not can_stand():
		set_movement_state(MovementState.SLIDING)
		set_slide_collider_active(true)
		return

	set_slide_collider_active(false)

	if is_wall_sliding():
		set_movement_state(MovementState.WALL_SLIDING)
		return

	if not is_on_floor():
		set_movement_state(MovementState.AIRBORNE)
		return

	set_movement_state(MovementState.GROUNDED)


func set_slide_collider_active(is_active: bool) -> void:
	standing_collision.disabled = is_active
	sliding_collision.disabled = not is_active


func set_movement_state(new_state: MovementState) -> void:
	if movement_state == new_state:
		return

	var old_state := movement_state
	movement_state = new_state

	movement_state_changed.emit(old_state, movement_state)


func set_control_mode(new_mode: ControlMode) -> void:
	if control_mode == new_mode:
		return

	var old_mode := control_mode
	control_mode = new_mode

	control_mode_changed.emit(old_mode, control_mode)
	refresh_debug_display()


func can_move() -> bool:
	return control_mode == ControlMode.ON_FOOT


func can_look() -> bool:
	return (
		control_mode == ControlMode.ON_FOOT
		or control_mode == ControlMode.IN_VEHICLE
		or control_mode == ControlMode.LOCKED
	)


func can_shoot() -> bool:
	return control_mode == ControlMode.ON_FOOT


func can_interact() -> bool:
	return control_mode == ControlMode.ON_FOOT


func handle_interact_input() -> void:
	if not can_interact():
		return

	if ray_target == null:
		return

	if ray_target.is_in_group("interactable") and ray_target.has_method("interact"):
		print("Interaction Started...")
		ray_target.interact()


func handle_interaction_ray() -> void:
	var new_target: Node = null

	if interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		new_target = find_interactable(collider)

	if new_target != previous_ray_target:
		previous_ray_target = new_target
		ray_target = new_target
		ray_target_changed.emit(ray_target)


func find_interactable(node: Node) -> Node:
	var current := node

	while current != null:
		if current.is_in_group("interactable"):
			return current

		current = current.get_parent()

	return null


func refresh_debug_display() -> void:
	if debug_label == null:
		return

	debug_label.text = (
		"Control Mode: " + str(control_mode)
		+ "\nMovement State: " + str(movement_state)
		+ "\nWall Normal: " + str(wall_normal)
		+ "\nWall Jump Lock: " + str(wall_jump_lock_timer)
		+ "\nDash Recovery: " + str(dash_recovery_timer)
		+ "\nCan Move: " + str(can_move())
		+ "\nCan Look: " + str(can_look())
		+ "\nCan Shoot: " + str(can_shoot())
		+ "\nCan Interact: " + str(can_interact())
	)

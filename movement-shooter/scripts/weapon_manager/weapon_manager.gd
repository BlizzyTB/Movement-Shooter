extends Node
class_name WeaponManager

@export_category("Punch")

## Damage dealt by the player's punch.
@export var punch_damage: float = 25.0

## Force value sent through DamageInfo when punching.
@export var punch_force: float = 8.0

## Time in seconds before the player can punch again.
@export var punch_cooldown: float = 0.35


@export_category("Firearm")

## Damage dealt by the currently equipped firearm.
@export var firearm_damage: float = 20.0

## Time in seconds between firearm shots.
@export var firearm_cooldown: float = 0.18

## Maximum distance the firearm ray can hit.
@export var firearm_range: float = 100.0

## Force value sent through DamageInfo for bullet impact reactions.
@export var firearm_force: float = 4.0


@export_category("Node References")

## RayCast3D used for close-range punch hit detection.
@export var punch_ray: RayCast3D

## RayCast3D used for firearm hit detection.
@export var fire_ray: RayCast3D

## Viewmodel root responsible for hand animations and equipped visuals.
@export var viewmodel_root: Node


## Currently equipped weapon data resource.
var equipped_weapon_data: WeaponItemData = null

## Internal timer that blocks punch spam.
var punch_cooldown_timer: float = 0.0

## Internal timer that blocks firearm spam.
var firearm_cooldown_timer: float = 0.0


func _process(delta: float) -> void:
	if punch_cooldown_timer > 0.0:
		punch_cooldown_timer -= delta

	if firearm_cooldown_timer > 0.0:
		firearm_cooldown_timer -= delta


## Attempts to punch if the punch cooldown is ready.
func try_punch() -> void:
	print("")
	print("========== TRY PUNCH ==========")

	if punch_cooldown_timer > 0.0:
		print("Punch blocked. Cooldown remaining: ", punch_cooldown_timer)
		print("========== END TRY PUNCH ==========")
		return

	punch_cooldown_timer = punch_cooldown
	print("Punch accepted.")

	if viewmodel_root == null:
		push_warning("WeaponManager viewmodel_root is null.")
	else:
		print("Viewmodel root found: ", viewmodel_root.name)

		if viewmodel_root.has_method("play_punch"):
			print("Calling viewmodel_root.play_punch()")
			viewmodel_root.play_punch()
		else:
			push_warning("Viewmodel root has no play_punch().")

	perform_punch_hit()

	print("========== END TRY PUNCH ==========")
	print("")


## Attempts to fire the equipped firearm if cooldown is ready.
func try_fire() -> void:
	print("")
	print("========== TRY FIRE ==========")

	if firearm_cooldown_timer > 0.0:
		print("Fire blocked. Cooldown remaining: ", firearm_cooldown_timer)
		print("========== END TRY FIRE ==========")
		return

	firearm_cooldown_timer = firearm_cooldown
	print("Fire accepted.")

	if equipped_weapon_data == null:
		print("Warning: firing with no equipped_weapon_data. Using default firearm stats.")

	if viewmodel_root != null and viewmodel_root.has_method("play_fire"):
		print("Calling viewmodel_root.play_fire()")
		viewmodel_root.play_fire()

	perform_firearm_hit()

	print("========== END TRY FIRE ==========")
	print("")


## Equips weapon data onto the player and spawns its viewmodel into the right hand.
##
## data:
## WeaponItemData resource containing weapon stats and viewmodel scene.
func equip_weapon_from_data(data: WeaponItemData) -> void:
	print("")
	print("========== EQUIP WEAPON FROM DATA ==========")

	if data == null:
		print("Cannot equip weapon: data is null.")
		print("========== END EQUIP WEAPON FROM DATA ==========")
		return

	equipped_weapon_data = data

	firearm_damage = data.damage
	firearm_cooldown = data.fire_rate
	firearm_range = data.attack_range
	firearm_force = data.force

	print("Equipped weapon data: ", data.item_name)
	print("Damage: ", firearm_damage)
	print("Fire cooldown: ", firearm_cooldown)
	print("Range: ", firearm_range)
	print("Force: ", firearm_force)
	print("Viewmodel root assigned: ", viewmodel_root != null)
	print("Viewmodel scene assigned: ", data.viewmodel_scene != null)

	if data.viewmodel_scene != null:
		print("Viewmodel scene path: ", data.viewmodel_scene.resource_path)
	else:
		print("Viewmodel scene path: NULL")

	if viewmodel_root != null:
		print("Viewmodel root name: ", viewmodel_root.name)
		print("Viewmodel root has equip_right_hand_scene: ", viewmodel_root.has_method("equip_right_hand_scene"))

	if viewmodel_root != null and viewmodel_root.has_method("equip_right_hand_scene"):
		print("Calling equip_right_hand_scene...")
		viewmodel_root.equip_right_hand_scene(data.viewmodel_scene)
	else:
		push_warning("Cannot equip viewmodel. Missing viewmodel_root or equip_right_hand_scene().")

	print("========== END EQUIP WEAPON FROM DATA ==========")
	print("")


## Performs firearm raycast hit detection and applies bullet damage.
func perform_firearm_hit() -> void:
	print("---------- PERFORM FIREARM HIT ----------")

	if fire_ray == null:
		push_warning("WeaponManager fire_ray is null.")
		return

	fire_ray.target_position = Vector3(0.0, 0.0, -firearm_range)
	fire_ray.force_raycast_update()

	if not fire_ray.is_colliding():
		print("Shot missed.")
		return

	var collider := fire_ray.get_collider()

	if collider == null:
		print("Shot collided, but collider is null.")
		return

	print("Shot hit: ", collider.name)

	var health := find_health_component(collider)

	if health == null:
		print("Shot hit object with no HealthComponent.")
		return

	var hit_normal := fire_ray.get_collision_normal()

	var info := DamageInfo.new()
	info.amount = firearm_damage
	info.source = owner
	info.hit_position = fire_ray.get_collision_point()
	info.hit_normal = hit_normal
	info.direction = -hit_normal
	info.damage_type = "bullet"
	info.force = firearm_force

	print("Target health BEFORE shot: ", health.current_health, " / ", health.max_health)

	health.take_damage(info)

	print("Target health AFTER shot: ", health.current_health, " / ", health.max_health)


## Performs punch raycast hit detection and applies punch damage.
func perform_punch_hit() -> void:
	print("---------- PERFORM PUNCH HIT ----------")

	if punch_ray == null:
		push_warning("WeaponManager punch_ray is null.")
		return

	punch_ray.force_raycast_update()

	if not punch_ray.is_colliding():
		print("Punch ray hit nothing.")
		return

	var collider := punch_ray.get_collider()

	if collider == null:
		print("Punch ray collided, but collider is null.")
		return

	print("Punch hit: ", collider.name)

	var health := find_health_component(collider)

	if health == null:
		print("Punch hit object with no HealthComponent.")
		return

	var hit_normal := punch_ray.get_collision_normal()

	var info := DamageInfo.new()
	info.amount = punch_damage
	info.source = owner
	info.hit_position = punch_ray.get_collision_point()
	info.hit_normal = hit_normal
	info.direction = -hit_normal
	info.damage_type = "punch"
	info.force = punch_force

	print("Target health BEFORE punch: ", health.current_health, " / ", health.max_health)

	health.take_damage(info)

	print("Target health AFTER punch: ", health.current_health, " / ", health.max_health)


## Searches upward from a hit node until it finds a HealthComponent.
##
## start_node:
## Node hit by the punch/fire ray.
##
## Returns:
## HealthComponent found on the node or parents, or null.
func find_health_component(start_node: Node) -> HealthComponent:
	if start_node == null:
		return null

	if start_node is HealthComponent:
		return start_node

	var direct_health := start_node.get_node_or_null("HealthComponent")
	if direct_health != null and direct_health is HealthComponent:
		return direct_health

	var current := start_node.get_parent()

	while current != null:
		if current is HealthComponent:
			return current

		var health := current.get_node_or_null("HealthComponent")
		if health != null and health is HealthComponent:
			return health

		current = current.get_parent()

	return null
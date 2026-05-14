extends Node
class_name WeaponManager

## Handles equipped weapon data, firearm cooldowns, and firearm ray damage.
## Punch and old FPS arms logic have been removed.
## First-person visuals are handled by PlayerHandsRoot.

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
## RayCast3D used for firearm hit detection.
@export var fire_ray: RayCast3D

## First-person hand/equipment visual root.
@export var player_hands_root: PlayerHandsRoot


## Currently equipped weapon data resource.
var equipped_weapon_data: WeaponItemData = null

## Internal timer that blocks firearm spam.
var firearm_cooldown_timer: float = 0.0


func _process(delta: float) -> void:
	if firearm_cooldown_timer > 0.0:
		firearm_cooldown_timer -= delta


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

	if player_hands_root != null:
		player_hands_root.play_fire()
	else:
		push_warning("WeaponManager player_hands_root is null.")

	perform_firearm_hit()

	print("========== END TRY FIRE ==========")
	print("")


## Equips weapon data onto the player and spawns its viewmodel into PlayerHandsRoot/WeaponSlot.
##
## data:
## WeaponItemData resource containing weapon stats, viewmodel scene, and procedural weapon settings.
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
	print("PlayerHandsRoot assigned: ", player_hands_root != null)
	print("Viewmodel scene assigned: ", data.viewmodel_scene != null)

	if data.viewmodel_scene != null:
		print("Viewmodel scene path: ", data.viewmodel_scene.resource_path)
	else:
		print("Viewmodel scene path: NULL")

	if player_hands_root != null:
		player_hands_root.equip_weapon_scene(data.viewmodel_scene, data)
	else:
		push_warning("Cannot equip viewmodel. Missing player_hands_root.")

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


## Searches upward from a hit node until it finds a HealthComponent.
##
## start_node:
## Node hit by the fire ray.
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

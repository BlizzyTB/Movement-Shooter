extends Node
class_name WeaponManager

@export var punch_damage: float = 10.0
@export var punch_cooldown: float = 0.38
@export var viewmodel: PlayerViewmodel

@onready var punch_ray: RayCast3D = $"../PunchRay"

var can_punch: bool = true


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("punch"):
		try_punch()


func try_punch() -> void:
	if not can_punch:
		return

	can_punch = false

	if viewmodel != null:
		viewmodel.play_punch()

	perform_punch_hit()

	await get_tree().create_timer(punch_cooldown).timeout
	can_punch = true


func perform_punch_hit() -> void:
	if punch_ray == null:
		return

	punch_ray.force_raycast_update()

	if not punch_ray.is_colliding():
		return

	var collider: Object = punch_ray.get_collider()

	if collider == null:
		return

	if not collider is Node:
		return

	var target: Node = find_damageable(collider as Node)

	if target == null:
		return

	var health_component: Node = find_health_component(target)

	if health_component == null:
		return

	var damage_source: Node = get_damage_source()
	health_component.take_damage(punch_damage, damage_source)
	print("Damage sent. Source: ", damage_source.name)


func get_damage_source() -> Node:
	var current: Node = self

	while current != null:
		if current is CharacterBody3D:
			return current

		current = current.get_parent()

	return self


func find_damageable(start_node: Node) -> Node:
	var current: Node = start_node

	while current != null:
		if current.is_in_group("damageable"):
			return current

		current = current.get_parent()

	return null


func find_health_component(start_node: Node) -> Node:
	var current: Node = start_node

	while current != null:
		var health_component: Node = current.get_node_or_null("HealthComponent")

		if health_component != null:
			return health_component

		current = current.get_parent()

	return null
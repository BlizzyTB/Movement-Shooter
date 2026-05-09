extends Area3D
class_name DamageArea

@export var damage_amount: float = 25.0
@export var damage_type: String = "hazard"


func _ready() -> void:

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:

	var health := find_health_component(body)

	if health == null:
		return


	var info := DamageInfo.new()
	info.amount = damage_amount
	info.source = self
	info.hit_position = body.global_position
	info.hit_normal = Vector3.UP
	info.direction = Vector3.UP
	info.damage_type = damage_type

	health.take_damage(info)


func find_health_component(start_node: Node) -> HealthComponent:
	if start_node == null:
		return null

	var direct_health := start_node.get_node_or_null("HealthComponent")
	if direct_health != null:
		return direct_health as HealthComponent

	var current := start_node.get_parent()

	while current != null:

		var health := current.get_node_or_null("HealthComponent")
		if health != null:
			return health as HealthComponent

		current = current.get_parent()

	return null
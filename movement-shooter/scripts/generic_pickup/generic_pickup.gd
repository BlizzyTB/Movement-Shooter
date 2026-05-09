extends RigidBody3D
class_name GenericPickup

signal picked_up(pickup: GenericPickup, item_data: ItemData, picker: Node)

## Data resource that tells this generic pickup what item it represents.
@export var item_data: ItemData

## Visible mesh used to display the pickup in the world.
@export var mesh_instance: MeshInstance3D

## Main physical collision shape for the RigidBody3D pickup.
@export var body_collision_shape: CollisionShape3D

## Area used to detect/assist pickup range.
@export var pickup_area: Area3D

## Collision shape inside PickupArea.
@export var pickup_area_shape: CollisionShape3D

## Extra size added around the physical collision.
@export var body_collision_padding: float = 0.05

## Extra size added around the pickup area.
@export var pickup_area_padding: float = 0.45

## Minimum collision size so tiny meshes still have usable collision.
@export var minimum_collision_size: Vector3 = Vector3(0.25, 0.25, 0.25)

## If true, the script automatically sizes collision shapes from the mesh bounds.
@export var auto_fit_collision_to_mesh: bool = true

## Stores the most recent body that entered the pickup area.
var player_in_range: Node = null


func _ready() -> void:
	print("")
	print("========== GENERIC PICKUP READY ==========")
	print("Pickup node name: ", name)

	add_to_group("observable")
	add_to_group("pickup")

	_apply_item_data()

	if auto_fit_collision_to_mesh:
		_fit_collision_to_mesh()

	if pickup_area != null:
		if not pickup_area.body_entered.is_connected(_on_pickup_area_body_entered):
			pickup_area.body_entered.connect(_on_pickup_area_body_entered)

		if not pickup_area.body_exited.is_connected(_on_pickup_area_body_exited):
			pickup_area.body_exited.connect(_on_pickup_area_body_exited)

	print("========== END PICKUP READY ==========")
	print("")


func get_observable_name() -> String:
	if item_data == null:
		return "Unknown Item"

	return item_data.item_name


func get_interaction_prompt() -> String:
	if item_data == null:
		return "Pick up"

	return item_data.pickup_prompt + " " + item_data.item_name


func can_interact(interactor: Node) -> bool:
	if item_data == null:
		return false

	return item_data.can_pick_up


func interact(interactor: Node) -> void:
	print("")
	print("========== PICKUP INTERACT ==========")
	print("Pickup: ", name)
	print("Interactor: ", interactor.name if interactor != null else "null")

	if not can_interact(interactor):
		print("Interaction failed.")
		return

	picked_up.emit(self, item_data, interactor)

	if interactor != null and interactor.has_method("receive_item"):
		interactor.receive_item(item_data)
	else:
		push_warning("Interactor has no receive_item method.")

	queue_free()


func _apply_item_data() -> void:
	if item_data == null:
		print("GenericPickup has no item_data assigned.")
		return

	if mesh_instance == null:
		print("GenericPickup has no mesh_instance assigned.")
		return

	if item_data.world_mesh != null:
		mesh_instance.mesh = item_data.world_mesh
		print("Applied world mesh.")

	if item_data.world_material != null:
		mesh_instance.material_override = item_data.world_material
		print("Applied world material.")


func _fit_collision_to_mesh() -> void:
	if mesh_instance == null:
		push_warning("Cannot fit pickup collision: mesh_instance is null.")
		return

	if mesh_instance.mesh == null:
		push_warning("Cannot fit pickup collision: mesh_instance has no mesh.")
		return

	var aabb: AABB = mesh_instance.get_aabb()
	var mesh_size: Vector3 = aabb.size * mesh_instance.scale.abs()

	mesh_size.x = max(mesh_size.x, minimum_collision_size.x)
	mesh_size.y = max(mesh_size.y, minimum_collision_size.y)
	mesh_size.z = max(mesh_size.z, minimum_collision_size.z)

	var mesh_center: Vector3 = aabb.position + aabb.size * 0.5
	mesh_center *= mesh_instance.scale

	print("Mesh AABB size: ", mesh_size)
	print("Mesh AABB center: ", mesh_center)

	_fit_body_collision(mesh_size, mesh_center)
	_fit_pickup_area(mesh_size, mesh_center)


func _fit_body_collision(mesh_size: Vector3, mesh_center: Vector3) -> void:
	if body_collision_shape == null:
		push_warning("Cannot fit body collision: body_collision_shape is null.")
		return

	var box_shape := BoxShape3D.new()
	box_shape.size = mesh_size + Vector3.ONE * body_collision_padding

	body_collision_shape.shape = box_shape
	body_collision_shape.position = mesh_center

	print("Body collision fitted.")
	print("Body collision size: ", box_shape.size)
	print("Body collision position: ", body_collision_shape.position)


func _fit_pickup_area(mesh_size: Vector3, mesh_center: Vector3) -> void:
	if pickup_area_shape == null:
		push_warning("Cannot fit pickup area: pickup_area_shape is null.")
		return

	var sphere_shape := SphereShape3D.new()

	var largest_axis: float = max(mesh_size.x, max(mesh_size.y, mesh_size.z))
	sphere_shape.radius = largest_axis * 0.5 + pickup_area_padding

	pickup_area_shape.shape = sphere_shape
	pickup_area_shape.position = mesh_center

	print("Pickup area fitted.")
	print("Pickup area radius: ", sphere_shape.radius)
	print("Pickup area position: ", pickup_area_shape.position)


func _on_pickup_area_body_entered(body: Node3D) -> void:
	print("PICKUP AREA BODY ENTERED: ", body.name)
	player_in_range = body


func _on_pickup_area_body_exited(body: Node3D) -> void:
	print("PICKUP AREA BODY EXITED: ", body.name)

	if player_in_range == body:
		player_in_range = null
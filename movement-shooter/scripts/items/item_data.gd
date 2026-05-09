extends Resource
class_name ItemData

@export var item_name: String = "Unnamed Item"
@export_multiline var description: String = ""

@export var item_id: StringName = &"generic_item"
@export var item_type: StringName = &"generic"

@export var pickup_prompt: String = "Pick up"

@export var world_mesh: Mesh
@export var world_material: Material

@export var can_pick_up: bool = true
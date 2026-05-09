extends ItemData
class_name WeaponItemData

@export_category("Weapon Stats")
@export var damage: float = 20.0
@export var fire_rate: float = 0.18
@export var attack_range: float = 100.0
@export var force: float = 4.0

@export_category("Weapon Scenes")
@export var weapon_scene: PackedScene
@export var viewmodel_scene: PackedScene
extends ItemData
class_name WeaponItemData

@export_category("Weapon Stats")
@export var damage: float = 20.0
@export var fire_rate: float = 0.18
@export var attack_range: float = 100.0
@export var force: float = 4.0

@export_category("Viewmodel")
@export var viewmodel_scene: PackedScene

@export_category("Recoil")
@export var recoil_position_kick: Vector3 = Vector3(0.0, 0.03, 0.12)
@export var recoil_rotation_kick_degrees: Vector3 = Vector3(-6.0, 1.0, 0.0)
@export var recoil_snappiness: float = 28.0
@export var recoil_return_speed: float = 16.0

@export_category("Sway")
@export var sway_position_amount: Vector2 = Vector2(0.025, 0.018)
@export var sway_rotation_amount_degrees: Vector2 = Vector2(2.0, 2.0)
@export var sway_follow_speed: float = 14.0
@export var sway_return_speed: float = 10.0

@export_category("Bob")
@export var bob_position_amount: Vector3 = Vector3(0.035, 0.035, 0.0)
@export var bob_rotation_amount_degrees: Vector3 = Vector3(1.0, 1.5, 1.0)
@export var bob_walk_speed: float = 8.0
@export var bob_sprint_speed: float = 12.0

@export_category("Tactical Sprint Pose")
@export var tactical_sprint_position: Vector3 = Vector3(0.08, -0.08, -0.04)
@export var tactical_sprint_rotation_degrees: Vector3 = Vector3(35.0, 18.0, 10.0)
@export var tactical_sprint_enter_speed: float = 6.0
@export var tactical_sprint_exit_speed: float = 8.0
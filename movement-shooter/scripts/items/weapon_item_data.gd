extends ItemData
class_name WeaponItemData

## Data resource for weapons.
## Holds weapon combat stats, first-person viewmodel scene, and procedural weapon feel settings.

@export_category("Weapon Stats")
## Damage dealt by this weapon per shot.
@export var damage: float = 20.0

## Time in seconds between shots.
## Lower value means faster fire rate.
@export var fire_rate: float = 0.18

## Maximum firearm raycast distance.
@export var attack_range: float = 100.0

## Impact force sent through DamageInfo.
@export var force: float = 4.0


@export_category("Viewmodel")
## First-person weapon visual scene spawned into PlayerHandsRoot/WeaponSlot.
@export var viewmodel_scene: PackedScene


@export_category("Procedural Recoil")
## Position kick added when firing.
## Negative Z usually kicks the weapon back toward the camera.
@export var recoil_position_kick: Vector3 = Vector3(0.0, 0.03, 0.12)

## Rotation kick in degrees added when firing.
## Negative X usually tilts the muzzle upward.
@export var recoil_rotation_kick_degrees: Vector3 = Vector3(-6.0, 1.0, 0.0)

## How quickly the weapon moves into recoil.
@export var recoil_snappiness: float = 28.0

## How quickly the weapon returns from recoil.
@export var recoil_return_speed: float = 16.0


@export_category("Procedural Sway")
## Maximum positional sway caused by mouse movement.
@export var sway_position_amount: Vector2 = Vector2(0.025, 0.018)

## Maximum rotational sway caused by mouse movement, in degrees.
@export var sway_rotation_amount_degrees: Vector2 = Vector2(2.0, 2.0)

## How quickly sway follows mouse movement.
@export var sway_follow_speed: float = 14.0

## How quickly sway returns to center.
@export var sway_return_speed: float = 10.0


@export_category("Procedural Bob")
## How much the weapon moves while the player is moving.
@export var bob_position_amount: Vector3 = Vector3(0.035, 0.035, 0.0)

## How much the weapon rotates while the player is moving, in degrees.
@export var bob_rotation_amount_degrees: Vector3 = Vector3(1.0, 1.5, 1.0)

## Bob speed while walking.
@export var bob_walk_speed: float = 8.0

## Bob speed while sprinting.
@export var bob_sprint_speed: float = 12.0
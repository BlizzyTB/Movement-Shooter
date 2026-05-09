extends Resource
class_name DamageInfo

var amount: float = 0.0
var source: Node = null
var hit_position: Vector3 = Vector3.ZERO
var hit_normal: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO
var damage_type: String = "generic"
var force: float = 0.0
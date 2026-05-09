extends Node
class_name HealthComponent

signal damaged(info: DamageInfo)
signal died(info: DamageInfo)
signal healed(amount: float)

@export var max_health: float = 100.0

var current_health: float
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	print("HealthComponent ready on: ", owner.name)
	print("Starting health: ", current_health, " / ", max_health)


func take_damage(info: DamageInfo) -> void:
	print("HealthComponent.take_damage called on: ", owner.name)

	if is_dead:
		print("Damage ignored. Target is already dead.")
		return

	if info == null:
		print("Damage ignored. DamageInfo is null.")
		return

	print("Incoming damage amount: ", info.amount)
	print("Damage type: ", info.damage_type)
	print("Damage source: ", info.source)
	print("Health before damage: ", current_health, " / ", max_health)

	current_health -= info.amount
	current_health = max(current_health, 0.0)

	print("Health after damage: ", current_health, " / ", max_health)

	damaged.emit(info)

	if current_health <= 0.0:
		print("Health reached zero. Dying.")
		die(info)


func die(info: DamageInfo) -> void:
	if is_dead:
		print("die() ignored. Already dead.")
		return

	is_dead = true
	print("DIED: ", owner.name)
	died.emit(info)


func heal(amount: float) -> void:
	print("Healing: ", owner.name, " by ", amount)

	if is_dead:
		print("Heal ignored. Target is dead.")
		return

	current_health += amount
	current_health = min(current_health, max_health)

	print("Health after heal: ", current_health, " / ", max_health)

	healed.emit(amount)


func reset_health() -> void:
	print("Resetting health on: ", owner.name)

	current_health = max_health
	is_dead = false

	print("Health reset to: ", current_health, " / ", max_health)
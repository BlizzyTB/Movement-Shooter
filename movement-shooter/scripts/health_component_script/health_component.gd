extends Node
class_name HealthComponent

signal health_changed(current_health, max_health)
signal damaged(amount, source)
signal died(source)

@export_category("Health")

## Maximum health this object can have.
## Current health starts at this value unless changed manually.
@export var max_health: float = 100.0

## If true, this object cannot take damage.
## Useful for invincible states, testing, or scripted moments.
@export var invincible: bool = false

var current_health: float
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float, source: Node = null) -> void:
	if is_dead:
		return

	if invincible:
		return

	if amount <= 0.0:
		return

	current_health = max(current_health - amount, 0.0)

	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	print("HealthComponent: Took damage of ", amount, " from ", source)

	if current_health <= 0.0:
		die(source)


func heal(amount: float) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func die(source: Node = null) -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(source)
extends Node3D
class_name ViewmodelRoot

## AnimationPlayer that controls first-person hand/viewmodel animations.
@export var animation_player: AnimationPlayer

## Node where right-hand equipment appears.
## Usually used for firearms.
@export var right_hand_slot: Node3D

## Node where left-hand equipment appears.
## Later used for held items, tools, artifacts, etc.
@export var left_hand_slot: Node3D

## Idle/rest animation for the hands.
@export var idle_animation: StringName = "Relax"

## Left-hand punch animation.
@export var punch_animation: StringName = "Jab_L"

## Weapon fire animation.
## Can be "Relax" temporarily until you have a real fire animation.
@export var fire_animation: StringName = "Relax"

## Current object spawned in the right hand.
var right_hand_instance: Node3D = null

## Current object spawned in the left hand.
var left_hand_instance: Node3D = null


func _ready() -> void:
	print("")
	print("========== VIEWMODEL ROOT READY ==========")

	print("ViewmodelRoot: ", name)
	print("AnimationPlayer assigned: ", animation_player != null)
	print("RightHandSlot assigned: ", right_hand_slot != null)
	print("LeftHandSlot assigned: ", left_hand_slot != null)

	if right_hand_slot != null:
		print("RightHandSlot path: ", right_hand_slot.get_path())

	if left_hand_slot != null:
		print("LeftHandSlot path: ", left_hand_slot.get_path())

	if animation_player == null:
		push_warning("ViewmodelRoot has no animation_player assigned.")
		print("========== END VIEWMODEL ROOT READY ==========")
		return

	print("Available animations:")
	for anim_name in animation_player.get_animation_list():
		print("- ", anim_name)

	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

	play_idle()

	print("========== END VIEWMODEL ROOT READY ==========")
	print("")


## Plays the resting/idle hand animation.
func play_idle() -> void:
	if animation_player == null:
		return

	if animation_player.has_animation(idle_animation):
		animation_player.play(idle_animation)
	else:
		push_warning("Idle animation not found: " + str(idle_animation))


## Plays the left-hand punch animation.
func play_punch() -> void:
	print("ViewmodelRoot.play_punch called.")

	if animation_player == null:
		push_warning("Cannot punch: animation_player is null.")
		return

	if not animation_player.has_animation(punch_animation):
		push_warning("Punch animation not found: " + str(punch_animation))
		return

	animation_player.stop()
	animation_player.play(punch_animation)


## Plays weapon fire animation if one exists.
func play_fire() -> void:
	print("ViewmodelRoot.play_fire called.")

	if animation_player == null:
		push_warning("Cannot fire anim: animation_player is null.")
		return

	if not animation_player.has_animation(fire_animation):
		push_warning("Fire animation not found: " + str(fire_animation))
		return

	animation_player.play(fire_animation)


## Equips a scene into the right-hand slot.
##
## scene:
## PackedScene to instantiate and place under right_hand_slot.
func equip_right_hand_scene(scene: PackedScene) -> void:
	print("")
	print("========== EQUIP RIGHT HAND SCENE ==========")
	print("Scene passed in: ", scene)
	print("Right hand slot: ", right_hand_slot)

	if right_hand_slot == null:
		push_warning("Cannot equip right hand scene: right_hand_slot is null.")
		print("========== END EQUIP RIGHT HAND SCENE ==========")
		return

	clear_right_hand()

	if scene == null:
		push_warning("Cannot equip right hand scene: scene is null.")
		print("========== END EQUIP RIGHT HAND SCENE ==========")
		return

	print("Scene resource path: ", scene.resource_path)

	var instance := scene.instantiate()

	print("Instantiated scene: ", instance)
	print("Instance name: ", instance.name)
	print("Instance class: ", instance.get_class())

	if not instance is Node3D:
		push_warning("Right hand scene root must be Node3D.")
		instance.queue_free()
		print("========== END EQUIP RIGHT HAND SCENE ==========")
		return

	right_hand_instance = instance as Node3D
	right_hand_slot.add_child(right_hand_instance)

	right_hand_instance.position = Vector3.ZERO
	right_hand_instance.rotation = Vector3.ZERO
	right_hand_instance.scale = Vector3.ONE
	right_hand_instance.visible = true

	print("Right hand instance parent: ", right_hand_instance.get_parent().name)
	print("Right hand instance position: ", right_hand_instance.position)
	print("Right hand instance rotation: ", right_hand_instance.rotation)
	print("Right hand instance scale: ", right_hand_instance.scale)
	print("Right hand instance visible: ", right_hand_instance.visible)

	print("RightHandSlot child count: ", right_hand_slot.get_child_count())
	for child in right_hand_slot.get_children():
		print("- Slot child: ", child.name, " | Class: ", child.get_class())

	print("========== END EQUIP RIGHT HAND SCENE ==========")
	print("")


## Equips a scene into the left-hand slot.
##
## scene:
## PackedScene to instantiate and place under left_hand_slot.
func equip_left_hand_scene(scene: PackedScene) -> void:
	print("")
	print("========== EQUIP LEFT HAND SCENE ==========")

	if left_hand_slot == null:
		push_warning("Cannot equip left hand scene: left_hand_slot is null.")
		print("========== END EQUIP LEFT HAND SCENE ==========")
		return

	clear_left_hand()

	if scene == null:
		push_warning("Cannot equip left hand scene: scene is null.")
		print("========== END EQUIP LEFT HAND SCENE ==========")
		return

	var instance := scene.instantiate()

	if not instance is Node3D:
		push_warning("Left hand scene root must be Node3D.")
		instance.queue_free()
		print("========== END EQUIP LEFT HAND SCENE ==========")
		return

	left_hand_instance = instance as Node3D
	left_hand_slot.add_child(left_hand_instance)

	left_hand_instance.position = Vector3.ZERO
	left_hand_instance.rotation = Vector3.ZERO
	left_hand_instance.scale = Vector3.ONE
	left_hand_instance.visible = true

	print("Equipped left hand scene: ", scene.resource_path)
	print("========== END EQUIP LEFT HAND SCENE ==========")
	print("")


## Removes the current right-hand item.
func clear_right_hand() -> void:
	if right_hand_instance != null:
		print("Clearing right hand instance: ", right_hand_instance.name)
		right_hand_instance.queue_free()
		right_hand_instance = null


## Removes the current left-hand item.
func clear_left_hand() -> void:
	if left_hand_instance != null:
		print("Clearing left hand instance: ", left_hand_instance.name)
		left_hand_instance.queue_free()
		left_hand_instance = null


## Called when an animation finishes.
##
## anim_name:
## Name of the animation that just finished.
func _on_animation_finished(anim_name: StringName) -> void:
	print("Animation finished: ", anim_name)

	if anim_name == punch_animation:
		play_idle()
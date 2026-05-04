extends Node



func _unhandled_input(event):
    if event.is_action_pressed("dev_quit"):
        get_tree().quit()
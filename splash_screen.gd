extends Control

func _on_timer_timeout():
	# Change this path if your Main Menu is inside a specific folder!
	# Pro-tip: Right-click your Main Menu scene in the FileSystem and click "Copy Path"
	get_tree().change_scene_to_file("res://main_menu.tscn")
func _ready():
	# --- NEW: RETURN TO NORMAL MOUSE ---
	Input.set_custom_mouse_cursor(null) 

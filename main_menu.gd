extends Control

func _ready():
	# --- NEW: RETURN TO NORMAL MOUSE ---
	Input.set_custom_mouse_cursor(null) 

# --- PLAY BUTTON ---
func _on_play_pressed():
	# This loads your Level Select / Play Page. 
	get_tree().change_scene_to_file("res://play_page.tscn")

# --- SETTINGS BUTTON (UPDATED) ---
func _on_settings_pressed():
	# 1. Hide the VBoxContainer (Main Menu buttons)
	$VBoxContainer.hide()
	
	# 2. Load the standalone Settings scene
	var settings_menu = preload("res://settings.tscn").instantiate()
	
	# 3. Add it to the screen on top
	add_child(settings_menu)
	
	# 4. Wait until the Settings menu is deleted (when they click Return)
	await settings_menu.tree_exited
	
	# 5. Show the Main Menu buttons again!
	$VBoxContainer.show()

# --- CREDITS BUTTON ---
func _on_credits_pressed():
	# This loads your Credits screen.
	get_tree().change_scene_to_file("res://credits.tscn")

# --- EXIT BUTTON ---
func _on_exit_pressed():
	print("Closing Geneticide Awakening...")
	# This completely closes the game window!
	get_tree().quit()

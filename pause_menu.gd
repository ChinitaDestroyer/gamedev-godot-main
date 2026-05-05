extends CanvasLayer

func _ready():
	# Keep the menu hidden when the game is playing normally
	hide()

func _input(event):
	# Listen for the ESC key
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	# Flip the pause state (If playing, pause it. If paused, play it.)
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		show() # Dim the screen and show buttons
	else:
		hide() # Hide menu and go back to the game

# --- BUTTON SIGNALS ---

func _on_resume_pressed():
	toggle_pause() # Unpause the game

func _on_quit_pressed():
	# CRITICAL: You MUST unpause the game before leaving!
	# If you don't, your Main Menu will be completely frozen when it loads.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

# This matches the signal Godot created for your Settings_btn!
func _on_settings_btn_pressed():
	# 1. Hide the Resume/Quit buttons so they don't overlap
	$MainPauseUI.hide()
	
	# 2. Load your standalone Settings scene
	var settings_menu = preload("res://settings.tscn").instantiate()
	
	# 3. Add it to the screen on top of the Pause Menu
	add_child(settings_menu)
	
	# 4. Wait until the Settings menu is deleted (when the player clicks Return)
	await settings_menu.tree_exited
	
	# 5. Show the Resume/Quit buttons again!
	$MainPauseUI.show()


func _on_resume_btn_pressed():
	toggle_pause() # Unpause the game

func _on_quit_to_menu_btn_pressed():
	# CRITICAL: Unpause before leaving!
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://main_menu.tscn")

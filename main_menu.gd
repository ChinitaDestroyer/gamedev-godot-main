extends Control

# --- AUDIO NODES ---
@onready var hover_sfx: AudioStreamPlayer = $HoverSound
@onready var click_sfx: AudioStreamPlayer = $ClickSound

func _ready():
	Input.set_custom_mouse_cursor(null)
	
	# Check if a save file exists on the hard drive
	if FileAccess.file_exists(Global.SAVE_PATH):
		$VBoxContainer/Continue.show() # Show the Continue button
	else:
		$VBoxContainer/Continue.hide() # Hide it if they are a brand new player

	# --- NEW: Connect hover sounds via code ---
	# (Ensure these button names exactly match the nodes inside your VBoxContainer!)
	if has_node("VBoxContainer/Continue"): $VBoxContainer/Continue.mouse_entered.connect(_on_button_hover)
	if has_node("VBoxContainer/Play"): $VBoxContainer/Play.mouse_entered.connect(_on_button_hover)
	if has_node("VBoxContainer/Settings"): $VBoxContainer/Settings.mouse_entered.connect(_on_button_hover)
	if has_node("VBoxContainer/Credits"): $VBoxContainer/Credits.mouse_entered.connect(_on_button_hover)
	if has_node("VBoxContainer/Exit"): $VBoxContainer/Exit.mouse_entered.connect(_on_button_hover)


# --- NEW: HOVER FUNCTION ---
func _on_button_hover() -> void:
	if hover_sfx: hover_sfx.play()


# --- CONTINUE BUTTON ---
func _on_continue_pressed():
	if click_sfx: click_sfx.play()
	await get_tree().create_timer(0.15).timeout # Wait for sound to play
	
	if Global.load_game():
		# Check if we actually saved a scene path
		if Global.current_scene_path != "":
			get_tree().change_scene_to_file(Global.current_scene_path)
		else:
			# Fallback just in case something goes wrong
			get_tree().change_scene_to_file("res://main_level.tscn")
			
	var crosshair_img = load("res://asset ni oswel/crosshair.png")
	Input.set_custom_mouse_cursor(crosshair_img, Input.CURSOR_ARROW, Vector2(30, 32))


# --- PLAY BUTTON ---
func _on_play_pressed():
	if click_sfx: click_sfx.play()
	await get_tree().create_timer(0.15).timeout # Wait for sound to play
	
	# Wipe old global data just in case they are restarting
	Global.has_checkpoint = false
	GlobalInventory.current_weapons.clear()
	GlobalInventory.items.fill(null)
	
	# Optional: Delete the old save file
	if FileAccess.file_exists(Global.SAVE_PATH):
		DirAccess.remove_absolute(Global.SAVE_PATH)
		
	get_tree().change_scene_to_file("res://intro.tscn")
	
	var crosshair_img = load("res://asset ni oswel/crosshair.png")
	Input.set_custom_mouse_cursor(crosshair_img, Input.CURSOR_ARROW, Vector2(30, 32))


# --- SETTINGS BUTTON ---
func _on_settings_pressed():
	if click_sfx: click_sfx.play()
	# (No 'await' timer needed here since we don't change scenes!)
	
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
	if click_sfx: click_sfx.play()
	await get_tree().create_timer(0.15).timeout # Wait for sound to play
	
	# This loads your Credits screen.
	get_tree().change_scene_to_file("res://credits.tscn")


# --- EXIT BUTTON ---
func _on_exit_pressed():
	if click_sfx: click_sfx.play()
	await get_tree().create_timer(0.15).timeout # Wait for sound to play
	
	print("Closing Geneticide Awakening...")
	# This completely closes the game window!
	get_tree().quit()

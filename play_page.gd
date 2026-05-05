extends Control

# 1. The list of your 5 levels
var levels = ["VIP Suite", "Diagnostics", "Quarantine", "Cafeteria", "Courtyard"]
var current_index = 0

# 2. Tell Godot to look for your specific UI nodes
@onready var title_label = $TitleLabel
@onready var play_button = $PlayButton
@onready var level_picture = $LevelPicture 

# 3. Your TWO arrays for custom images!
@export var unlocked_images: Array[Texture2D]
@export var locked_images: Array[Texture2D]

func _ready():
	# --- NEW: RETURN TO NORMAL MOUSE ---
	Input.set_custom_mouse_cursor(null) 
	
	update_ui()
# --- THE SYSTEM THAT CHANGES THE SCREEN ---
func update_ui():
	var level_name = levels[current_index]
	
	# Update the Title Text
	title_label.text = level_name.to_upper()

	# Check the GameManager to see if this level is locked
	if GameManager.unlocked_levels[level_name] == true:
		# --- UNLOCKED ---
		# Show the normal picture and show the Play button
		if unlocked_images.size() > 0 and current_index < unlocked_images.size():
			level_picture.texture = unlocked_images[current_index]
		if play_button: play_button.show()
	else:
		# --- LOCKED ---
		# Show the locked picture and hide the Play button
		if locked_images.size() > 0 and current_index < locked_images.size():
			level_picture.texture = locked_images[current_index]
		if play_button: play_button.hide()

# --- NAVIGATION ARROWS ---
func _on_right_arrow_pressed():
	current_index += 1
	if current_index >= levels.size():
		current_index = 0 
	update_ui()

func _on_left_arrow_pressed():
	current_index -= 1
	if current_index < 0:
		current_index = levels.size() - 1 
	update_ui()

# --- PLAY BUTTON ---
func _on_play_button_pressed():
	var scene_path = ""
	
	# Match the current index to the exact folder paths!
	match current_index:
		0: scene_path = "res://scene/first_round_map.tscn"  # VIP Suite
		1: scene_path = "res://scene/second_round_map.tscn" # Diagnostics
		2: scene_path = "res://scene/third_round_map.tscn"  # Quarantine
		3: scene_path = "res://scene/fourth_round_map.tscn" # Cafeteria
		4: scene_path = "res://scene/last_round_map.tscn"   # Courtyard
		
	# If a path was found, change the scene!
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)

# --- RETURN BUTTON ---
func _on_return_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")

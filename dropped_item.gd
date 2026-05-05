extends Area2D

@export var item_texture: Texture2D # This lets you drag ANY icon into the Inspector!
var player_nearby = false
var player_node = null

# --- NEW: The memory for the item's file path! ---
var stored_texture_path: String = ""

func _ready():
	# If we manually dragged this item into the map editor, set it up immediately
	if item_texture != null and stored_texture_path == "":
		stored_texture_path = item_texture.resource_path # Save the path!
		apply_texture_and_scale(item_texture)

func _on_body_entered(body):
	if body.name == "Player_Boy":
		player_nearby = true
		player_node = body

func _on_body_exited(body):
	if body.name == "Player_Boy":
		player_nearby = false
		player_node = null

func _input(event):
	# If the player is standing inside the circle and presses E
	if player_nearby and Input.is_action_just_pressed("interact"):
		
		var fresh_texture = item_texture
		
		# 🔥 FIX: If we have a saved path, load a fresh perfect copy of the picture!
		if stored_texture_path != "":
			fresh_texture = load(stored_texture_path)
			
		# Send the picture to the player's UI inventory
		var item_was_picked_up = player_node.get_node("PlayerUI").add_item(fresh_texture)
		
		# If the inventory wasn't full, delete the item from the ground!
		if item_was_picked_up:
			get_viewport().set_input_as_handled() # Fixes the "Vacuum" bug!
			queue_free()

# --- UPDATED: The UI script calls this right after you press 'G' to drop! ---
func setup_item(new_texture, texture_path):
	stored_texture_path = texture_path
	item_texture = new_texture
	apply_texture_and_scale(new_texture)

# --- NEW: Moved your scaling math here so it resizes perfectly when dropped! ---
func apply_texture_and_scale(tex: Texture2D):
	$Sprite2D.texture = tex
	
	if tex != null:
		var target_size = 25.0 # We want every item to be exactly 25 pixels big on the floor
		
		# Get the actual pixel size of the image you dropped in
		var img_width = tex.get_width()
		var img_height = tex.get_height()
		
		# Find whichever side is longer
		var longest_side = max(img_width, img_height)
		
		# Mathematically calculate the perfect scale!
		var perfect_scale = target_size / longest_side
		
		# Apply that scale to the sprite
		$Sprite2D.scale = Vector2(perfect_scale, perfect_scale)

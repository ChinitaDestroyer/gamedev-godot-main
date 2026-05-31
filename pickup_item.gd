extends Area2D

@export var item_name: String = "Health Potion"
@export_enum("consumable", "weapon", "key", "flashlight", "armor") var item_type: String = "consumable"
@export var item_value: int = 20

@onready var prompt: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D # NEW: Grab the sprite so we can change it!

var can_interact: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	var my_id = name + "_" + str(global_position)
	
	if my_id in Global.completed_events:
		queue_free() 
		return 
		
	prompt.hide()
	prompt.text = "[E] " + item_name
	update_visuals()

# --- NEW: VISUAL UPDATE FUNCTION ---

func update_visuals() -> void:
	# A match statement is a super clean way to check multiple if/else conditions
	match item_type:
		"flashlight":
			# REPLACE THIS PATH with your actual potion image path!
			sprite.texture = preload("res://asset ni oswel/flashlight.png") 
		"weapon":
			if item_name == "Knife":
				sprite.texture = preload("res://PNG_items/items_0015_knife.png")
			elif item_name == "Pistol": # (Or whatever you name your gun in the Inspector!)
				sprite.texture = preload("res://PNG_items/items_0014_gun.png")
		"key":
			# REPLACE THIS PATH with your actual key image path!
			sprite.texture = preload("res://asset ni oswel/key.png")
		"armor":
			sprite.texture = preload("res://PNG_items/items_0010_armor.png")

# --- SIGNALS ---

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = true
		player_ref = body # Save a reference to the player!
		prompt.show()
		
		# Shortened this text since the inventory part happens after pickup now
		if not Global.seen_item_tutorial:
			Global.seen_item_tutorial = true 
			if body.has_method("show_tutorial_message"):
				body.show_tutorial_message("TUTORIAL: Press [E] to pick up the item.", 4.0)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		player_ref = null # Clear the memory when they leave
		prompt.hide()

# --- INPUT HANDLING ---

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		var my_id = name + "_" + str(global_position)
		
		if item_type == "armor":
			GlobalInventory.equipped_armor = item_name
			GlobalInventory.armor_equipped.emit(item_name)
			Global.completed_events.append(my_id)
			queue_free()
			return 
		
		var my_item_data = {
			"name": item_name,
			"type": item_type,
			"value": item_value,
			"icon": sprite.texture.resource_path 
		}
		
		# If the item successfully goes into the backpack...
		if GlobalInventory.add_item(my_item_data):
			
			# --- NEW: Check if the player exists and can show messages ---
			if player_ref != null and player_ref.has_method("show_tutorial_message"):
				
				# 1. Did we pick up a flashlight?
				if item_type == "flashlight" and not Global.seen_flashlight_tutorial:
					Global.seen_flashlight_tutorial = true
					player_ref.show_tutorial_message("TUTORIAL: Press [F] to turn your flashlight on and off.", 5.0)
					
				# 2. Otherwise, show the normal inventory tutorial!
				elif not Global.seen_inventory_tutorial:
					Global.seen_inventory_tutorial = true
					player_ref.show_tutorial_message("TUTORIAL: Press [I] to open your inventory and equip items.", 5.0)
			
			Global.completed_events.append(my_id)
			queue_free()

extends Area2D

@export var item_name: String = "Health Potion"
@export_enum("consumable", "weapon", "key", "flashlight", "armor") var item_type: String = "consumable"
@export var item_value: int = 20

@onready var prompt: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D # NEW: Grab the sprite so we can change it!

var can_interact: bool = false

func _ready() -> void:
	var my_id = name + "_" + str(global_position)
	
	if my_id in Global.completed_events:
		queue_free() 
		return 
		
	prompt.hide()
	prompt.text = "[E] Pick Up " + item_name
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
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		prompt.hide()

# --- INPUT HANDLING ---

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		var my_id = name + "_" + str(global_position)
		
		# --- THE FIX: Intercept the armor before it goes into the backpack! ---
		if item_type == "armor":
			# Tell the Global manager we are wearing it
			GlobalInventory.equipped_armor = item_name
			# Emit the signal so the Player script fills up the Armor Bar
			GlobalInventory.armor_equipped.emit(item_name)
			
			# Save it so it doesn't respawn, then delete it from the floor
			Global.completed_events.append(my_id)
			queue_free()
			
			return # STOP here so it doesn't continue down into the backpack code!
		# ----------------------------------------------------------------------
		
		# For all normal items (guns, knives, flashlights, etc.)
		var my_item_data = {
			"name": item_name,
			"type": item_type,
			"value": item_value,
			"icon": sprite.texture.resource_path 
		}
		
		if GlobalInventory.add_item(my_item_data):
			Global.completed_events.append(my_id)
			queue_free()

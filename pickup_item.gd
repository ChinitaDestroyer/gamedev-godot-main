extends Area2D

@export var item_name: String = "Health Potion"
@export_enum("consumable", "weapon", "key") var item_type: String = "consumable"
@export var item_value: int = 20

@onready var prompt: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D # NEW: Grab the sprite so we can change it!

var can_interact: bool = false

func _ready() -> void:
	prompt.hide()
	prompt.text = "[E] Pick Up " + item_name
	
	# NEW: Change the image as soon as the item is created
	update_visuals()

# --- NEW: VISUAL UPDATE FUNCTION ---

func update_visuals() -> void:
	# A match statement is a super clean way to check multiple if/else conditions
	match item_type:
		#"consumable":
			# REPLACE THIS PATH with your actual potion image path!
			#sprite.texture = preload("res://potion.png") 
		"weapon":
			# REPLACE THIS PATH with your actual weapon image path!
			sprite.texture = preload("res://PNG_items/items_0015_knife.png")
		#"key":
			# REPLACE THIS PATH with your actual key image path!
			#sprite.texture = preload("res://key.png")

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
		
		var my_item_data = {
			"name": item_name,
			"type": item_type,
			"value": item_value,
			"icon": sprite.texture # <--- NEW: Grab the image directly from the sprite!
		}
		
		if GlobalInventory.add_item(my_item_data):
			queue_free()

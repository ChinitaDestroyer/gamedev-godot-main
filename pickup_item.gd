extends Area2D

@export var item_name: String = "Health Potion"
@export_enum("consumable", "weapon", "key", "flashlight", "armor", "ammo") var item_type: String = "consumable"
@export var item_value: int = 20

@onready var prompt: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D 

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

func update_visuals() -> void:
	match item_type:
		"flashlight":
			sprite.texture = preload("res://asset ni oswel/flashlight.png") 
		"weapon":
			if item_name == "Knife":
				sprite.texture = preload("res://PNG_items/items_0015_knife.png")
			elif item_name == "Pistol": 
				sprite.texture = preload("res://PNG_items/items_0014_gun.png")
		"key":
			sprite.texture = preload("res://asset ni oswel/key.png")
		"armor":
			sprite.texture = preload("res://PNG_items/items_0010_armor.png")
		"ammo":
			sprite.texture = preload("res://PNG_items/items_0003_magazine_gun.png")
		"consumable":
			sprite.texture = preload("res://PNG_items/items_0005_health.png")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = true
		player_ref = body
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		player_ref = null
		prompt.hide()

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		var my_id = name + "_" + str(global_position)
		
		if item_type == "ammo":
			if player_ref != null and player_ref.has_method("add_ammo"):
				player_ref.add_ammo(item_value)
				player_ref.show_tutorial_message("Picked up " + str(item_value) + " bullets!", 3.0)
			
			Global.completed_events.append(my_id)
			queue_free()
			return
		
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
		
		if GlobalInventory.add_item(my_item_data):
			if player_ref != null and player_ref.has_method("show_tutorial_message"):
				if item_type == "flashlight" and not Global.seen_flashlight_tutorial:
					Global.seen_flashlight_tutorial = true
					player_ref.show_tutorial_message("TUTORIAL: Press [F] to turn your flashlight on and off.", 5.0)
				elif not Global.seen_inventory_tutorial:
					Global.seen_inventory_tutorial = true
					player_ref.show_tutorial_message("TUTORIAL: Press [I] to open your inventory and equip items.", 5.0)
			
			Global.completed_events.append(my_id)
			queue_free()

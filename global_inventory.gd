extends Node

signal inventory_updated
signal weapon_equipped(weapon_name: String)
signal armor_equipped(armor_name: String)

var current_weapons: Array[String] = [] 
var checkpoint_weapons: Array[String] = []
var checkpoint_items: Array = []
var has_seen_combat_tutorial: bool = false

const MAX_SLOTS = 6
var items: Array = [] 

var equipped_armor: String = ""
var checkpoint_equipped_armor: String = ""
var equipped_weapon: String = ""
var checkpoint_equipped_weapon: String = ""

func _ready() -> void:
	items.resize(MAX_SLOTS)
	items.fill(null) 

func add_item(item_data: Dictionary) -> bool:
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = item_data
			inventory_updated.emit()
			
			if item_data["type"] == "weapon" and not has_seen_combat_tutorial:
				has_seen_combat_tutorial = true
			
			return true
			
	print("Inventory is full!")
	return false

func use_item(slot_index: int) -> void:
	var item = items[slot_index]
	if item == null: return
	
	if item["type"] == "consumable":
		print("You drank the ", item["name"], "! Healed for ", item["value"])
		items[slot_index] = null 
		
	elif item["type"] == "weapon":
		if equipped_weapon == item["name"]:
			print("Unequipped the ", equipped_weapon)
			equipped_weapon = "" 
			weapon_equipped.emit("") 
		else:
			equipped_weapon = item["name"]
			print("Equipped the ", equipped_weapon)
			weapon_equipped.emit(equipped_weapon)
	
	elif item["type"] == "armor":
		if equipped_armor == item["name"]:
			print("Taking off the ", equipped_armor)
			equipped_armor = "" 
			armor_equipped.emit("") 
		else:
			equipped_armor = item["name"]
			print("Putting on the ", equipped_armor)
			armor_equipped.emit(equipped_armor)
		
	elif item["type"] == "key":
		print("Try walking up to a locked door instead!")
		
	inventory_updated.emit()
	
func swap_items(index1: int, index2: int) -> void:
	var temp = items[index1]
	items[index1] = items[index2]
	items[index2] = temp
	inventory_updated.emit()

func drop_item(index: int) -> Dictionary:
	var item_to_drop = items[index]
	
	if item_to_drop != null and item_to_drop["type"] == "weapon":
		if equipped_weapon == item_to_drop["name"]:
			equipped_weapon = ""
			weapon_equipped.emit("") 
			print("Unequipped weapon because it was dropped!")
			
	elif item_to_drop != null and item_to_drop["type"] == "armor":
		if equipped_armor == item_to_drop["name"]:
			equipped_armor = ""
			armor_equipped.emit("") 
			print("Took off armor because it was dropped!")
	
	items[index] = null
	inventory_updated.emit()
	return item_to_drop

func consume_key() -> bool:
	for i in range(MAX_SLOTS):
		var item = items[i]
		if item != null and item["type"] == "key":
			items[i] = null
			inventory_updated.emit() 
			return true 
	return false
	
func save_to_checkpoint() -> void:
	checkpoint_weapons = current_weapons.duplicate()
	checkpoint_items = items.duplicate(true)
	checkpoint_equipped_weapon = equipped_weapon
	print("Inventory saved to checkpoint! Safe items: ", checkpoint_weapons)

func restore_from_checkpoint() -> void:
	current_weapons = checkpoint_weapons.duplicate()
	
	if checkpoint_items.is_empty():
		items.fill(null)
	else:
		items = checkpoint_items.duplicate(true)
		
	print("Inventory restored from checkpoint! Current items: ", current_weapons)
	
	if current_weapons.size() > 0:
		weapon_equipped.emit(current_weapons[0])
	else:
		weapon_equipped.emit("") 
		
	equipped_weapon = checkpoint_equipped_weapon
	weapon_equipped.emit(equipped_weapon)
	inventory_updated.emit()

func has_item(target_name: String) -> bool:
	for i in range(MAX_SLOTS):
		var item = items[i]
		if item != null and item["name"] == target_name:
			return true
	return false

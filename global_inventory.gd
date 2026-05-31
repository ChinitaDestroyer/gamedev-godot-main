extends Node

signal inventory_updated
signal weapon_equipped(weapon_name: String)


# 1. Your current pockets (what you lose if you die)
var current_weapons: Array[String] = [] 

# 2. Your permanent vault (what is safe at the checkpoint)
var checkpoint_weapons: Array[String] = []
var checkpoint_items: Array = []
var has_seen_combat_tutorial: bool = false

const MAX_SLOTS = 6
var items: Array = [] # This will now hold Dictionaries instead of Strings!

var equipped_armor: String = ""
var checkpoint_equipped_armor: String = ""
var equipped_weapon: String = ""
var checkpoint_equipped_weapon: String = ""

signal armor_equipped(armor_name: String)

func _ready() -> void:
	# Fill the inventory with 'null' (which means completely empty)
	items.resize(MAX_SLOTS)
	items.fill(null) 

# Notice we now accept a Dictionary instead of a String
func add_item(item_data: Dictionary) -> bool:
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = item_data
			
			inventory_updated.emit()
			
			# --- NEW: Trigger combat tutorial when picking up the first weapon! ---
			if item_data["type"] == "weapon" and not has_seen_combat_tutorial:
				has_seen_combat_tutorial = true
			
			return true
			
	print("Inventory is full!")
	return false

# --- NEW: THE MAGIC USE FUNCTION ---
func use_item(slot_index: int) -> void:
	var item = items[slot_index]
	if item == null: return
	
	if item["type"] == "consumable":
		print("You drank the ", item["name"], "! Healed for ", item["value"])
		items[slot_index] = null 
		
	elif item["type"] == "weapon":
		
		# --- NEW: Check if we are already holding this exact weapon! ---
		if equipped_weapon == item["name"]:
			print("Unequipped the ", equipped_weapon)
			equipped_weapon = "" # Clear the weapon memory
			weapon_equipped.emit("") # Tell the player to play unarmed animations!
			
		# If we aren't holding it, equip it normally
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
	# Standard programming trick: Store the first item in a temporary variable, 
	# overwrite the first, then overwrite the second with the temporary one!
	var temp = items[index1]
	items[index1] = items[index2]
	items[index2] = temp
	
	# Tell the UI to redraw
	inventory_updated.emit()

func drop_item(index: int) -> Dictionary:
	var item_to_drop = items[index]
	
	if item_to_drop != null and item_to_drop["type"] == "weapon":
		if equipped_weapon == item_to_drop["name"]:
			equipped_weapon = ""
			weapon_equipped.emit("") 
			print("Unequipped weapon because it was dropped!")
			
	# --- NEW: Unequip armor if it gets dropped! ---
	elif item_to_drop != null and item_to_drop["type"] == "armor":
		if equipped_armor == item_to_drop["name"]:
			equipped_armor = ""
			armor_equipped.emit("") # Tell the player to return to normal clothes
			print("Took off armor because it was dropped!")
	# ----------------------------------------------
	
	items[index] = null
	inventory_updated.emit()
	return item_to_drop

func consume_key() -> bool:
	# Check every slot in the backpack
	for i in range(MAX_SLOTS):
		var item = items[i]
		
		# If there is an item, and its type is "key"
		if item != null and item["type"] == "key":
			
			# We found a key! Remove it from the backpack so it gets used up
			items[i] = null
			inventory_updated.emit() # Update the UI so the key disappears
			
			return true # Tell the door: "Yes, we had a key!"
			
	# If the loop finishes and finds nothing, tell the door: "No key found."
	return false
	
func save_to_checkpoint() -> void:
	# .duplicate() is CRUCIAL! It makes a hard copy of the list.
	# If you don't use it, Godot links them together and both will delete!
	checkpoint_weapons = current_weapons.duplicate()
	# --- NEW: Save the actual inventory slots! ---
	checkpoint_items = items.duplicate(true)
	
	checkpoint_equipped_weapon = equipped_weapon
	print("Inventory saved to checkpoint! Safe items: ", checkpoint_weapons)

func restore_from_checkpoint() -> void:
	# Restore the old string array
	current_weapons = checkpoint_weapons.duplicate()
	
	# --- NEW: Restore the inventory slots! ---
	# If we die before ever hitting a checkpoint, checkpoint_items will be empty. 
	# If it's empty, we just fill the slots with nulls again.
	if checkpoint_items.is_empty():
		items.fill(null)
	else:
		items = checkpoint_items.duplicate(true)
		
	print("Inventory restored from checkpoint! Current items: ", current_weapons)
	
	# Optional: Automatically equip the first weapon in the list if you have one
	if current_weapons.size() > 0:
		weapon_equipped.emit(current_weapons[0])
	else:
		weapon_equipped.emit("") # Unequip if we have no weapons
		
	equipped_weapon = checkpoint_equipped_weapon
	weapon_equipped.emit(equipped_weapon)
		
	# --- NEW: Tell the UI backpack to redraw itself! ---
	inventory_updated.emit()

func has_item(target_name: String) -> bool:
	for i in range(MAX_SLOTS):
		var item = items[i]
		# If the slot isn't empty, and the name matches exactly, return true!
		if item != null and item["name"] == target_name:
			return true
	return false

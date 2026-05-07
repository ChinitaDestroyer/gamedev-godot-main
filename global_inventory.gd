extends Node

signal inventory_updated

const MAX_SLOTS = 6
var items: Array = [] # This will now hold Dictionaries instead of Strings!

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
			return true
			
	print("Inventory is full!")
	return false

# --- NEW: THE MAGIC USE FUNCTION ---
func use_item(slot_index: int) -> void:
	var item = items[slot_index]
	
	# If the slot is empty, do nothing
	if item == null: return
	
	# Check what TYPE of item it is
	if item["type"] == "consumable":
		print("You drank the ", item["name"], "! Healed for ", item["value"])
		items[slot_index] = null # Delete it from the inventory!
		
	elif item["type"] == "weapon":
		print("You equipped the ", item["name"], "! Damage is now ", item["value"])
		# Note: It stays in your inventory because it's not consumed!
		
	elif item["type"] == "key":
		print("You can't use this here. Try walking up to a locked door!")
		
	# Tell the UI to redraw itself
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
	# Grabs the item, clears the slot, and returns the item data 
	# so we can spawn it on the floor later!
	var item_to_drop = items[index]
	items[index] = null
	inventory_updated.emit()
	return item_to_drop

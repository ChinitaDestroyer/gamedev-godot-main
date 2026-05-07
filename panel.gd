extends Panel

# 1. Load the physical item scene so we can spawn it.
# IMPORTANT: Make sure this path exactly matches your file name in the FileSystem!
var pickup_scene = preload("res://pickup_item.tscn") 

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("origin_slot")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Remove it from the inventory data
	var dropped_item = GlobalInventory.drop_item(data["origin_slot"])
	
	if dropped_item != null:
		spawn_item_in_world(dropped_item)

# --- NEW: SPAWN THE ITEM ---

func spawn_item_in_world(item_data: Dictionary) -> void:
	var new_item = pickup_scene.instantiate()
	
	new_item.item_name = item_data["name"]
	new_item.item_type = item_data["type"]
	new_item.item_value = item_data["value"]

	
	var main_level = get_tree().current_scene
	var player = main_level.get_node_or_null("Player") 
	new_item.global_position = player.global_position + Vector2(60, 60)
	
	if player != null:
		# 1. CRITICAL FIX: Add it to the level FIRST! 
		# (No call_deferred needed since this is a UI action, not a physics collision)
		main_level.add_child(new_item)
		
		# 2. NOW set its global_position. 
		# Because it is officially in the level, Godot's math will be 100% perfect.
		new_item.global_position = player.global_position + Vector2(0, 40)
		
		print("SUCCESS: Dropped ", item_data["name"], " perfectly at ", new_item.global_position)
	else:
		print("CRITICAL ERROR: Could not find the Player node!")

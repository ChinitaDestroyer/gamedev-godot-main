extends ColorRect

# We will let the main UI script assign this number so the slot knows who it is
var slot_index: int = -1

# 1. WHAT HAPPENS WHEN YOU CLICK AND DRAG?
func _get_drag_data(_at_position: Vector2) -> Variant:
	var item = GlobalInventory.items[slot_index]
	
	if item == null:
		return null
		
	# --- NEW: Create a floating image preview ---
	var preview_texture = TextureRect.new()
	preview_texture.texture = item["icon"]
	
	# Shrink the floating image so it isn't massive while dragging
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(40, 40) 
	
	var preview = Control.new()
	preview.add_child(preview_texture)
	
	# Center the image directly under your mouse cursor
	preview_texture.position = Vector2(-20, -20) 
	
	set_drag_preview(preview)
	
	return {"origin_slot": slot_index}


# 2. CAN I DROP THIS HERE?
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Check if the data we are holding is a Dictionary and came from an inventory slot
	return typeof(data) == TYPE_DICTIONARY and data.has("origin_slot")


# 3. WHAT HAPPENS WHEN I LET GO OF THE MOUSE?
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Tell the global inventory to swap the item we dragged with whatever is in this slot
	GlobalInventory.swap_items(data["origin_slot"], slot_index)

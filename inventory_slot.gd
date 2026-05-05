extends Panel

func _get_drag_data(at_position):
	# 1. Grab the image inside this slot
	var item_texture = $TextureRect.texture
	
	# 2. If the box is empty, do nothing!
	if item_texture == null:
		return null
		
	# 3. Create a little ghost image to follow your mouse
	var preview = TextureRect.new()
	preview.texture = item_texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(64, 64)
	set_drag_preview(preview)
	
	# 4. Tell Godot we are dragging this slot
	return self


func _can_drop_data(at_position, data):
	# Only allow dropping if the thing we are dragging is another Panel (slot)
	return data is Panel


func _drop_data(at_position, data):
	# 1. Save the image that is currently in THIS box
	var temp_texture = $TextureRect.texture
	
	# 2. Take the image from the OLD box and put it in THIS box
	$TextureRect.texture = data.get_node("TextureRect").texture
	
	# 3. Put our saved image back into the OLD box
	data.get_node("TextureRect").texture = temp_texture

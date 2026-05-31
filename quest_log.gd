extends VBoxContainer

func _process(delta: float) -> void:
	var keys = Global.active_quests.keys()
	
	# --- NEW MODULAR CHECK FOR ALL QUESTS ---
	for quest_name in keys:
		if Global.active_quests[quest_name] == false:
			var req_items = Global.quest_requirements.get(quest_name, [])
			
			# If this quest actually requires items...
			if req_items.size() > 0:
				var all_items_found = true
				
				# Check the backpack for every single item on the list
				for item in req_items:
					if not GlobalInventory.has_item(item):
						all_items_found = false
						break # Stop checking if we are missing one
						
				# If we found everything, cross it off!
				if all_items_found:
					Global.complete_quest(quest_name)
	# ----------------------------------------

	if Global.active_quests.is_empty():
		hide()
		return
		
	var child_index = 1 # Skip the Title Label
	var incomplete_count = 0 
	
	for i in range(keys.size()):
		var quest_name = keys[i]
		var is_completed = Global.active_quests[quest_name]
		
		if is_completed == true:
			continue 
			
		incomplete_count += 1
		
		var label: Label
		if child_index < get_child_count():
			label = get_child(child_index)
			label.show()
		else:
			label = Label.new()
			add_child(label)
			
		label.text = "[ ] " + quest_name
		label.modulate = Color(1, 1, 1)
			
		child_index += 1
		
	for i in range(child_index, get_child_count()):
		get_child(i).hide()

	if incomplete_count == 0:
		hide()
	else:
		show()

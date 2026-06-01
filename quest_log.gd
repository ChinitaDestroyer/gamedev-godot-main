extends VBoxContainer

func _process(delta: float) -> void:
	var keys = Global.active_quests.keys()
	
	# 1. Check for completed quests
	for quest_name in keys:
		if Global.active_quests[quest_name] == false:
			var req_items = Global.quest_requirements.get(quest_name, [])
			
			if req_items.size() > 0:
				var all_items_found = true
				var valid_items_checked = 0 
				
				for raw_item in req_items:
					# Safeguard: Ignore Nil or bad data to prevent crashes
					if typeof(raw_item) != TYPE_STRING:
						continue
						
					# Automatically erase hidden spaces from the Inspector!
					var item = raw_item.strip_edges()
					if item == "":
						continue
						
					valid_items_checked += 1
						
					if not GlobalInventory.has_item(item):
						all_items_found = false
						break 
						
				# Only complete if we actually found valid items
				if all_items_found and valid_items_checked > 0:
					Global.complete_quest(quest_name)

	if Global.active_quests.is_empty():
		hide()
		return
		
	# 2. Build the UI
	var child_index = 1 
	var incomplete_count = 0 
	var current_display_title = "" 
	
	for i in range(keys.size()):
		var quest_name = keys[i]
		var is_completed = Global.active_quests[quest_name]
		
		if is_completed == true:
			continue 
			
		# Grab the title of the OLDEST unfinished quest!
		if current_display_title == "" and Global.quest_titles.has(quest_name):
			current_display_title = Global.quest_titles[quest_name]
			
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
		
	# Hide unused labels
	for i in range(child_index, get_child_count()):
		get_child(i).hide()

	# 3. Show the correct Title and Window
	if incomplete_count == 0:
		hide()
	else:
		show()
		# Update the Title Label at the very top!
		if get_child_count() > 0:
			if current_display_title != "":
				get_child(0).text = current_display_title
				get_child(0).show()
			else:
				get_child(0).hide()

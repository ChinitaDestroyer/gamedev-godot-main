extends CanvasLayer

@onready var grid: GridContainer = $Panel/GridContainer
@onready var panel: Panel = $Panel

func _ready() -> void:
	panel.hide()
	GlobalInventory.inventory_updated.connect(update_ui)
	
	# NEW: Assign an ID number to every slot when the game starts
	for i in range(GlobalInventory.MAX_SLOTS):
		var slot = grid.get_child(i)
		slot.slot_index = i # Tell the slot its index (0 through 5)
		
	update_ui()

func _input(event: InputEvent) -> void:
	# Open and close the inventory
	if event.is_action_pressed("toggle_inventory"):
		panel.visible = !panel.visible

func update_ui() -> void:
	for i in range(GlobalInventory.MAX_SLOTS):
		var slot = grid.get_child(i)
		# Look for the new TextureRect instead of the Label
		var icon_rect = slot.get_node("ItemIcon") 
		
		var item = GlobalInventory.items[i]
		
		# If there is an item, set the texture to the icon we saved
		if item != null:
			icon_rect.texture = item["icon"]
		# If the slot is empty, set the texture to null (which makes it invisible)
		else:
			icon_rect.texture = null

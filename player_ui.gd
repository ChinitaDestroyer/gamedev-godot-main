extends CanvasLayer

# --- NEW: Load your dropped item scene here! Check the file path! ---
const DROPPED_ITEM_SCENE = preload("res://dropped_item.tscn")

@onready var main_inventory = $MainInventory
@onready var inventory_bar = $InventoryBar
@onready var player = get_parent() # This secretly grabs your Player_Boy script!

# --- VERTICAL FLASHLIGHT & AMMO UI NODES ---
@onready var flashlight_bar = $VBoxContainer/FlashlightBar
@onready var ammo_label = $VBoxContainer/AmmoLabel

var active_slot = 0 # This keeps track of which hotbar slot (0 to 8) is selected

func _ready():
	# Make sure the MAIN grid is hidden when the game first starts!
	main_inventory.hide()

# --- BACKPACK TOGGLE BUTTON ---
func _on_backpack_button_pressed():
	# This flips the visibility! If it's hidden, it shows. If it shows, it hides.
	main_inventory.visible = not main_inventory.visible

# --- KEYBOARD CONTROLS (1-9 Select, G to Drop) ---
func _input(event):
	if event is InputEventKey and event.pressed:
		# Change hotbar slot
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_index = event.keycode - KEY_1
			update_active_slot(slot_index)
			
		# --- NEW: Drop Item when 'G' is pressed ---
		if event.keycode == KEY_G:
			drop_active_item()

# --- NEW: THE DROP FUNCTION ---
func drop_active_item():
	# 1. Look at the box you currently have selected
	var active_panel = inventory_bar.get_child(active_slot)
	var texture_rect = active_panel.get_node("TextureRect")
	var item_texture = texture_rect.texture
	
	# 2. If the box isn't empty, we can drop it!
	if item_texture != null:
		# Spawn the physical item
		var dropped_item = DROPPED_ITEM_SCENE.instantiate()
		
		# Put it in the main map (NOT inside the player, or it will follow you!)
		get_tree().current_scene.add_child(dropped_item)
		
		# Move it to exactly where the player is standing
		dropped_item.global_position = player.global_position
		
		# Give it the correct picture (Requires setup_item inside dropped_item.gd)
		# 🔥 THE FIX: We pass BOTH the picture and its file path!
		if dropped_item.has_method("setup_item"):
			dropped_item.setup_item(item_texture, item_texture.resource_path)
		
		texture_rect.texture = null
		equip_weapon_from_slot()

# --- HIGHLIGHT THE BOX & CHANGE WEAPON ---
func update_active_slot(index):
	active_slot = index
	
	for i in range(inventory_bar.get_child_count()):
		var slot = inventory_bar.get_child(i)
		if i == active_slot:
			slot.modulate = Color(1, 1, 1, 1) # Bright and normal
		else:
			slot.modulate = Color(0.5, 0.5, 0.5, 1) # Dark and dimmed out
			
	equip_weapon_from_slot()

func equip_weapon_from_slot():
	var active_panel = inventory_bar.get_child(active_slot)
	var item_texture = active_panel.get_node("TextureRect").texture
	
	if item_texture == null:
		# FIX: If the box is empty, your hands are empty! No magic knife.
		player.current_weapon = "knife" 
	else:
		var file_name = item_texture.resource_path
		
		if "knife" in file_name:
			player.current_weapon = "knife"
		elif "bat" in file_name:
			player.current_weapon = "bat"
		elif "gun" in file_name and not "machine" in file_name:
			player.current_weapon = "gun"
		elif "riffle" in file_name: 
			player.current_weapon = "riffle"
		elif "fire" in file_name:
			player.current_weapon = "firethrower"
			
	player.update_animation()
	player.update_weapon_alignment()

# --- PICK UP ITEMS FROM THE GROUND ---
func add_item(new_texture) -> bool:
	for i in range(inventory_bar.get_child_count()):
		var slot_picture = inventory_bar.get_child(i).get_node("TextureRect")
		
		if slot_picture.texture == null:
			slot_picture.texture = new_texture
			if i == active_slot:
				equip_weapon_from_slot()
			return true 
			
	var grid = main_inventory.get_node("GridContainer")
	for i in range(grid.get_child_count()):
		var slot_picture = grid.get_child(i).get_node("TextureRect")
		
		if slot_picture.texture == null:
			slot_picture.texture = new_texture
			return true
			
	print("Inventory is completely full!")
	return false

# --- NEW: UI UPDATE FUNCTIONS ---
func update_flashlight_ui(current_battery):
	flashlight_bar.value = current_battery

func update_ammo_ui(current_ammo, max_ammo):
	ammo_label.text = "Ammo: " + str(current_ammo) + " / " + str(max_ammo)

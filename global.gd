extends Node

var respawn_position: Vector2
var has_checkpoint: bool = false
var current_scene_path: String = ""
var player_health: int = 100
var player_ammo: int = 30

var completed_events: Array[String] = []
var checkpoint_events: Array[String] = []

# --- TUTORIAL TRACKERS ---
var seen_movement_tutorial: bool = false # <--- Added this!
var seen_item_tutorial: bool = false
var seen_note_tutorial: bool = false
var seen_door_tutorial: bool = false
var seen_inventory_tutorial: bool = false
var seen_melee_tutorial: bool = false
var seen_gun_tutorial: bool = false
var seen_flashlight_tutorial: bool = false
var seen_sign_tutorial: bool = false

# --- MODULAR QUEST TRACKING ---
var active_quests: Dictionary = {}
var quest_requirements: Dictionary = {}
var quest_titles: Dictionary = {} 

const SAVE_PATH = "user://save_game.save"

func add_quest(quest_name: String, required_items: Array = [], title: String = "") -> void:
	if not active_quests.has(quest_name):
		active_quests[quest_name] = false
		
	# Always update requirements and titles to self-heal old save files!
	quest_requirements[quest_name] = required_items
	quest_titles[quest_name] = title

func complete_quest(quest_name: String) -> void:
	if active_quests.has(quest_name):
		active_quests[quest_name] = true 

func save_game() -> void:
	checkpoint_events = completed_events.duplicate()
	var save_data = {
		"has_checkpoint": has_checkpoint,
		"respawn_x": respawn_position.x,
		"respawn_y": respawn_position.y,
		"player_health": player_health,
		"safe_weapons": GlobalInventory.checkpoint_weapons,
		"safe_items": GlobalInventory.checkpoint_items,
		"safe_equipped_weapon": GlobalInventory.checkpoint_equipped_weapon,
		"safe_equipped_armor": GlobalInventory.checkpoint_equipped_armor,
		"scene_path": current_scene_path,
		"events": checkpoint_events,
		"quests": active_quests,
		"quest_reqs": quest_requirements,
		"quest_titles": quest_titles,
		
		# --- FIXED: Now actually saving tutorials to the file! ---
		"seen_movement": seen_movement_tutorial,
		"seen_item": seen_item_tutorial,
		"seen_note": seen_note_tutorial,
		"seen_door": seen_door_tutorial,
		"seen_inventory": seen_inventory_tutorial,
		"seen_melee": seen_melee_tutorial,
		"seen_gun": seen_gun_tutorial,
		"seen_flashlight": seen_flashlight_tutorial,
		"seen_sign": seen_sign_tutorial,
		"player_ammo": player_ammo,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	print("Game Saved Successfully! Scene: ", current_scene_path)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())
	
	has_checkpoint = save_data["has_checkpoint"]
	respawn_position = Vector2(save_data["respawn_x"], save_data["respawn_y"])
	player_health = save_data.get("player_health", 100)
	player_ammo = save_data.get("player_ammo", 30)
	
	GlobalInventory.checkpoint_weapons.assign(save_data.get("safe_weapons", []))
	GlobalInventory.checkpoint_items = save_data.get("safe_items", [])
	GlobalInventory.current_weapons.assign(GlobalInventory.checkpoint_weapons.duplicate())
	GlobalInventory.items = GlobalInventory.checkpoint_items.duplicate(true)
	
	GlobalInventory.checkpoint_equipped_weapon = save_data.get("safe_equipped_weapon", "")
	GlobalInventory.equipped_weapon = GlobalInventory.checkpoint_equipped_weapon
	GlobalInventory.checkpoint_equipped_armor = save_data.get("safe_equipped_armor", "")
	GlobalInventory.equipped_armor = GlobalInventory.checkpoint_equipped_armor
	current_scene_path = save_data.get("scene_path", "")
	
	active_quests = save_data.get("quests", {}) 
	quest_requirements = save_data.get("quest_reqs", {})
	quest_titles = save_data.get("quest_titles", {})
	
	checkpoint_events.assign(save_data.get("events", []))
	completed_events = checkpoint_events.duplicate()
	
	# --- FIXED: Now loading tutorials from the file! ---
	seen_movement_tutorial = save_data.get("seen_movement", false)
	seen_item_tutorial = save_data.get("seen_item", false)
	seen_note_tutorial = save_data.get("seen_note", false)
	seen_door_tutorial = save_data.get("seen_door", false)
	seen_inventory_tutorial = save_data.get("seen_inventory", false)
	seen_melee_tutorial = save_data.get("seen_melee", false)
	seen_gun_tutorial = save_data.get("seen_gun", false)
	seen_flashlight_tutorial = save_data.get("seen_flashlight", false)
	seen_sign_tutorial = save_data.get("seen_sign", false)
	
	return true
	
func restore_events() -> void:
	completed_events = checkpoint_events.duplicate()

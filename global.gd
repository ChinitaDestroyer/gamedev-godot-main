extends Node

# This will remember where the player should spawn
var respawn_position: Vector2
var has_checkpoint: bool = false
var current_scene_path: String = ""
var player_health: int = 100

var completed_events: Array[String] = []
var checkpoint_events: Array[String] = []

var seen_item_tutorial: bool = false
var seen_note_tutorial: bool = false
var seen_door_tutorial: bool = false
var seen_inventory_tutorial: bool = false
var seen_melee_tutorial: bool = false
var seen_gun_tutorial: bool = false
var seen_flashlight_tutorial: bool = false
var seen_sign_tutorial: bool = false
var has_main_key: bool = false

# --- QUEST TRACKING ---
var active_quests: Dictionary = {}
var quest_requirements: Dictionary = {} # NEW: Remembers what items are needed!


const SAVE_PATH = "user://save_game.save"

# Now accepts a second argument: the list of required items!
func add_quest(quest_name: String, required_items: Array = []) -> void:
	if not active_quests.has(quest_name):
		active_quests[quest_name] = false
		quest_requirements[quest_name] = required_items

func complete_quest(quest_name: String) -> void:
	if active_quests.has(quest_name):
		active_quests[quest_name] = true

func save_game() -> void:
	# Bundle all our important variables into a Dictionary
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
		"has_main_key": has_main_key
	}
	
	# Open a file and write the data as a JSON string
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
	
	GlobalInventory.checkpoint_weapons.assign(save_data.get("safe_weapons", []))
	GlobalInventory.checkpoint_items = save_data.get("safe_items", [])
	GlobalInventory.current_weapons.assign(GlobalInventory.checkpoint_weapons.duplicate())
	GlobalInventory.items = GlobalInventory.checkpoint_items.duplicate(true)
	
	GlobalInventory.checkpoint_equipped_weapon = save_data.get("safe_equipped_weapon", "")
	GlobalInventory.equipped_weapon = GlobalInventory.checkpoint_equipped_weapon
	GlobalInventory.checkpoint_equipped_armor = save_data.get("safe_equipped_armor", "")
	GlobalInventory.equipped_armor = GlobalInventory.checkpoint_equipped_armor
	current_scene_path = save_data.get("scene_path", "")
	
	# --- THE FIX: We tell the game to load the key variable! ---
	has_main_key = save_data.get("has_main_key", false)
	
	checkpoint_events.assign(save_data.get("events", []))
	completed_events = checkpoint_events.duplicate()
	active_quests = save_data.get("quests", {})
	
	return true
	
func restore_events() -> void:
	completed_events = checkpoint_events.duplicate()

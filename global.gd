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


const SAVE_PATH = "user://save_game.save"

func save_game() -> void:
	# Bundle all our important variables into a Dictionary
	checkpoint_events = completed_events.duplicate()
	var save_data = {
		"has_checkpoint": has_checkpoint,
		"respawn_x": respawn_position.x,
		"respawn_y": respawn_position.y,
		
		# --- THE FIX: Write the health to the save file ---
		"player_health": player_health,
		
		"safe_weapons": GlobalInventory.checkpoint_weapons,
		"safe_items": GlobalInventory.checkpoint_items,
		"safe_equipped_weapon": GlobalInventory.checkpoint_equipped_weapon,
		"safe_equipped_armor": GlobalInventory.checkpoint_equipped_armor,
		"scene_path": current_scene_path,
		"events": checkpoint_events 
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
	
	# --- THE FIX: Load into the checkpoint array, then copy to current! ---
	checkpoint_events.assign(save_data.get("events", []))
	completed_events = checkpoint_events.duplicate()
	
	return true
	
func restore_events() -> void:
	completed_events = checkpoint_events.duplicate()

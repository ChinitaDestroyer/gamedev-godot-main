extends Area2D

# This gives you a folder icon in the Inspector to easily select your next level!
@export_file("*.tscn") var next_level_path: String

# --- NEW: Modular quest completion! ---
@export var completes_quest: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		
		# 1. Make sure we actually picked a level in the Inspector
		if next_level_path == "":
			print("Error: You forgot to set the next level path on the door!")
			return
			
		print("Player entered the door! Moving to: ", next_level_path)
		
		# --- NEW: Finish the objective BEFORE saving! ---
		if completes_quest != "":
			Global.complete_quest(completes_quest)
		
		# 2. Tell the Global memory that our new "safe area" is the next level
		Global.current_scene_path = next_level_path
		Global.has_checkpoint = false # Reset the checkpoint flag so they spawn at the new level's default start point!
		
		# 3. Save the current health and inventory to the hard drive
		Global.player_health = body.current_health
		GlobalInventory.save_to_checkpoint()
		Global.save_game()
		
		# 4. Magically change the scene!
		get_tree().change_scene_to_file(next_level_path)

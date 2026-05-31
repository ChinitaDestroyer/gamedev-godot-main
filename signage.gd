extends Area2D

@export var sign_text: String = "Room 000"

# We use this to track if the player is currently close enough to read the sign
var player_in_zone: bool = false 

func _ready() -> void:
	# You can delete the Label node from the signage.tscn if you no longer want it,
	# or change its text to say "[E] Read" so the player knows they can interact.
	if has_node("Label"):
		$Label.hide()

func _input(event: InputEvent) -> void:
	# If the player is in the zone AND they press the interact button...
	if player_in_zone and event.is_action_pressed("interact"):
		
		# Stop this input from accidentally triggering other things in the same frame
		get_viewport().set_input_as_handled()
		
		# Show the floating prompt if you kept it
		if has_node("Label"):
			$Label.hide() 
			
		# Call the DialogManager and pass the text. 
		# We put sign_text inside [] because show_dialogue expects an Array[String].
		DialogManager.show_dialogue([sign_text])


# --- SIGNALS ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = true
		
		# Show the "[E] Read" prompt
		if has_node("Label"):
			$Label.text = "[E] Read"
			$Label.show()
			
		# --- NEW: On-screen tutorial for signs! ---
		if not Global.seen_sign_tutorial:
			Global.seen_sign_tutorial = true
			if body.has_method("show_tutorial_message"):
				body.show_tutorial_message("TUTORIAL: Press [E] to read room numbers and signs.", 4.0)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_zone = false
		if has_node("Label"):
			$Label.hide()

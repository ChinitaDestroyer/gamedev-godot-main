extends Node2D

# Grab the label node so we can turn the prompt on and off
@onready var prompt: Label = $Label

# A switch to track if the player is close enough to read
var can_interact: bool = false

func _ready() -> void:
	# Hide the "Press E" prompt when the game starts
	prompt.hide()

# --- SIGNALS ---

func _on_body_entered(body: Node2D) -> void:
	# Check if the thing that entered the circle is specifically the Player
	if body.name == "Player":
		prompt.show()
		can_interact = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		prompt.hide()
		can_interact = false

# --- INPUT HANDLING ---

func _input(event: InputEvent) -> void:
	# If the player is in the zone AND they press the 'E' key
	if can_interact and event.is_action_pressed("interact"):
		
		# CRITICAL FIX: Tell Godot to stop passing this 'E' press to other scripts
		# (Like the Dialogue Manager or doors behind the player)
		get_viewport().set_input_as_handled() 
		
		read_note()

# --- HELPER FUNCTION ---

func read_note() -> void:
	# Trigger your global DialogueManager
	# The square brackets [ ] create the list of pages you can click through!
	DialogManager.show_dialogue([
		"Hey. If you’re reading this, the sedatives finally wore off. I waited as long as I could,",
		"but the hoard broke through the north wing and the smell started drawing them to this floor.",
		"I left the key for 4th floor main door to room 428. Probably the staff close the door on this floor",
		"to avoid the horde to reach this room.",
		"I have left you a knife on room 408, 'Cause I know you might need it.",
		"Move to 3rd floor, and I have something for you that might help you escape this hospital.",
		"Don't make me regret leaving you behind. Move fast, stay quiet."
	])

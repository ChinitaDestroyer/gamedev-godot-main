extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var solid_collision: CollisionShape2D = $StaticBody2D/SolidCollision
@onready var prompt: Label = $Label
@onready var open_sfx: AudioStreamPlayer = $OpenSound
@onready var close_sfx: AudioStreamPlayer = $CloseSound
@onready var locked_sfx: AudioStreamPlayer = $LockedSound
# --- NEW: Exported variables ---
# This creates a checkbox in the Inspector for every individual door!
@export var is_locked: bool = false 

var can_interact: bool = false
var is_open: bool = false 

func _ready() -> void:
	anim.play("closed")
	solid_collision.disabled = false
	prompt.hide()
	prompt.text = "[E] Open"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = true
		
		if body.global_position.y < global_position.y:
			prompt.position.y = 0
		else:
			prompt.position.y = 0
			
		prompt.show()
		
		# --- NEW: On-screen tutorial for doors! ---
		if not Global.seen_door_tutorial:
			Global.seen_door_tutorial = true
			if body.has_method("show_tutorial_message"):
				if is_locked:
					body.show_tutorial_message("TUTORIAL: This door is locked. Find a key to open it.", 5.0)
				else:
					body.show_tutorial_message("TUTORIAL: Press [E] to open or close doors.", 4.0)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		prompt.hide()

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled() 
		toggle_door()

# --- UPDATED FUNCTION ---
func toggle_door() -> void:
	# 1. Check if the door is locked first!
	if is_locked and not is_open:
		
		# --- NEW: Check the player's pockets for a key! ---
		if GlobalInventory.consume_key():
			# We found a key! Turn off the lock permanently.
			is_locked = false
			open_sfx.play()
			DialogManager.show_dialogue(["*Click!* You unlocked the door."])
			
			# Notice there is NO 'return' here! 
			# Because we didn't return, the code will continue down below and physically open the door!
			
		else:
			locked_sfx.play()
			# No key found in the inventory!
			DialogManager.show_dialogue(["The door is firmly locked.", "You need a key to open it!"])
			return # Stop the function here so the door stays shut
			
	# 2. Normal open/close logic
	is_open = !is_open 
	
	if is_open:
		open_sfx.play()
		anim.play("open")
		solid_collision.set_deferred("disabled", true)
		prompt.text = "[E] Close"
		
		# --- THIS INSTANTLY LETS LIGHT THROUGH ---
		if has_node("LightOccluder2D"):
			$LightOccluder2D.hide()
			
	else:
		close_sfx.play()
		anim.play("closed")
		solid_collision.set_deferred("disabled", false)
		prompt.text = "[E] Open"
		
		# --- THIS BLOCKS THE LIGHT AGAIN ---
		if has_node("LightOccluder2D"):
			$LightOccluder2D.show()

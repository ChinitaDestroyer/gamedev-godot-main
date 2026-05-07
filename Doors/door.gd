extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var solid_collision: CollisionShape2D = $StaticBody2D/SolidCollision
@onready var prompt: Label = $Label

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
			prompt.position.y = 40 
		else:
			prompt.position.y = -40 
			
		prompt.show()

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
	# 1. NEW: Check if the door is locked first!
	if is_locked and not is_open:
		# Trigger your dialogue manager to tell the player it's locked
		DialogManager.show_dialogue(["The door is firmly locked.", "It won't budge!"])
		
		# 'return' instantly stops the function here, so the door doesn't open
		return 

	# 2. Normal open/close logic
	is_open = !is_open 
	
	if is_open:
		anim.play("open")
		solid_collision.set_deferred("disabled", true)
		prompt.text = "[E] Close"
	else:
		anim.play("closed")
		solid_collision.set_deferred("disabled", false)
		prompt.text = "[E] Open"

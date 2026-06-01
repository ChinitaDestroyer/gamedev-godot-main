extends Node2D

@export_multiline var note_pages: Array[String] = ["This is a blank note."]
@export var quests_to_add: Dictionary = {}
@export var next_objective: String = "Find a way out of the facility."

@onready var prompt: Label = $Label
var can_interact: bool = false
var player_ref: Node2D = null 

func _ready() -> void:
	prompt.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = true
		player_ref = body
		prompt.show()
		
		if not Global.seen_note_tutorial:
			Global.seen_note_tutorial = true 
			if body.has_method("show_tutorial_message"):
				body.show_tutorial_message("TUTORIAL: Press [E] to read documents for clues.", 4.0)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		can_interact = false
		player_ref = null
		prompt.hide()

func _input(event: InputEvent) -> void:
	if can_interact and event.is_action_pressed("interact") and player_ref != null:
		get_viewport().set_input_as_handled()
		read_note()
		
		var new_title = ""
		if next_objective != "":
			new_title = "Objective: " + next_objective
			
		for quest_name in quests_to_add.keys():
			var requirements = quests_to_add[quest_name]
			Global.add_quest(quest_name, requirements, new_title)

func read_note() -> void:
	DialogManager.show_dialogue(note_pages)

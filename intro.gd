extends Control

@onready var dialogue_text = $SubtitleBox/DialogueText
@onready var black_screen = $BlackScreen
@onready var anim_player = $AnimPlayer
@onready var sfx_player = $AudioPlayers/SFXPlayer

# The path to your actual first gameplay level
const LEVEL_1_PATH = "res://levels/level_1.tscn"

var current_index = 0

# The dialogue script stored as an array of dictionaries
var script_lines = [
	{"speaker": "none", "text": "[i](Screen is pitch black. A heart monitor beeps slowly. Suddenly, the power cuts out with a heavy clunk. The monitor dies.)[/i]", "event": "none"},
	{"speaker": "PLAYER", "text": "My head... feels like it was split open with a hammer.", "event": "fade_in"},
	{"speaker": "PLAYER", "text": "Hello? ... Nurse? Is anyone there?", "event": "none"},
	{"speaker": "none", "text": "[i](A heavy, dragging footstep echoes from the hallway outside. Then another.)[/i]", "event": "play_footsteps"},
	{"speaker": "PLAYER", "text": "Hey! Who's out there? I need a doctor in here!", "event": "none"},
	{"speaker": "none", "text": "[i](A burst of harsh static erupts from the nurse's call-button speaker.)[/i]", "event": "play_static"},
	{"speaker": "INTERCOM", "text": "[color=yellow]...repeat, is anyone alive on the third floor... if you are awake... do not open your doors.[/color]", "event": "none"},
	{"speaker": "PLAYER", "text": "Hey! I'm here! Room 401! I'm locked in!", "event": "none"},
	{"speaker": "INTERCOM", "text": "[color=yellow]Keep your voice down! They track sound. Listen to me very carefully. The evacuation failed. The hospital is gone.[/color]", "event": "none"},
	{"speaker": "INTERCOM", "text": "[color=yellow]There's a surgical tray next to your bed. Grab whatever is sharp. The east stairwell is at the end of the hall. Run.[/color]", "event": "none"},
	{"speaker": "none", "text": "[i](A loud slam hits the bedroom door. The wood begins to splinter. Low groans rise from the hallway.)[/i]", "event": "door_bang"},
	{"speaker": "PLAYER", "text": "Okay. Okay, get up. Move!", "event": "none"}
]

func _ready():
	# Ensure the screen starts black
	black_screen.modulate.a = 1.0
	display_current_line()

func _input(event):
	# Advance dialogue on Left Click, Spacebar, or Enter
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):
		advance_dialogue()

func advance_dialogue():
	current_index += 1
	
	if current_index < script_lines.size():
		display_current_line()
	else:
		start_gameplay()

func display_current_line():
	var line_data = script_lines[current_index]
	var formatted_text = ""
	
	# Format the text based on who is speaking
	if line_data["speaker"] == "none":
		formatted_text = "[color=gray]" + line_data["text"] + "[/color]"
	else:
		formatted_text = "[b]" + line_data["speaker"] + ":[/b] " + line_data["text"]
		
	# Update the RichTextLabel (using append_text or setting text with BBCode)
	dialogue_text.text = formatted_text
	
	# Handle special events tied to this specific line of dialogue
	trigger_event(line_data["event"])

func trigger_event(event_name: String):
	match event_name:
		"fade_in":
			anim_player.play("fade_in")
		"play_footsteps":
			# Example of playing a sound. You would preload your audio stream here.
			# sfx_player.stream = preload("res://audio/footsteps.wav")
			# sfx_player.play()
			print("SFX: Footsteps playing")
		"play_static":
			print("SFX: Intercom static playing")
		"door_bang":
			print("SFX: Door banging playing")

func start_gameplay():
	# Change to your actual game level
	print("Starting Game...")
	get_tree().change_scene_to_file("res://scene/first_round_map.tscn")

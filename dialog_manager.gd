extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label
@onready var indicator: Label = $Panel/Indicator # NEW: Grabs your indicator

var is_active: bool = false
var dialogue_lines: Array[String] = []
var current_line_index: int = 0

func _ready() -> void:
	panel.hide()

func show_dialogue(lines: Array[String]) -> void:
	is_active = true
	dialogue_lines = lines
	current_line_index = 0
	
	label.text = dialogue_lines[current_line_index]
	
	# NEW: Update the indicator right when the box opens
	update_indicator() 
	
	panel.show()
	get_tree().paused = true 

func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		
		current_line_index += 1
		
		if current_line_index < dialogue_lines.size():
			label.text = dialogue_lines[current_line_index]
			
			# NEW: Update the indicator every time we turn the page
			update_indicator() 
			
		else:
			is_active = false
			panel.hide()
			get_tree().paused = false

# --- HELPER FUNCTION ---

func update_indicator() -> void:
	# If we are NOT on the very last page
	if current_line_index < dialogue_lines.size() - 1:
		indicator.text = "[E] Next ▼"
	# If we ARE on the last page
	else:
		indicator.text = "[E] Close ✖"

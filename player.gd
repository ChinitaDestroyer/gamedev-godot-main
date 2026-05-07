extends CharacterBody2D

# --- SETTINGS ---
@export_category("Movement Settings")
@export var walk_speed: float = 300.0
@export var sprint_speed: float = 350.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# --- VARIABLES ---
var current_speed: float
var input_dir: Vector2 = Vector2.ZERO

# --- NODES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_speed = walk_speed

func _physics_process(delta: float) -> void:
	handle_input()
	handle_movement(delta)
	handle_animation()
	
	move_and_slide()

# --- HELPER FUNCTIONS ---

func handle_input() -> void:
	input_dir = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed

func handle_movement(delta: float) -> void:
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * current_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func handle_animation() -> void:
	if input_dir == Vector2.ZERO:
		anim.play("idle")
	else:
		anim.play("walk")
		
		# Automatically face any angle (Cardinal or Diagonal)
		anim.rotation = input_dir.angle() - (PI / 2.0)

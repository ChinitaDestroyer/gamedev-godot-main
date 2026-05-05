extends CharacterBody2D
# --- PLAYER STATS ---
@export var max_health: int = 100
var current_health: int = 100

@export var base_speed: float = 200.0 # Your new normal default speed
var current_speed: float = 200.0

var is_stunned: bool = false
var stun_timer: float = 0.0
@export var speed: float = 150.0

# --- WEAPON SYSTEM ---
var current_weapon: String = "knife"
var is_attacking: bool = false

var weapon_data = {
	"bat": {
		"idle_offset": Vector2(-4, 3),
		"attack_offset": Vector2(15, -2),
		"flash_idle": Vector2(20, 0),
		"flash_attack": Vector2(20, 0),
		"reach": 50.0,
		"hitbox_size": Vector2(20, 40),
		"type": "melee"
	},
	"knife": {
		"idle_offset": Vector2(7, 6),
		"attack_offset": Vector2(7, 11),
		"flash_idle": Vector2(15, 0),
		"flash_attack": Vector2(15, 0),
		"reach": 35.0,
		"hitbox_size": Vector2(15, 20),
		"type": "melee"
	},
	"gun": {
		"idle_offset": Vector2(7, 1),
		"attack_offset": Vector2(19, 3),
		"flash_idle": Vector2(20, 0),
		"flash_attack": Vector2(20, 0),
		"reach": 60.0,
		"hitbox_size": Vector2(10, 10),
		"type": "ranged"
	},
	"riffle": {
		"idle_offset": Vector2(20, 0),
		"attack_offset": Vector2(50, 3),
		"flash_idle": Vector2(20, 0),
		"flash_attack": Vector2(20, 0),
		"reach": 75.0,
		"hitbox_size": Vector2(10, 10),
		"type": "ranged"
	},
	"firethrower": {
		"idle_offset": Vector2(15, 0),
		"attack_offset": Vector2(55, 5),
		"flash_idle": Vector2(20, 0),
		"flash_attack": Vector2(20, 0),
		"reach": 55.0,
		"hitbox_size": Vector2(60, 30),
		"type": "melee"
	}
}

# --- COMPONENTS ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var flashlight: PointLight2D = $PointLight2D
@onready var melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

enum State { IDLE, WALK, ATTACK }
var state = State.IDLE

func _ready():
	melee_shape.disabled = true

	var crosshair = load("res://asset ni oswel/crosshair.png")
	Input.set_custom_mouse_cursor(crosshair, Input.CURSOR_ARROW, Vector2(30, 32))


func _physics_process(delta): # Add delta here!
	# Handle the temporary stagger/slow when a zombie hits you
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			update_speed() # Recalculate speed based on health
			
	handle_movement()
	handle_aim()
	handle_attack_input()
	update_animation()
	update_weapon_alignment()
	move_and_slide()

# --- MOVEMENT ---
func handle_movement():
	var direction = Input.get_vector("left", "right", "up", "down")
	# 🔥 USE CURRENT_SPEED HERE, NOT SPEED!
	velocity = direction * current_speed


# --- AIM ---
func handle_aim():
	look_at(get_global_mouse_position())


# --- ATTACK INPUT ---
func handle_attack_input():
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()


# --- ANIMATION ---
func update_animation():
	if is_attacking:
		return

	if velocity.length() > 0:
		state = State.WALK
		var anim = "walk_" + current_weapon

		# 🔥 THE FIX: We added 'or not sprite.is_playing()' so it unpauses!
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)

		var look_dir = Vector2.from_angle(rotation)
		var move_dir = velocity.normalized()
		sprite.speed_scale = 1.0 if move_dir.dot(look_dir) > -0.1 else -1.0

	else:
		state = State.IDLE
		sprite.play("walk_" + current_weapon)
		sprite.stop()
		sprite.frame = 0

# --- WEAPON ALIGNMENT (FIXED) ---
func update_weapon_alignment():
	var data = weapon_data.get(current_weapon)
	if data == null:
		return

	var rect = melee_shape.shape if melee_shape.shape is RectangleShape2D else null

	body_shape.position = Vector2.ZERO

	if is_attacking:
		sprite.position = data.attack_offset
		if flashlight: flashlight.position = data.flash_attack
	else:
		sprite.position = data.idle_offset
		if flashlight: flashlight.position = data.flash_idle

	# 🔥 FIX: REPLACE hitbox_pos with reach system
	if rect:
		rect.size = data.hitbox_size

		var forward = Vector2.RIGHT.rotated(rotation)
		melee_shape.position = forward * data.reach


# --- COMBAT ---
func attack():
	if state == State.ATTACK:
		return

	state = State.ATTACK
	is_attacking = true

	sprite.speed_scale = 1.0
	sprite.play(current_weapon)

	var data = weapon_data[current_weapon]

	if data.type == "melee":
		melee_shape.disabled = false

	await sprite.animation_finished

	melee_shape.disabled = true

	is_attacking = false
	state = State.IDLE
	# --- PLAYER HEALTH & DAMAGE ---
func take_damage(amount: int):
	current_health -= amount
	print("Player Health: ", current_health) # Prints to your output console to test!
	
	# 1. THE IMPACT SLOW (Zombie hit you!)
	is_stunned = true
	stun_timer = 0.5 # You are slowed for 0.5 seconds
	current_speed = base_speed * 0.3 # You slow down to 30% speed while staggering!
	
	if current_health <= 0:
		print("PLAYER IS DEAD!") # We will add a game over screen later
	elif not is_stunned:
		update_speed()

func update_speed():
	# 2. THE INJURY SLOW (Health Kit needed!)
	if current_health <= 50:
		current_speed = base_speed * 0.6 # Permanently slowed to 60% speed
	else:
		current_speed = base_speed # Normal speed

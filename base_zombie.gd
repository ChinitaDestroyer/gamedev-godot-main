extends CharacterBody2D

# --- ZOMBIE STATS ---
@export var health: int = 100
@export var speed: float = 100.0
@export var attack_damage: int = 10 # 🔥 Add this line!

# 🔥 NEW: Two different ranges to measure!
@export var melee_range: float = 60.0 
@export var special_range: float = 200.0 

# --- THE COOLDOWN SYSTEM ---
@export var normal_attacks: Array[String] = ["attack1"]
@export var special_attacks: Array[String] = []
@export var special_cooldown: float = 15.0 

var current_cooldown: float = 0.0 

# --- COMPONENTS ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

enum State { IDLE, CHASE, ATTACK, DEAD }
var state = State.IDLE

var player = null

func _ready():
	attack_shape.disabled = true
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	if state == State.DEAD or player == null:
		return
		
	# Tick down the cooldown timer
	if current_cooldown > 0:
		current_cooldown -= _delta

	var distance_to_player = global_position.distance_to(player.global_position)

	if state != State.ATTACK:
		# 1st Check: Is the player far away, but inside the LONG range?
		# And is the special attack ready?
		if distance_to_player <= special_range and special_attacks.size() > 0 and current_cooldown <= 0.0:
			attack("special")
			
		# 2nd Check: Is the player super close, inside the SHORT range?
		elif distance_to_player <= melee_range:
			attack("normal")
			
		# 3rd Check: If neither, keep walking toward the player!
		else:
			chase_player()

# --- MOVEMENT / AI ---
func chase_player():
	state = State.CHASE
	if sprite.animation != "walk":
		sprite.play("walk")

	nav_agent.target_position = player.global_position
	var direction = global_position.direction_to(nav_agent.get_next_path_position())
	velocity = direction * speed
	look_at(player.global_position) 
	move_and_slide()

# --- COMBAT ---
# 🔥 NEW: The attack function now needs to know which type of attack to do!
func attack(attack_type: String):
	if state == State.ATTACK:
		return

	state = State.ATTACK
	velocity = Vector2.ZERO 
	
	var anim_to_play: String = ""
	
	# Play the correct animation based on what _physics_process told us
	if attack_type == "special":
		anim_to_play = special_attacks.pick_random()
		current_cooldown = special_cooldown
	else:
		anim_to_play = normal_attacks.pick_random()
	
	sprite.play(anim_to_play) 
	attack_shape.disabled = false 

	await sprite.animation_finished 

	attack_shape.disabled = true 

	if state != State.DEAD:
		state = State.CHASE
		
# --- ZOMBIE HEALTH & DEATH ---
func take_damage(amount: int):
	if state == State.DEAD:
		return
		
	health -= amount
	
	if health <= 0:
		die()

func die():
	state = State.DEAD
	velocity = Vector2.ZERO # Stop walking
	sprite.play("death")
	
	# Turn off collisions so the player can walk over the dead body!
	attack_shape.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	# If the thing the blue box touched is the Player...
	if body.is_in_group("Player"):
		# ...tell the player to take damage!
		body.take_damage(attack_damage)

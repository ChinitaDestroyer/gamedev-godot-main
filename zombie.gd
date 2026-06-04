extends CharacterBody2D

@export var roam_speed: float = 40.0
@export var chase_speed: float = 120.0

var current_state: String = "ROAM"

@export var roam_direction: Vector2 = Vector2.RIGHT
@export var attack_damage: int = 20
@export var max_health: int = 100
@export var can_drop_loot: bool = false # Defaults to false so Round 1 zombies drop nothing!
const PICKUP_SCENE = preload("res://pickup_item.tscn")

# --- NEW: Replaced the math distance with our Hitbox variable ---
var player_in_attack_range: bool = false
var current_health: int = max_health
var player_ref: Node2D = null
var initial_position: Vector2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var roam_timer: Timer = $RoamTimer
@onready var detection_area: Area2D = $DetectionArea
@onready var vision_raycast: RayCast2D = $VisionRayCast
@onready var alert_sfx: AudioStreamPlayer = $AlertSound
@onready var attack_sfx: AudioStreamPlayer = $AttackSound
@onready var hurt_sfx: AudioStreamPlayer = $HurtSound
@onready var death_sfx: AudioStreamPlayer = $DeathSound




func _ready() -> void:
	initial_position = global_position 
	var base_id = name + "_" + str(initial_position)
	
	# Check our global list to see if this specific zombie is dead
	for event in Global.completed_events:
		if event.begins_with(base_id):
			
			# We found our death certificate! Split it at the "|" symbol
			var parts = event.split("|")
			if parts.size() > 1:
				# Apply the exact rotation we had when we died
				anim.rotation = float(parts[1])
			
			# Turn into a corpse
			die(false) 
			
			# --- BONUS FIX: Fast-forward to the end of the death animation! ---
			# This stops the corpse from re-playing the falling animation on reload
			var last_frame = anim.sprite_frames.get_frame_count("death") - 1
			anim.frame = last_frame
			
			return # Stop reading _ready()

func _physics_process(_delta: float) -> void:
		# 1. State Logic
		
	if current_state == "DEATH":
		return

	if current_state == "ROAM":
		velocity = roam_direction * roam_speed
		
	elif current_state == "CHASE" and player_ref != null:
		
		# 1. Shoot the invisible laser exactly at the player's position
		vision_raycast.target_position = to_local(player_ref.global_position)
		vision_raycast.force_raycast_update()
		
		# 2. Check if the laser hit a wall instead of the player
		var is_blocked_by_wall = false
		if vision_raycast.is_colliding():
			var object_hit = vision_raycast.get_collider()
			if object_hit != player_ref:
				is_blocked_by_wall = true
				
		# 3. Decide what to do!
		if is_blocked_by_wall:
			current_state = "ROAM"
			player_ref = null
			reset_patrol_direction()
		else:
			# Line of sight is clear! Proceed as normal.
			if player_in_attack_range:
				start_attack()
			else:
				var direction = global_position.direction_to(player_ref.global_position)
				velocity = direction * chase_speed
			
	elif current_state == "ATTACK":
		# Freeze the zombie in place while the attack animation plays
		velocity = Vector2.ZERO

	# 2. Visuals (Top-Down Rotation)
	if current_state != "ATTACK":
		if velocity != Vector2.ZERO:
			anim.play("walk")
			anim.rotation = velocity.angle() - (PI / 2.0)
			
			if detection_area:
				detection_area.rotation = velocity.angle() - (PI / 2.0)
		else:
			anim.play("idle")

	# 3. Move
	move_and_slide()


# --- ATTACK LOGIC ---
func start_attack() -> void:
	current_state = "ATTACK"
	velocity = Vector2.ZERO 
	attack_sfx.play()
	if player_ref != null:
		var direction_to_player = global_position.direction_to(player_ref.global_position)
		anim.rotation = direction_to_player.angle() - (PI / 2.0)
		
		# Swing the vision box to face the player while attacking
		if detection_area:
			detection_area.rotation = anim.rotation 
			
		# --- NEW: Deal the damage! ---
		# We use has_method just to be 100% safe so the game doesn't crash
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)
		
	anim.play("attack")


# --- SIGNALS ---
func _on_roam_timer_timeout() -> void:
	if current_state == "ROAM":
		roam_direction = roam_direction * -1

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if current_state != "CHASE":
			alert_sfx.play()
		current_state = "CHASE"
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	# --- NEW: If the zombie is dead, ignore this completely! ---
	if current_state == "DEATH":
		return

	if body.name == "Player":
		player_ref = null
		
		# Only go back to ROAM instantly if we aren't mid-swing
		if current_state != "ATTACK":
			current_state = "ROAM"
			reset_patrol_direction()

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		if player_ref != null:
			current_state = "CHASE"
		else:
			current_state = "ROAM"
			reset_patrol_direction()

# --- NEW HITBOX SIGNALS ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_attack_range = false


# --- HELPER ---
func reset_patrol_direction() -> void:
	var reset_dir = velocity.normalized()
	
	if abs(reset_dir.x) > abs(reset_dir.y):
		roam_direction = Vector2(sign(reset_dir.x), 0) 
	else:
		roam_direction = Vector2(0, sign(reset_dir.y)) 
		
	if roam_direction == Vector2.ZERO:
		roam_direction = Vector2.RIGHT
		
func take_damage(damage_amount: int) -> void:
	# Ignore damage if we are already dead
	if current_state == "DEATH":
		return
		
	current_health -= damage_amount
	print("Take that! Zombie health is now: ", current_health)
	
	# --- NEW: Red Damage Flash Effect ---
	var tween = create_tween()
	anim.modulate = Color(1.0, 0.0, 0.0) # Instantly turn Red
	tween.tween_property(anim, "modulate", Color(1.0, 1.0, 1.0), 0.3) # Fade back to normal over 0.3 seconds
	# ------------------------------------
	
	# Did we just strike the killing blow?
	if current_health <= 0:
		die()
	else:
		hurt_sfx.play()

func die(is_fresh_kill: bool = true) -> void:
	if is_fresh_kill:
		death_sfx.play()
	# 1. Create the base ID and grab the current rotation
	var base_id = name + "_" + str(initial_position)
	var save_string = base_id + "|" + str(anim.rotation)
	
	# 2. Check if we already saved this death to avoid duplicates
	var already_saved = false
	for event in Global.completed_events:
		if event.begins_with(base_id):
			already_saved = true
			break
			
	if not already_saved:
		Global.completed_events.append(save_string)
		
		# --- NEW: Roll the dice for loot on a fresh kill! ---
		drop_loot()
		
	# 3. The rest of your normal death logic
	current_state = "DEATH"
	velocity = Vector2.ZERO 
	
	$CollisionShape2D.set_deferred("disabled", true)
	if detection_area:
		detection_area.queue_free()
	if has_node("AttackArea"):
		$AttackArea.queue_free()
		
	z_index = 0
	anim.play("death")

func drop_loot() -> void:
	
	# --- THE FIX: Stop here if this zombie isn't allowed to drop items! ---
	if can_drop_loot == false:
		return 
	# ----------------------------------------------------------------------
		
	# Keep this at 1.0 for testing, change to 0.5 later!
	if randf() <= .5: 
		print("Zombie dropped ammo!")
		
		var drop = PICKUP_SCENE.instantiate()
		
		drop.item_name = "Pistol Ammo"
		drop.item_type = "ammo"
		drop.item_value = randi_range(5, 10) 
		drop.name = "DroppedAmmo_" + str(randi())
		
		# FIX 1: Force the item to render on TOP of the dead zombie corpse
		drop.z_index = 5 
		
		var level = get_tree().current_scene
		level.call_deferred("add_child", drop)
		
		# FIX 2: Set the position AFTER it is safely added to the tree, 
		# preventing it from teleporting to the top-left of the map!
		drop.set_deferred("global_position", global_position)
		

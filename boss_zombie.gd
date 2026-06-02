extends CharacterBody2D

@export var roam_speed: float = 40.0
@export var base_chase_speed: float = 120.0
@export var enraged_chase_speed: float = 220.0 # SUPER FAST!
@export var attack_damage: int = 45
@export var max_health: int = 500
@export var is_boss_holding_key: bool = true # Always true for the boss

var current_state: String = "ROAM"
var roam_direction: Vector2 = Vector2.RIGHT
var player_in_attack_range: bool = false
var current_health: int = max_health
var player_ref: Node2D = null
var initial_position: Vector2

# --- NEW: Boss Mechanics ---
var is_enraged: bool = false
var current_chase_speed: float = base_chase_speed

const PICKUP_SCENE = preload("res://pickup_item.tscn")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var roam_timer: Timer = $RoamTimer
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	initial_position = global_position 
	var base_id = name + "_" + str(initial_position)
	
	for event in Global.completed_events:
		if event.begins_with(base_id):
			var parts = event.split("|")
			if parts.size() > 1:
				anim.rotation = float(parts[1])
			die() 
			var last_frame = anim.sprite_frames.get_frame_count("death") - 1
			anim.frame = last_frame
			return 

func _physics_process(_delta: float) -> void:
	if current_state == "DEATH":
		return

	if current_state == "ROAM":
		velocity = roam_direction * roam_speed
		
	elif current_state == "CHASE" and player_ref != null:
		if player_in_attack_range:
			start_attack()
		else:
			var direction = global_position.direction_to(player_ref.global_position)
			velocity = direction * current_chase_speed
			
	elif current_state == "ATTACK":
		velocity = Vector2.ZERO

	if current_state != "ATTACK":
		if velocity != Vector2.ZERO:
			anim.play("walk")
			anim.rotation = velocity.angle() - (PI / 2.0)
			if detection_area:
				detection_area.rotation = velocity.angle() - (PI / 2.0)
		else:
			anim.play("idle")

	move_and_slide()

func start_attack() -> void:
	current_state = "ATTACK"
	velocity = Vector2.ZERO 
	
	if player_ref != null:
		var direction_to_player = global_position.direction_to(player_ref.global_position)
		anim.rotation = direction_to_player.angle() - (PI / 2.0)
		if detection_area:
			detection_area.rotation = anim.rotation 
			
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(attack_damage)
		
	anim.play("attack")

func take_damage(damage_amount: int) -> void:
	if current_state == "DEATH":
		return
		
	current_health -= damage_amount
	print("Boss health is now: ", current_health)
	
	# --- NEW: Phase 2 Enrage Logic ---
	if current_health <= (max_health / 2) and not is_enraged:
		trigger_enrage()
	# ---------------------------------
	
	var tween = create_tween()
	anim.modulate = Color(1.0, 0.0, 0.0) 
	
	# If enraged, fade back to dark red. Otherwise, fade back to normal.
	var return_color = Color(0.6, 0.0, 0.0) if is_enraged else Color(1.0, 1.0, 1.0)
	tween.tween_property(anim, "modulate", return_color, 0.3) 
	
	if current_health <= 0:
		die()

# --- NEW: ENRAGE FUNCTION ---
func trigger_enrage() -> void:
	is_enraged = true
	current_chase_speed = enraged_chase_speed
	
	# Visual cue that the boss is mad!
	anim.modulate = Color(0.6, 0.0, 0.0) # Permanently tint dark red
	
	# Make it hit even harder in Phase 2
	attack_damage = 65 
	
	print("THE BOSS IS ENRAGED!")

func die() -> void:
	var base_id = name + "_" + str(initial_position)
	var save_string = base_id + "|" + str(anim.rotation)
	
	var already_saved = false
	for event in Global.completed_events:
		if event.begins_with(base_id):
			already_saved = true
			break
			
	if not already_saved:
		Global.completed_events.append(save_string)
		drop_loot()
		
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
	if is_boss_holding_key:
		print("Boss killed! Dropping the Exit Key!")
		var drop = PICKUP_SCENE.instantiate()
		
		drop.item_name = "Exit Key"
		drop.item_type = "key"
		drop.name = "DroppedKey_Boss" 
		
		drop.z_index = 5 
		
		var level = get_tree().current_scene
		level.call_deferred("add_child", drop)
		drop.set_deferred("global_position", global_position)

# --- STANDARD SIGNALS ---
func _on_roam_timer_timeout() -> void:
	if current_state == "ROAM":
		roam_direction = roam_direction * -1
		
	var reset_dir = velocity.normalized()
	if abs(reset_dir.x) > abs(reset_dir.y):
		roam_direction = Vector2(sign(reset_dir.x), 0) 
	else:
		roam_direction = Vector2(0, sign(reset_dir.y)) 
	if roam_direction == Vector2.ZERO:
		roam_direction = Vector2.RIGHT

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		current_state = "CHASE"
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if current_state == "DEATH":
		return
	if body.is_in_group("player") or body.name == "Player":
		player_ref = null
		if current_state != "ATTACK":
			current_state = "ROAM"

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		if player_ref != null:
			current_state = "CHASE"
		else:
			current_state = "ROAM"

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_in_attack_range = false

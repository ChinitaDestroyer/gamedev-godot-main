extends CharacterBody2D

# --- SETTINGS ---
@export_category("Movement Settings")
@export var walk_speed: float = 500.0
@export var sprint_speed: float = 350.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var max_health: int = 100
@export var max_armor: int = 50

# --- VARIABLES ---
var current_health: int = 100
var current_speed: float
var input_dir: Vector2 = Vector2.ZERO
var current_weapon_prefix: String = ""
var current_armor_prefix: String = ""
var is_dead: bool = false
var is_attacking: bool = false 
var current_armor: int = 0

# NEW: A list to track any enemy currently inside our weapon hitbox!
var enemies_in_range: Array[Node2D] = []

# --- NODES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var armor_bar: ProgressBar = $UI/ArmorBar
@onready var death_screen: ColorRect = $UI/DeathScreen
@onready var gun_raycast: RayCast2D = $GunRayCast

func _ready() -> void:
	if Global.has_checkpoint == true:
		global_position = Global.respawn_position
		
		# --- THE FIX: Apply the saved health to the player! ---
		current_health = Global.player_health
	else:
		# If we don't have a checkpoint, start with full health
		current_health = max_health

	# Update the UI health bar to match our actual health
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# --- NEW: Hide armor bar on start ---
	armor_bar.hide() 
	
	current_speed = walk_speed
	GlobalInventory.weapon_equipped.connect(_on_weapon_equipped)
	_on_weapon_equipped(GlobalInventory.equipped_weapon)
	GlobalInventory.inventory_updated.connect(_on_inventory_changed)
	
	GlobalInventory.armor_equipped.connect(_on_armor_equipped)
	_on_armor_equipped(GlobalInventory.equipped_armor)
	
func _on_weapon_equipped(weapon_name: String) -> void:
	if weapon_name == "Knife":
		current_weapon_prefix = "knife_"
	elif weapon_name == "Pistol": # (Make sure this exactly matches your item_name)
		current_weapon_prefix = "gun_"
		
	else:
		current_weapon_prefix = ""
		
func _on_armor_equipped(armor_name: String) -> void:
	# Make sure the name matches whatever you typed into the pickup_item script!
	if armor_name == "Kevlar Vest": 
		current_armor_prefix = "armor_"
		
		# --- NEW: Fill and show the armor bar! ---
		current_armor = max_armor
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
		armor_bar.show()
	else:
		current_armor_prefix = ""
		
		# --- NEW: Hide the armor bar when unequipped ---
		current_armor = 0
		armor_bar.hide()

func _physics_process(delta: float) -> void:
	# Check if attacking first!
	if is_dead:
		return
		
	if is_attacking:
		velocity = Vector2.ZERO 
		move_and_slide()
		return 
		
	# If not attacking, handle normal movement and animation
	handle_input()
	handle_movement(delta)
	handle_animation()
	
	move_and_slide()

# --- INPUT & ATTACK LOGIC ---

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return # Stop reading inputs if dead!
		
	if event.is_action_pressed("attack") and not is_attacking:
		attack()
	
	if event.is_action_pressed("toggle_flashlight"):
		if GlobalInventory.has_item("Flashlight"):
			
			# Note the new path!
			if has_node("FlashlightPivot/Flashlight"):
				$FlashlightPivot/Flashlight.visible = not $FlashlightPivot/Flashlight.visible

func attack() -> void:
	if current_weapon_prefix == "":
		return
		
	is_attacking = true
	
	var attack_anim_name = current_armor_prefix + current_weapon_prefix + "attack"
	print("✅ TRYING TO PLAY ANIMATION: ", attack_anim_name)
	anim.play(attack_anim_name)
	
	perform_attack()
	
	# THE FAILSAFE: Wait exactly 0.3 seconds, then force the player free!
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

# --- HELPER FUNCTIONS ---

func handle_input() -> void:
	# This handles Up, Down, Left, and Right automatically!
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
	var final_anim = current_armor_prefix + current_weapon_prefix
	
	if input_dir == Vector2.ZERO:
		anim.play(final_anim + "idle")
	else:
		anim.play(final_anim + "walk")
		
	# --- NEW: TWIN-STICK AIMING LOGIC ---
	var mouse_pos = get_global_mouse_position()
	var aim_direction = global_position.direction_to(mouse_pos)
	var aim_angle = aim_direction.angle() - (PI / 2.0)
	
	# Rotates the player sprite
	anim.rotation = aim_angle
	
	# Rotates the weapon hitbox
	if has_node("WeaponArea"):
		$WeaponArea.rotation = aim_angle
		
	# --- NEW: Rotates the Flashlight! ---
	if has_node("FlashlightPivot"):
		$FlashlightPivot.rotation = aim_angle
		
	if gun_raycast:
		gun_raycast.target_position = to_local(mouse_pos)


# --- HEALTH, DAMAGE, & WEAPONS ---

func perform_attack() -> void:
	# --- MELEE ATTACK (KNIFE) ---
	if current_weapon_prefix == "knife_":
		print("--- SWINGING KNIFE ---")
		if enemies_in_range.is_empty():
			print("Swung at the air!")
			
		for enemy in enemies_in_range:
			print("Stabbed an enemy!")
			enemy.take_damage(25)
			
	# --- RANGED ATTACK (PISTOL) ---
	elif current_weapon_prefix == "gun_":
		print("--- FIRING GUN ---")
		
		# Force the raycast to update its math immediately before checking
		gun_raycast.force_raycast_update() 
		
		# Did the laser hit something?
		if gun_raycast.is_colliding():
			
			# Get the exact object the laser touched
			var target = gun_raycast.get_collider()
			
			# Check if the thing we shot has health
			if target.has_method("take_damage"):
				print("Headshot! Dealt massive damage!")
				target.take_damage(50) # Guns should do more damage!
			else:
				print("You shot a wall or an object!")
				
		else:
			print("You shot into the empty distance!")

func take_damage(damage_amount: int) -> void:
	# 1. Does the player have armor?
	if current_armor > 0:
		current_armor -= damage_amount
		
		# Did the zombie hit harder than the armor had left?
		if current_armor < 0:
			var spillover_damage = abs(current_armor) # Get the leftover damage
			current_armor = 0
			current_health -= spillover_damage # Apply spillover to real health
			
			print("Armor broke! Player took ", spillover_damage, " spillover damage.")
			break_armor() # Run our new break function!
		else:
			print("Armor absorbed the hit! Armor remaining: ", current_armor)
			
		armor_bar.value = current_armor
			
	# 2. No armor? Take normal health damage
	else:
		current_health -= damage_amount
		print("Ouch! Player took ", damage_amount, " damage. Health remaining: ", current_health)
		
	health_bar.value = current_health
	
	if current_health <= 0:
		die()

func break_armor() -> void:
	print("The Kevlar Vest was destroyed!")
	
	# --- THE FIX: We deleted the loop that searched the backpack ---
	# Since armor is passive now, it was never in the backpack to begin with!
	
	# Force the player to take off the broken armor
	GlobalInventory.equipped_armor = ""
	GlobalInventory.armor_equipped.emit("")

func die() -> void:
	# Prevent the player from dying multiple times at once
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO # Stop sliding
	
	print("The Player has died!")
	GlobalInventory.equipped_weapon = ""
	
	# Turn off the player's hitboxes so zombies stop biting the corpse
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("WeaponArea"):
		$WeaponArea.queue_free()
	
	# Push the player corpse to the floor layer (just like the zombie!)
	z_index = 0
	
	# Hide the health bar, it's useless now
	health_bar.hide()
	
	# Play the death animation
	anim.play("death")
	
	# Show the bloody game over screen!
	death_screen.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- SIGNALS ---

func _on_animated_sprite_2d_animation_finished() -> void:
	if "attack" in anim.animation:
		is_attacking = false

# --- NEW: Using the signals you connected to update our target list! ---
func _on_weapon_area_body_entered(body: Node2D) -> void:
	# If the thing we touched has health, add it to our hit list
	if body.has_method("take_damage") and body != self:
		enemies_in_range.append(body)

func _on_weapon_area_body_exited(body: Node2D) -> void:
	# If the enemy walks away, remove them from the list
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		
func _on_continue_button_pressed() -> void:
	print("Restarting from checkpoint...")
	
	# Restore the safe inventory
	GlobalInventory.restore_from_checkpoint()
	
	# --- THE FIX: Restore the world items! ---
	Global.restore_events() 
	
	# Now reload the level
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	print("Going back to Main Menu...")
	# Replace the text inside the quotes with the actual path to your Main Menu scene!
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _on_inventory_changed() -> void:
	# If we just dropped or lost the flashlight...
	if not GlobalInventory.has_item("Flashlight"):
		# Force the flashlight OFF and the aura ON
		if has_node("Flashlight") and $Flashlight.visible == true:
			$Flashlight.visible = false
			if has_node("AuraLight"):
				$AuraLight.visible = true

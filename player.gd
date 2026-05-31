extends CharacterBody2D

# --- SETTINGS ---
@export_category("Movement Settings")
@export var walk_speed: float = 500.0
@export var sprint_speed: float = 350.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var max_health: int = 100
@export var max_armor: int = 50
@export var reload_time: float = 1.5 # Takes 1.5 seconds to reload

# --- VARIABLES ---
var current_health: int = 100
var current_speed: float
var input_dir: Vector2 = Vector2.ZERO
var current_weapon_prefix: String = ""
var current_armor_prefix: String = ""
var is_dead: bool = false
var is_attacking: bool = false 
var current_armor: int = 0
var max_ammo: int = 15
var current_ammo: int = 15
var is_reloading: bool = false

var tutorial_step: int = 0
var tutorial_label: Label
var initial_mouse_pos: Vector2


# NEW: A list to track any enemy currently inside our weapon hitbox!
var enemies_in_range: Array[Node2D] = []

# --- NODES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var armor_bar: ProgressBar = $UI/ArmorBar
@onready var death_screen: ColorRect = $UI/DeathScreen
@onready var gun_raycast: RayCast2D = $GunRayCast
@onready var weapon_label: Label = $UI/WeaponLabel
@onready var weapon_icon: TextureRect = $UI/WeaponIcon # <--- NEW LINE

func _ready() -> void:
	if Global.has_checkpoint == true:
		global_position = Global.respawn_position
		current_health = Global.player_health
	else:
		current_health = max_health
		
		# --- NEW: Start the interactive tutorial on a new game! ---
		start_movement_tutorial()
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
		
		# --- NEW: Melee / Knife Tutorial ---
		if not Global.seen_melee_tutorial:
			Global.seen_melee_tutorial = true
			show_tutorial_message("TUTORIAL: Left Click to attack. The knife is for close-range combat.", 5.0)
			
	elif weapon_name == "Pistol": 
		current_weapon_prefix = "gun_"
		
		# --- NEW: Firearm / Pistol Tutorial ---
		if not Global.seen_gun_tutorial:
			Global.seen_gun_tutorial = true
			show_tutorial_message("TUTORIAL: Left Click to shoot. Press [R] to reload.", 5.0)
			
	else:
		current_weapon_prefix = ""
		
	# Update the UI whenever we switch weapons!
	update_hud()
		
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
	if is_dead:
		return
		
	if is_attacking:
		velocity = Vector2.ZERO 
		move_and_slide()
		return 
		
	handle_input()
	
	# --- NEW: Process the interactive movement steps ---
	if tutorial_step > 0:
		handle_tutorial()
		
	handle_movement(delta)
	handle_animation()
	
	move_and_slide()

# --- INPUT & ATTACK LOGIC ---

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return 
		
	if event.is_action_pressed("attack") and not is_attacking:
		attack()
		
	# --- NEW: Listen for the reload key ---
	if event.is_action_pressed("reload"):
		reload()
		
	if event.is_action_pressed("toggle_flashlight"):
		if GlobalInventory.has_item("Flashlight"):
			if has_node("FlashlightPivot/Flashlight"):
				$FlashlightPivot/Flashlight.visible = not $FlashlightPivot/Flashlight.visible

func attack() -> void:
	# Stop if no weapon is equipped OR if we are currently reloading
	if current_weapon_prefix == "" or is_reloading:
		return
		
	# If we try to shoot but have no ammo, trigger reload instead of attacking
	if current_weapon_prefix == "gun_" and current_ammo <= 0:
		reload()
		return
		
	is_attacking = true
	
	var attack_anim_name = current_armor_prefix + current_weapon_prefix + "attack"
	anim.play(attack_anim_name)
	
	perform_attack()
	
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
		
		current_ammo -= 1
		update_hud()
		
		print("--- FIRING GUN ---")
		
		gun_raycast.force_raycast_update() 
		
		if gun_raycast.is_colliding():
			var target = gun_raycast.get_collider()
			if target.has_method("take_damage"):
				print("Headshot! Dealt massive damage!")
				target.take_damage(50) 
		else:
			print("You shot into the empty distance!")
			
		# --- NEW: Auto-reload immediately after firing the last bullet ---
		if current_ammo <= 0:
			reload()

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
				
func update_hud() -> void:
	# Update the bars
	health_bar.value = current_health
	armor_bar.value = current_armor
	
	if GlobalInventory.equipped_weapon != "":
		# --- NEW: Fetch the Icon from the Global Inventory ---
		var icon_path = ""
		for i in range(GlobalInventory.MAX_SLOTS):
			var item = GlobalInventory.items[i]
			if item != null and item["name"] == GlobalInventory.equipped_weapon:
				icon_path = item["icon"]
				break # Stop searching once we find it!
				
		# Apply the icon to our TextureRect
		if icon_path != "":
			weapon_icon.texture = load(icon_path)
			weapon_icon.show()
		# -----------------------------------------------------
		
		# Update the Weapon Text
		if GlobalInventory.equipped_weapon == "Pistol":
			weapon_label.text = "Equipped: Pistol | Ammo: " + str(current_ammo) + "/" + str(max_ammo)
		else:
			weapon_label.text = "Equipped: " + GlobalInventory.equipped_weapon
			
		weapon_label.show()
		
	else:
		# Hide both the label and the icon if our hands are empty
		weapon_label.hide()
		weapon_icon.hide()

func reload() -> void:
	# Cancel if already reloading, magazine is full, or not holding a gun
	if is_reloading or current_ammo == max_ammo or current_weapon_prefix != "gun_":
		return
		
	is_reloading = true
	print("Reloading...")
	
	# Override the UI label to show the reloading status
	if weapon_label:
		weapon_label.text = "Equipped: Pistol | Ammo: Reloading..."
	
	# Wait for the reload time to finish (simulating an animation)
	await get_tree().create_timer(reload_time).timeout
	
	# Refill the magazine and turn off the reloading state
	current_ammo = max_ammo
	is_reloading = false
	
	print("Reload complete!")
	
	# Update the HUD again to restore the normal numbers (e.g., 15/15)
	update_hud()
	
# --- NEW: TUTORIAL FUNCTIONS ---

func setup_tutorial_label() -> void:
	# Only create it if it doesn't exist yet
	if not is_instance_valid(tutorial_label):
		tutorial_label = Label.new()
		tutorial_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tutorial_label.add_theme_font_size_override("font_size", 30)
		tutorial_label.add_theme_color_override("font_outline_color", Color.BLACK)
		tutorial_label.add_theme_constant_override("outline_size", 4)
		
		# Attach it to the Player's existing UI CanvasLayer
		$UI.add_child(tutorial_label)
		tutorial_label.position.y = 100

func start_movement_tutorial() -> void:
	tutorial_step = 1
	setup_tutorial_label()
	tutorial_label.text = "TUTORIAL: Use [W, A, S, D] to move."
	tutorial_label.show()

func handle_tutorial() -> void:
	if tutorial_step == 1:
		# If the player inputs any movement...
		if input_dir != Vector2.ZERO:
			tutorial_step = 2
			tutorial_label.text = "TUTORIAL: Move your mouse around to aim your flashlight."
			initial_mouse_pos = get_viewport().get_mouse_position()
			
	elif tutorial_step == 2:
		# If the player moves their mouse far enough from the starting position...
		if get_viewport().get_mouse_position().distance_to(initial_mouse_pos) > 150:
			tutorial_step = 0 # Turn off the tracking
			show_tutorial_message("TUTORIAL: Explore the facility. Find items and notes.", 4.0)

# Other scripts will call this function to show temporary messages!
func show_tutorial_message(message: String, duration: float) -> void:
	setup_tutorial_label()
	tutorial_label.text = message
	tutorial_label.show()
	
	await get_tree().create_timer(duration).timeout
	
	# Only hide if the text hasn't been replaced by a newer tutorial
	if is_instance_valid(tutorial_label) and tutorial_label.text == message:
		tutorial_label.hide()

extends CharacterBody2D

# --- SETTINGS ---
@export_category("Movement Settings")
@export var walk_speed: float = 500.0
@export var sprint_speed: float = 350.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var max_health: int = 100
@export var max_armor: int = 50
@export var reload_time: float = 1.5 

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
var enemies_in_range: Array[Node2D] = []

# --- NODES ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var armor_bar: ProgressBar = $UI/ArmorBar
@onready var death_screen: ColorRect = $UI/DeathScreen
@onready var gun_raycast: RayCast2D = $GunRayCast
@onready var weapon_label: Label = $UI/WeaponLabel
@onready var weapon_icon: TextureRect = $UI/WeaponIcon 

func _ready() -> void:
	if Global.has_checkpoint == true:
		global_position = Global.respawn_position
		current_health = Global.player_health
	else:
		current_health = max_health
		start_movement_tutorial()
		
	health_bar.max_value = max_health
	health_bar.value = current_health
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
		if not Global.seen_melee_tutorial:
			Global.seen_melee_tutorial = true
			show_tutorial_message("TUTORIAL: Left Click to attack. The red box shows your close-range reach.", 5.0)
			show_range_visual("melee")
	elif weapon_name == "Pistol": 
		current_weapon_prefix = "gun_"
		if not Global.seen_gun_tutorial:
			Global.seen_gun_tutorial = true
			show_tutorial_message("TUTORIAL: Left Click to shoot. The red line shows your bullet path.", 5.0)
			show_range_visual("gun")
	else:
		current_weapon_prefix = ""
	update_hud()
		
func _on_armor_equipped(armor_name: String) -> void:
	if armor_name == "Kevlar Vest": 
		current_armor_prefix = "armor_"
		current_armor = max_armor
		armor_bar.max_value = max_armor
		armor_bar.value = current_armor
		armor_bar.show()
	else:
		current_armor_prefix = ""
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
	
	if tutorial_step > 0:
		handle_tutorial()
		
	handle_movement(delta)
	handle_animation()
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return 
		
	if event.is_action_pressed("attack") and not is_attacking:
		attack()
		
	if event.is_action_pressed("reload"):
		reload()
		
	if event.is_action_pressed("toggle_flashlight"):
		if GlobalInventory.has_item("Flashlight"):
			if has_node("FlashlightPivot/Flashlight"):
				$FlashlightPivot/Flashlight.visible = not $FlashlightPivot/Flashlight.visible

func attack() -> void:
	if current_weapon_prefix == "" or is_reloading:
		return
		
	if current_weapon_prefix == "gun_" and current_ammo <= 0:
		reload()
		return
		
	is_attacking = true
	var attack_anim_name = current_armor_prefix + current_weapon_prefix + "attack"
	anim.play(attack_anim_name)
	perform_attack()
	
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

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
	var final_anim = current_armor_prefix + current_weapon_prefix
	
	if input_dir == Vector2.ZERO:
		anim.play(final_anim + "idle")
	else:
		anim.play(final_anim + "walk")
		
	var mouse_pos = get_global_mouse_position()
	var aim_direction = global_position.direction_to(mouse_pos)
	var aim_angle = aim_direction.angle() - (PI / 2.0)
	
	anim.rotation = aim_angle
	if has_node("WeaponArea"):
		$WeaponArea.rotation = aim_angle
	if has_node("FlashlightPivot"):
		$FlashlightPivot.rotation = aim_angle
		
	if gun_raycast:
		gun_raycast.target_position = to_local(mouse_pos)

func perform_attack() -> void:
	if current_weapon_prefix == "knife_":
		print("--- SWINGING KNIFE ---")
		if enemies_in_range.is_empty():
			print("Swung at the air!")
		for enemy in enemies_in_range:
			print("Stabbed an enemy!")
			enemy.take_damage(25)
			
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
			
		if current_ammo <= 0:
			reload()

func take_damage(damage_amount: int) -> void:
	if current_armor > 0:
		current_armor -= damage_amount
		if current_armor < 0:
			var spillover_damage = abs(current_armor) 
			current_armor = 0
			current_health -= spillover_damage 
			print("Armor broke! Player took ", spillover_damage, " spillover damage.")
			break_armor() 
		else:
			print("Armor absorbed the hit! Armor remaining: ", current_armor)
		armor_bar.value = current_armor
	else:
		current_health -= damage_amount
		print("Ouch! Player took ", damage_amount, " damage. Health remaining: ", current_health)
		
	health_bar.value = current_health
	
	if current_health <= 0:
		die()

func break_armor() -> void:
	print("The Kevlar Vest was destroyed!")
	GlobalInventory.equipped_armor = ""
	GlobalInventory.armor_equipped.emit("")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO 
	
	print("The Player has died!")
	GlobalInventory.equipped_weapon = ""
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("WeaponArea"):
		$WeaponArea.queue_free()
	
	z_index = 0
	health_bar.hide()
	anim.play("death")
	death_screen.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_animated_sprite_2d_animation_finished() -> void:
	if "attack" in anim.animation:
		is_attacking = false

func _on_weapon_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		enemies_in_range.append(body)

func _on_weapon_area_body_exited(body: Node2D) -> void:
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		
func _on_continue_button_pressed() -> void:
	print("Restarting from checkpoint...")
	GlobalInventory.restore_from_checkpoint()
	Global.restore_events() 
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	print("Going back to Main Menu...")
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _on_inventory_changed() -> void:
	if not GlobalInventory.has_item("Flashlight"):
		if has_node("FlashlightPivot/Flashlight") and $FlashlightPivot/Flashlight.visible == true:
			$FlashlightPivot/Flashlight.visible = false
			if has_node("AuraLight"):
				$AuraLight.visible = true
				
func update_hud() -> void:
	health_bar.value = current_health
	armor_bar.value = current_armor
	
	if GlobalInventory.equipped_weapon != "":
		var icon_path = ""
		for i in range(GlobalInventory.MAX_SLOTS):
			var item = GlobalInventory.items[i]
			if item != null and item["name"] == GlobalInventory.equipped_weapon:
				icon_path = item["icon"]
				break 
				
		if icon_path != "":
			weapon_icon.texture = load(icon_path)
			weapon_icon.show()
		
		if GlobalInventory.equipped_weapon == "Pistol":
			weapon_label.text = "Equipped: Pistol | Ammo: " + str(current_ammo) + "/" + str(max_ammo)
		else:
			weapon_label.text = "Equipped: " + GlobalInventory.equipped_weapon
			
		weapon_label.show()
	else:
		weapon_label.hide()
		weapon_icon.hide()

func reload() -> void:
	if is_reloading or current_ammo == max_ammo or current_weapon_prefix != "gun_":
		return
	is_reloading = true
	print("Reloading...")
	if weapon_label:
		weapon_label.text = "Equipped: Pistol | Ammo: Reloading..."
	await get_tree().create_timer(reload_time).timeout
	current_ammo = max_ammo
	is_reloading = false
	print("Reload complete!")
	update_hud()
	
func setup_tutorial_label() -> void:
	if not is_instance_valid(tutorial_label):
		tutorial_label = Label.new()
		tutorial_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tutorial_label.add_theme_font_size_override("font_size", 30)
		tutorial_label.add_theme_color_override("font_outline_color", Color.BLACK)
		tutorial_label.add_theme_constant_override("outline_size", 4)
		$UI.add_child(tutorial_label)
		tutorial_label.position.y = 100

func start_movement_tutorial() -> void:
	tutorial_step = 1
	setup_tutorial_label()
	tutorial_label.text = "TUTORIAL: Use [W, A, S, D] to move."
	tutorial_label.show()

func handle_tutorial() -> void:
	if tutorial_step == 1:
		if input_dir != Vector2.ZERO:
			tutorial_step = 2
			tutorial_label.text = "TUTORIAL: Move your mouse around to aim your flashlight."
			initial_mouse_pos = get_viewport().get_mouse_position()
	elif tutorial_step == 2:
		if get_viewport().get_mouse_position().distance_to(initial_mouse_pos) > 150:
			tutorial_step = 0 
			show_tutorial_message("TUTORIAL: Explore the facility. Find items and notes.", 4.0)

func show_tutorial_message(message: String, duration: float) -> void:
	setup_tutorial_label()
	tutorial_label.text = message
	tutorial_label.show()
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(tutorial_label) and tutorial_label.text == message:
		tutorial_label.hide()
		
func show_range_visual(weapon_type: String) -> void:
	if weapon_type == "melee" and has_node("WeaponArea/CollisionShape2D"):
		var visual = Polygon2D.new()
		visual.color = Color(1.0, 0.0, 0.0, 0.3) 
		
		var col_node = $WeaponArea/CollisionShape2D
		var rect_shape = col_node.shape as RectangleShape2D
		
		if rect_shape:
			var extents = rect_shape.size / 2.0
			var center = col_node.position
			
			visual.polygon = PackedVector2Array([
				Vector2(center.x - extents.x, center.y - extents.y), 
				Vector2(center.x + extents.x, center.y - extents.y), 
				Vector2(center.x + extents.x, center.y + extents.y), 
				Vector2(center.x - extents.x, center.y + extents.y)  
			])
		
		$WeaponArea.add_child(visual)
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(visual):
			visual.queue_free()
			
	elif weapon_type == "gun" and has_node("FlashlightPivot"):
		var visual = Line2D.new()
		visual.default_color = Color(1.0, 0.0, 0.0, 0.5) 
		visual.width = 4.0
		visual.add_point(Vector2(0, 0))
		visual.add_point(Vector2(0, 600)) 
		
		$FlashlightPivot.add_child(visual)
		await get_tree().create_timer(5.0).timeout
		if is_instance_valid(visual):
			visual.queue_free()
			

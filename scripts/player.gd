extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -320.0
const MIN_JUMP_VELOCITY = -160.0
const DASH_SPEED = 400.0
const DASH_DURATION = 0.2
var jump_count = 0
var max_jumps = 2
const LASER_SCENE = preload("res://laser.tscn")
var last_safe_position: Vector2
var safe_position_timer: float = 0.0

# Laser cooldown variables
var can_shoot = true
var laser_cooldown_time = 0.3  # 0.3 seconds between shots
var laser_cooldown_timer = 0.0

# Dash variables
var is_dashing = false
var dash_direction = Vector2.ZERO
var dash_timer = 0.0
var dash_count = 0  # Track air dashes
var max_air_dashes = 1  # Allow 1 dash in air

# Groundpound variables
var is_actively_groundpounding = false  # Track if currently in groundpound state
var is_ground_pounding = false
var ground_pound_velocity = 800.0  # How fast you slam down
var ground_pound_damage_radius = 80.0  # Radius for damaging enemies
var can_ground_pound = true  # Cooldown prevention

# Groundpound bounce settings
var bounce_velocity = -400.0  # How high you bounce (negative = up)
var bounce_gives_jump = true  # Whether bounce resets jump count
var bounce_gives_dash = true  # Whether bounce resets dash count

# Health system
var max_health = 3
var current_health = 3
var is_invulnerable = false
var invulnerability_time = 1.0

# Ability flags for robot parts
var has_leg_servos = false  # Controls jumping
var has_arm_cannon = false  # Controls shooting
var has_jump_boosters = false  # Controls double jump
var has_dash_thrusters = false  # Controls dash ability
var has_ground_slam = false  # Controls groundpound ability

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_ui = get_node("../CanvasLayer/HealthUI")

func _ready():
	# Add player to group so GameManager can find it
	add_to_group("player")
	
	# Get persistent state from GameManager
	GameManager.apply_to_player(self)
	
	
	GameManager.position_player_at_spawn()
	
	# Make sure health UI is updated with correct max health after a brief delay
	# (ensures the UI is fully initialized)
	await get_tree().process_frame
	if health_ui:
		health_ui.update_health(current_health, max_health)

func _physics_process(delta: float) -> void:
	# Handle laser cooldown timer
	if not can_shoot:
		laser_cooldown_timer -= delta
		if laser_cooldown_timer <= 0:
			can_shoot = true
			laser_cooldown_timer = 0.0
	
	# Handle dash first - overrides normal movement
	if is_dashing:
		handle_dash(delta)
		move_and_slide()
		return
	
	# Handle ground pound - overrides normal movement when active
	if is_ground_pounding:
		handle_ground_pound(delta)
		move_and_slide()
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Reset jump count when on ground
		jump_count = 0
		# Reset dash count when on ground
		dash_count = 0
		
		# Track safe positions when on ground - but avoid moving platforms
		var on_moving_platform = false
		
		# Check if we're on a moving platform (AnimatableBody2D)
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Check if it's an AnimatableBody2D (moving platforms)
			if collider is AnimatableBody2D:
				on_moving_platform = true
				break
		
		# Only update safe position if NOT on a moving platform
		if not on_moving_platform:
			safe_position_timer += delta
			if safe_position_timer > 0.5:
				last_safe_position = global_position
				safe_position_timer = 0.0
	
	# Handle jump - GATED BY LEG SERVOS
	if Input.is_action_just_pressed("ui_up") and has_leg_servos:
		var allowed_jumps = 1
		if has_jump_boosters:
			allowed_jumps = max_jumps
			
		if jump_count < allowed_jumps:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
	
	# Cut jump short if button is released early
	if Input.is_action_just_released("ui_up") and velocity.y < 0:
		if velocity.y < MIN_JUMP_VELOCITY:
			velocity.y = MIN_JUMP_VELOCITY
	
	# Handle dash - GATED BY DASH THRUSTERS
	if Input.is_action_just_pressed("ui_cancel") and has_dash_thrusters and not is_dashing:
		# Allow dash if on ground OR if we haven't used our air dash yet
		if is_on_floor() or dash_count < max_air_dashes:
			start_dash()
	
	# Handle ground pound input - GATED BY GROUND SLAM
	if Input.is_action_just_pressed("ui_down") and has_ground_slam and can_ground_pound:
		# Only allow ground pound when in air
		if not is_on_floor():
			start_ground_pound()
	
	# Add shooting - GATED BY ARM CANNON AND COOLDOWN
	if Input.is_action_just_pressed("ui_accept") and has_arm_cannon and can_shoot:
		shoot_laser()
	
	# Check for enemy collision
	check_enemy_collision()
	
	
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	if direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func shoot_laser():
	if not can_shoot:
		return
		
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	
	# Adjust spawn position based on facing direction
	var spawn_offset = Vector2(10, -10)  # Default offset for facing right
	if animated_sprite.flip_h:  # Facing left
		spawn_offset.x = -10  # Move spawn point to the left side
	
	laser.position = global_position + spawn_offset
	
	if animated_sprite.flip_h:
		laser.direction = Vector2.LEFT
	else:
		laser.direction = Vector2.RIGHT
	
	# Start cooldown
	can_shoot = false
	laser_cooldown_timer = laser_cooldown_time

func check_enemy_collision():
	if is_invulnerable:
		return
		
	# Check if we're colliding with any enemies
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we hit an enemy and we're not invulnerable
		if collider and collider.has_method("take_damage") and not is_invulnerable:
			
			# SPECIAL HANDLING FOR SAWS (or any object with "saw" in the name)
			if "saw" in collider.name.to_lower() or collider.is_in_group("saw"):
				handle_saw_collision(collider)
			else:
				# Normal enemy collision
				take_damage()
			break

# NEW: Special handling for saw collisions
func handle_saw_collision(saw):
	print("=== PLAYER HIT SAW ===")
	
	# If we're actively ground pounding, let the saw handle the bounce
	if is_actively_groundpounding:
		if saw.has_method("bounce_player"):
			saw.bounce_player(self)
		return
	
	# Apply saw-specific effects BEFORE taking damage
	apply_saw_plummet_effect()
	
	# Then apply normal damage
	take_damage()

# NEW: Apply the plummet effect from hitting a saw
func apply_saw_plummet_effect():
	print("=== APPLYING SAW PLUMMET ===")
	
	# Cancel any current abilities
	if is_dashing:
		end_dash()
	
	if is_ground_pounding:
		is_ground_pounding = false
		is_actively_groundpounding = false
		animated_sprite.modulate = Color.WHITE
	
	# Reset air abilities so player can't recover
	jump_count = max_jumps  # Use up all jumps
	dash_count = max_air_dashes  # Use up all dashes
	
	# Apply rapid downward velocity (like ground pound)
	velocity.x = 0  # Stop horizontal movement
	velocity.y = 150.0 # Use ground pound speed
	
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	# Tween back to normal color
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.5)
	
	print("Saw plummet applied - velocity set to:", velocity)

func take_damage():
	if is_invulnerable:
		return
		
	# Use GameManager for health tracking
	current_health = GameManager.take_damage()
	current_health = GameManager.current_health  # Sync local value
	is_invulnerable = true
	
	# Remove layer 3 (Enemies) from player's collision mask so you can walk through them
	collision_mask = collision_mask & ~(1 << 2)
	
	# Update UI
	if health_ui:
		health_ui.update_health(current_health)
	
	# Visual feedback
	animated_sprite.modulate = Color(1, 1, 1, 0.5)
	
	if current_health <= 0:
		game_over()
	else:
		await get_tree().create_timer(invulnerability_time).timeout
		is_invulnerable = false
		collision_mask = collision_mask | (1 << 2)
		animated_sprite.modulate = Color.WHITE

func game_over():
	print("Game Over!")
	GameManager.show_game_over()

func respawn_from_fall():
	current_health = GameManager.take_damage()
	current_health = GameManager.current_health
	
	if health_ui:
		health_ui.update_health(current_health)
		 
	if current_health <= 0:
		game_over()
	else:
		if last_safe_position != Vector2.ZERO:
			global_position = last_safe_position
		else:
			global_position = Vector2(100, 100)
		
		velocity = Vector2.ZERO

# Functions to unlock abilities when body parts are collected
func unlock_leg_servos():
	has_leg_servos = true
	GameManager.unlock_ability("leg_servos")  # Save to GameManager

func unlock_arm_cannon():
	has_arm_cannon = true
	GameManager.unlock_ability("arm_cannon")  # Save to GameManager

func unlock_jump_boosters():
	has_jump_boosters = true
	GameManager.unlock_ability("jump_boosters")  # Save to GameManager

func unlock_dash_thrusters():
	has_dash_thrusters = true
	GameManager.unlock_ability("dash_thrusters")  # Save to GameManager

func unlock_ground_slam():
	has_ground_slam = true
	GameManager.unlock_ability("ground_slam")  # Save to GameManager

func increase_max_health():
	# Increase max health by 1 and fully heal
	max_health += 1
	current_health = max_health
	
	# Update GameManager
	GameManager.max_health = max_health
	GameManager.current_health = current_health
	
	# Update UI with new max health
	if health_ui:
		health_ui.update_health(current_health, max_health)

func start_dash():
	if is_dashing:
		return
	
	# Count the dash if we're in the air
	if not is_on_floor():
		dash_count += 1
		
	# Determine dash direction based on player facing or input
	var direction = Vector2.ZERO
	var input_dir = Input.get_axis("ui_left", "ui_right")
	
	if input_dir != 0:
		direction.x = input_dir
	else:
		# Dash in facing direction if no input
		direction.x = -1 if animated_sprite.flip_h else 1
	
	# Start the dash
	is_dashing = true
	dash_direction = direction
	dash_timer = DASH_DURATION
	
	# Set dash velocity
	velocity.x = dash_direction.x * DASH_SPEED
	velocity.y = 0  # Cancel gravity during dash
	
	# Visual feedback
	animated_sprite.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent

func handle_dash(delta):
	dash_timer -= delta
	
	# Maintain dash velocity
	velocity.x = dash_direction.x * DASH_SPEED
	velocity.y = 0  # No gravity during dash
	
	if dash_timer <= 0:
		end_dash()

func end_dash():
	is_dashing = false
	dash_timer = 0.0
	
	# Restore normal appearance
	animated_sprite.modulate = Color.WHITE
	
	# Allow normal physics to resume

func start_ground_pound():
	if is_ground_pounding:
		return
	
	is_ground_pounding = true
	is_actively_groundpounding = true
	can_ground_pound = false
	
	# Set downward velocity
	velocity.x = 0  # Stop horizontal movement
	velocity.y = ground_pound_velocity  # Fast downward movement
	
	# Visual feedback
	animated_sprite.modulate = Color.YELLOW  # Make player flash yellow

func handle_ground_pound(_delta):
	# Maintain fast downward velocity
	velocity.x = 0
	velocity.y = ground_pound_velocity
	
	# Check if we hit the ground
	if is_on_floor():
		end_ground_pound()

func end_ground_pound():
	if not is_ground_pounding:
		return
		
	is_ground_pounding = false
	is_actively_groundpounding = false
	
	# Check for bouncy objects before doing damage/effects
	var bounced = check_for_bounce()
	
	if not bounced:
		# Normal ground pound - damage enemies and reset velocity
		damage_enemies_in_radius()
		velocity = Vector2.ZERO
	
	# Restore normal appearance
	animated_sprite.modulate = Color.WHITE
	
	# Start cooldown
	await get_tree().create_timer(0.5).timeout  # Half second cooldown
	can_ground_pound = true

func check_for_bounce() -> bool:
	# Check what we're colliding with
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if the object is bouncy (has bounce method or is in bounce group)
		if collider.has_method("bounce_player") or collider.is_in_group("bouncy"):
			# Call bounce method if it exists (for custom bounce behavior)
			if collider.has_method("bounce_player"):
				collider.bounce_player(self)
			
			# Apply bounce physics
			velocity.y = bounce_velocity  # Launch upward
			velocity.x *= 0.7  # Reduce horizontal momentum slightly
			
			# Reset abilities if enabled
			if bounce_gives_jump:
				jump_count = 0  # Reset jump count
			
			if bounce_gives_dash:
				dash_count = 0  # Reset dash count
			
			# Optional: Damage enemies even when bouncing
			damage_enemies_in_radius()
			
			return true
	
	return false

func damage_enemies_in_radius():
	# Get all bodies in the game
	var space_state = get_world_2d().direct_space_state
	
	# Create a circle area to check for enemies
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = ground_pound_damage_radius
	query.shape = circle_shape
	query.transform.origin = global_position
	query.collision_mask = 4  # Layer 3 (enemies)
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var enemy = result["collider"]
		if enemy and enemy.has_method("take_damage"):
			# Check if enemy is roughly at the same vertical level
			var vertical_distance = abs(enemy.global_position.y - global_position.y)
			var max_vertical_distance = 30.0  # Adjust this value as needed
			
			if vertical_distance <= max_vertical_distance:
				# Check if it's a bouncy platform (no damage argument needed)
				if enemy.is_in_group("bouncy"):
					enemy.take_damage()  # No arguments for bouncy platforms
				else:
					enemy.take_damage(2)  # 2 damage for regular enemies

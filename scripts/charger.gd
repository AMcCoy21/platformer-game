extends CharacterBody2D

# Movement properties
const PATROL_SPEED = 40.0
const CHARGE_SPEED = 200.0
const DETECTION_RANGE = 120.0
const CHARGE_DURATION = 1.5  # How long the charge lasts
const CHARGE_COOLDOWN = 2.0  # Time between charges
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

# Patrol behavior
var patrol_direction = 1
var is_charging = false
var charge_timer = 0.0
var charge_cooldown_timer = 0.0
var can_charge = true

# Charge warning system
var is_warning = false
var warning_timer = 0.0
var warning_duration = 0.3  # Short pause before charging
var warning_blink_speed = 8.0  # How fast to blink

# Player tracking
var player_ref = null
var charge_target_direction = 0

# Health system
var max_health = 2
var current_health = 2
var is_taking_damage = false
var damage_flash_duration = 0.2

# Wall and edge detection
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray_right: RayCast2D = get_node_or_null("WallRayRight")
@onready var wall_ray_left: RayCast2D = get_node_or_null("WallRayLeft")
@onready var edge_ray_right: RayCast2D = get_node_or_null("EdgeRayRight")
@onready var edge_ray_left: RayCast2D = get_node_or_null("EdgeRayLeft")

func _ready():
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Add to enemies group
	add_to_group("enemies")
	
	# Setup edge detection rays if they exist
	setup_edge_detection()
	
	print("Charging enemy spawned")

func setup_edge_detection():
	# Make sure edge rays are configured correctly
	if edge_ray_right:
		edge_ray_right.enabled = true
		edge_ray_right.collision_mask = 1  # Check against ground layer (layer 1)
		# Position it at the front-right edge of the enemy
		edge_ray_right.position = Vector2(10, 10)  # Adjust based on your enemy size
		# Make it point downward to detect ground
		edge_ray_right.target_position = Vector2(0, 20)  # Point down 20 pixels
		print("Edge ray right configured: ", edge_ray_right.position, " -> ", edge_ray_right.target_position)
	
	if edge_ray_left:
		edge_ray_left.enabled = true
		edge_ray_left.collision_mask = 1  # Check against ground layer (layer 1)
		# Position it at the front-left edge of the enemy
		edge_ray_left.position = Vector2(-10, 10)  # Adjust based on your enemy size
		# Make it point downward to detect ground
		edge_ray_left.target_position = Vector2(0, 20)  # Point down 20 pixels
		print("Edge ray left configured: ", edge_ray_left.position, " -> ", edge_ray_left.target_position)
	
	# Setup wall detection rays
	if wall_ray_right:
		wall_ray_right.enabled = true
		wall_ray_right.collision_mask = 1  # Check against ground layer (layer 1)
		wall_ray_right.position = Vector2(0, 0)
		wall_ray_right.target_position = Vector2(15, 0)  # Point right
	
	if wall_ray_left:
		wall_ray_left.enabled = true
		wall_ray_left.collision_mask = 1  # Check against ground layer (layer 1)
		wall_ray_left.position = Vector2(0, 0)
		wall_ray_left.target_position = Vector2(-15, 0)  # Point left

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if player_ref and player_ref.is_invulnerable:
		collision_mask = collision_mask & ~(1 << 1)  # Remove layer 2 (Player)
	else:
		collision_mask = collision_mask | (1 << 1)   # Add layer 2 (Player) back
	
	# Handle charge cooldown
	if not can_charge:
		charge_cooldown_timer -= delta
		if charge_cooldown_timer <= 0:
			can_charge = true
			print("Charging enemy ready to charge again!")
	
	# Handle charging behavior
	if is_warning:
		handle_warning(delta)
	elif is_charging:
		handle_charging(delta)
	else:
		# Check if we should start charging
		if should_charge_at_player():
			start_warning()
		else:
			# Normal patrol behavior
			patrol(delta)
	
	move_and_slide()

func should_charge_at_player():
	if not player_ref or not can_charge:
		return false
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Only charge if player is within range and on the same vertical level
	if distance_to_player <= DETECTION_RANGE:
		var height_difference = abs(global_position.y - player_ref.global_position.y)
		# Much stricter height requirement - must be very close to same level
		if height_difference < 20:  # Very tight vertical tolerance
			# IMPORTANT: Check if charging would lead to an edge before starting
			var charge_direction = 1 if player_ref.global_position.x > global_position.x else -1
			if not is_edge_ahead(charge_direction):
				return true
			else:
				print("Would charge off edge - canceling charge!")
	
	return false

func start_warning():
	print("Charging enemy warning - about to charge!")
	is_warning = true
	warning_timer = warning_duration
	
	# Stop moving during warning
	velocity.x = 0
	
	# Determine charge direction toward player for sprite facing
	if player_ref.global_position.x > global_position.x:
		charge_target_direction = 1
		animated_sprite.flip_h = false
	else:
		charge_target_direction = -1
		animated_sprite.flip_h = true

func handle_warning(delta: float):
	warning_timer -= delta
	
	# Blink red effect
	var blink_alpha = (sin(warning_timer * warning_blink_speed * PI) + 1.0) * 0.5
	animated_sprite.modulate = Color(1.0, blink_alpha, blink_alpha)
	
	# Stay still during warning
	velocity.x = 0
	
	# When warning time is up, start the actual charge
	if warning_timer <= 0:
		start_charge()

func start_charge():
	print("Charging enemy starting charge at player!")
	is_warning = false  # End warning state
	is_charging = true
	charge_timer = CHARGE_DURATION
	can_charge = false
	charge_cooldown_timer = CHARGE_COOLDOWN
	
	# Charge direction should already be set from warning phase
	# Visual feedback - bright red during charge
	animated_sprite.modulate = Color(1.5, 0.5, 0.5)  # Bright red tint

func handle_charging(delta: float):
	charge_timer -= delta
	
	# Check for obstacles BEFORE moving
	if is_wall_ahead(charge_target_direction):
		print("Charging enemy hit wall, stopping charge!")
		stop_charge()
		return
	
	if is_edge_ahead(charge_target_direction):
		print("Charging enemy reached edge, stopping charge!")
		stop_charge()
		return
	
	# Charge at high speed
	velocity.x = charge_target_direction * CHARGE_SPEED
	
	# Additional damage check during charge - check proximity to player
	check_charge_damage()
	
	# End charge when timer runs out
	if charge_timer <= 0:
		print("Charging enemy charge finished!")
		stop_charge()

func stop_charge():
	is_charging = false
	is_warning = false  # Make sure warning state is also cleared
	charge_timer = 0.0
	warning_timer = 0.0  # Reset warning timer
	
	# Restore normal appearance
	animated_sprite.modulate = Color.WHITE
	
	# Update patrol direction to match the direction we were charging
	patrol_direction = charge_target_direction
	
	# Make sure sprite faces the correct direction
	if patrol_direction == 1:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
	
	# Brief pause after charge
	velocity.x = 0

func patrol(_delta: float):
	# Check for walls and edges BEFORE moving
	if is_wall_ahead(patrol_direction) or is_edge_ahead(patrol_direction):
		patrol_direction *= -1  # Turn around
		
		# Face the new direction
		if patrol_direction == 1:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
		
		print("Patrol direction changed to: ", patrol_direction)
	
	# Move at patrol speed
	velocity.x = patrol_direction * PATROL_SPEED

func is_wall_ahead(direction: int) -> bool:
	if direction == 1 and wall_ray_right:
		var is_colliding = wall_ray_right.is_colliding()
		if is_colliding:
			print("Wall detected ahead (right)")
		return is_colliding
	elif direction == -1 and wall_ray_left:
		var is_colliding = wall_ray_left.is_colliding()
		if is_colliding:
			print("Wall detected ahead (left)")
		return is_colliding
	return false

func is_edge_ahead(direction: int) -> bool:
	# An edge is detected when the ray is NOT colliding with ground
	if direction == 1 and edge_ray_right:
		var no_ground = not edge_ray_right.is_colliding()
		if no_ground:
			print("Edge detected ahead (right) - no ground found")
		return no_ground
	elif direction == -1 and edge_ray_left:
		var no_ground = not edge_ray_left.is_colliding()
		if no_ground:
			print("Edge detected ahead (left) - no ground found")
		return no_ground
	
	print("No edge ray available for direction: ", direction)
	return false  # If no ray exists, assume no edge (safe default)

# Additional damage check for charging - handles fast movement collision issues
func check_charge_damage():
	if not player_ref:
		return
		
	# Check if we're very close to the player during charge
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# If we're very close (within collision range), deal damage
	if distance_to_player < 15:  # Slightly larger than typical collision shape
		if player_ref.has_method("take_damage") and not ("is_invulnerable" in player_ref and player_ref.is_invulnerable):
			player_ref.take_damage()
			print("Charging enemy dealt damage during charge!")
			# Stop the charge after hitting the player
			stop_charge()

func take_damage():
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	# Invulnerable while charging
	if is_charging:
		print("Charging enemy is invulnerable while charging!")
		return
	
	current_health -= 1
	is_taking_damage = true
	
	# Stop warning if we get hit during warning phase
	if is_warning:
		stop_charge()
	
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	# Knockback effect
	velocity.x *= 0.3
	
	if current_health <= 0:
		die()
	else:
		# Flash effect and brief invulnerability
		await get_tree().create_timer(damage_flash_duration).timeout
		animated_sprite.modulate = Color.WHITE
		is_taking_damage = false 

# Add this function to any enemy script
func spawn_health_pickup():
	var health_pickup = HEALTH_PICKUP_SCENE.instantiate()
	get_parent().add_child(health_pickup)
	
	# Set the start position directly on the pickup before it runs _ready()
	var spawn_position = global_position + Vector2(0, 8)  # 8 pixels lower
	health_pickup.start_position = spawn_position
	health_pickup.global_position = spawn_position
	
	print("Health pickup spawned at enemy death location")

func die():
	spawn_health_pickup()
	queue_free()

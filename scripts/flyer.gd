extends CharacterBody2D

# Movement properties
const SPEED = 100.0
const DIRECTION_CHANGE_TIME = 2.0  # Change direction every 2 seconds
const SPEED_VARIATION = 0.0  # Random speed variation
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

# NEW: Boundary limits to prevent flying off screen
const MAX_DISTANCE_FROM_SPAWN = 400.0  # Maximum distance from spawn point
var spawn_position: Vector2

# Random movement
var current_direction = Vector2.ZERO
var direction_timer = 0.0
var current_speed = SPEED

# Health system
var max_health = 1
var current_health = 1
var is_taking_damage = false
var damage_flash_duration = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Add to enemies group so player can detect collision
	add_to_group("enemies")
	
	# Remember spawn position
	spawn_position = global_position
	
	# Start with a random direction
	choose_random_direction()
	
	print("Random flying enemy spawned")

func _physics_process(delta: float) -> void:
	# Update direction timer
	direction_timer -= delta
	
	# Change direction randomly
	if direction_timer <= 0:
		choose_random_direction()
		direction_timer = DIRECTION_CHANGE_TIME + randf_range(-0.5, 0.5)  # Add some randomness
	
	# NEW: Check if we're too far from spawn point
	check_boundaries()
	
	# Apply random movement
	velocity = current_direction * current_speed
	
	# Face the direction we're moving
	if current_direction.x > 0:
		animated_sprite.flip_h = false
	elif current_direction.x < 0:
		animated_sprite.flip_h = true
	
	move_and_slide()
	
	# Check for wall collisions and bounce
	handle_wall_bouncing()

func choose_random_direction():
	# Generate completely random direction
	var angle = randf() * 2 * PI  # Random angle in radians
	current_direction = Vector2(cos(angle), sin(angle))
	
	# Randomize speed slightly
	current_speed = SPEED + randf_range(-SPEED_VARIATION, SPEED_VARIATION)

# NEW: Check if enemy is getting too far away and redirect if needed
func check_boundaries():
	var distance_from_spawn = global_position.distance_to(spawn_position)
	
	if distance_from_spawn > MAX_DISTANCE_FROM_SPAWN:
		# Force direction back toward spawn point
		var direction_to_spawn = (spawn_position - global_position).normalized()
		
		# Add some randomness to avoid just going straight back
		var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		current_direction = (direction_to_spawn + random_offset).normalized()
		
		# Reset timer so we don't immediately change direction again
		direction_timer = DIRECTION_CHANGE_TIME
		
		print("Flying enemy too far from spawn, redirecting toward home")

func handle_wall_bouncing():
	# Check if we hit any walls and bounce off them
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Skip if we hit the player (don't bounce off player)
			if collider and collider.is_in_group("player"):
				continue
				
			# Get the collision normal (direction of the wall)
			var collision_normal = collision.get_normal()
			
			# Instead of predictable bounce, choose a more random direction
			# Start with the bounce direction but add lots of randomness
			var bounce_direction = current_direction.bounce(collision_normal)
			
			# Add random variation (±90 degrees of randomness)
			var random_angle = randf_range(-PI/2, PI/2)  # ±90 degrees
			var random_rotation = Transform2D().rotated(random_angle)
			current_direction = random_rotation * bounce_direction
			
			# Alternative: Completely random direction away from wall
			# Uncomment this if you want even more chaos:
			# var away_from_wall = -collision_normal
			# var random_spread_angle = randf_range(-PI/3, PI/3)  # ±60 degrees
			# var spread_rotation = Transform2D().rotated(random_spread_angle)
			# current_direction = spread_rotation * away_from_wall
			
			# Reset direction timer so we don't immediately change direction again
			direction_timer = DIRECTION_CHANGE_TIME
			break  # Only handle the first collision

func take_damage():
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	current_health -= 1
	is_taking_damage = true
	
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	if current_health <= 0:
		die()
	else:
		# Flash effect and brief invulnerability
		await get_tree().create_timer(damage_flash_duration).timeout
		animated_sprite.modulate = Color.WHITE
		is_taking_damage = false

func spawn_health_pickup():
	var health_pickup = HEALTH_PICKUP_SCENE.instantiate()
	get_parent().add_child(health_pickup)
	
	# Set the start position directly on the pickup before it runs _ready()
	var spawn_position_pickup = global_position + Vector2(0, 8)  # 20 pixels lower
	health_pickup.start_position = spawn_position_pickup
	health_pickup.global_position = spawn_position_pickup
	
	print("Health pickup spawned at enemy death location")

func die():
	spawn_health_pickup()
	queue_free()

extends CharacterBody2D

const LASER_SCENE = preload("res://laser.tscn")
const PATROL_SPEED = 50.0
const CHASE_SPEED = 50.0
const DETECTION_RANGE = 150  # When to start chasing
const SHOOT_RANGE = 150
const SHOOT_COOLDOWN = 1.5
const DETECTION_COOLDOWN = 1.0  # NEW: Delay before first shot after detecting player
const PATROL_DISTANCE = 100  # How far to patrol left/right
const MIN_CHASE_HEIGHT = 50  # Minimum distance to stay above player
const ENEMY_LASER_SPEED = 200  # Faster than turrets, slower than player
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

var player_ref = null
var can_shoot = true
var shoot_timer = 0.0
var is_chasing = false
var just_detected_player = false  # NEW: Track if we just started chasing
var detection_timer = 0.0  # NEW: Timer for detection cooldown

# Patrol variables
var patrol_center: Vector2
var patrol_direction = 1  # 1 for right, -1 for left
var left_patrol_point: Vector2
var right_patrol_point: Vector2

# Health system
var max_health = 2
var current_health = 2
var is_taking_damage = false
var damage_flash_duration = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var laser_spawn_point_right: Marker2D = get_node_or_null("LaserSpawnPointRight")
@onready var laser_spawn_point_left: Marker2D = get_node_or_null("LaserSpawnPointLeft")

func _ready():
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Set up patrol area based on starting position
	patrol_center = global_position
	left_patrol_point = patrol_center + Vector2(-PATROL_DISTANCE, 0)
	right_patrol_point = patrol_center + Vector2(PATROL_DISTANCE, 0)
	
	# Debug laser spawn points
	if laser_spawn_point_right:
		print("Right laser spawn point found at: ", laser_spawn_point_right.position)
	else:
		print("WARNING: LaserSpawnPointRight not found!")
	
	if laser_spawn_point_left:
		print("Left laser spawn point found at: ", laser_spawn_point_left.position)
	else:
		print("WARNING: LaserSpawnPointLeft not found!")

func _physics_process(delta: float) -> void:
	# Flying drones don't use gravity - they hover
	
	# Handle shoot cooldown
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	# Handle detection cooldown
	if just_detected_player:
		detection_timer -= delta
		if detection_timer <= 0:
			just_detected_player = false
	
	# Check if we should chase or patrol
	check_for_player()
	
	# Move based on current behavior
	if is_chasing and player_ref:
		chase_player()
	else:
		patrol()
	
	# Check for shooting opportunity (but not if we just detected the player)
	if player_ref and can_shoot and not just_detected_player:
		check_and_shoot_at_player()
	
	# Apply movement
	move_and_slide()

func check_for_player():
	if not player_ref:
		is_chasing = false
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Start chasing if player comes within detection range
	if distance_to_player <= DETECTION_RANGE and not is_chasing:
		is_chasing = true
		just_detected_player = true  # NEW: Start detection cooldown
		detection_timer = DETECTION_COOLDOWN
		print("Enemy detected player - starting detection cooldown")
	# Stop chasing if player gets too far (with buffer to prevent flickering)
	elif distance_to_player > DETECTION_RANGE * 1.3:
		is_chasing = false
		just_detected_player = false  # NEW: Reset detection state

func chase_player():
	# Move toward player in both X and Y directions, but with height limits
	var direction_to_player = player_ref.global_position - global_position
	
	# Horizontal movement
	if abs(direction_to_player.x) > 10:  # Dead zone to prevent jittering
		if direction_to_player.x > 0:
			velocity.x = CHASE_SPEED
			animated_sprite.flip_h = false
		else:
			velocity.x = -CHASE_SPEED
			animated_sprite.flip_h = true
	else:
		velocity.x = 0
	
	# Vertical movement with height restriction
	var target_y = player_ref.global_position.y - MIN_CHASE_HEIGHT  # Stay above player
	var y_difference = target_y - global_position.y
	
	if abs(y_difference) > 10:  # Dead zone to prevent jittering
		if y_difference > 0:
			velocity.y = CHASE_SPEED * 0.7  # Slower vertical movement
		else:
			velocity.y = -CHASE_SPEED * 0.7
	else:
		velocity.y = 0

func patrol():
	# Simple back and forth patrol
	
	# Check if we've reached patrol boundaries
	if global_position.x >= right_patrol_point.x:
		patrol_direction = -1  # Go left
		animated_sprite.flip_h = true
	elif global_position.x <= left_patrol_point.x:
		patrol_direction = 1   # Go right
		animated_sprite.flip_h = false
	
	# Move in patrol direction
	velocity.x = patrol_direction * PATROL_SPEED
	velocity.y = 0

func check_and_shoot_at_player():
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Check if player is in shooting range
	if distance_to_player <= SHOOT_RANGE:
		shoot_at_player()

func shoot_at_player():
	if not can_shoot:
		return
	
	# Create laser instance
	var laser = LASER_SCENE.instantiate()
	
	# Use markers again with detailed debug
	var spawn_pos = global_position
	
	if animated_sprite.flip_h:
		# Facing left
		if laser_spawn_point_left:
			spawn_pos = laser_spawn_point_left.global_position
		else:
			spawn_pos = global_position
	else:
		# Facing right
		if laser_spawn_point_right:
			spawn_pos = laser_spawn_point_right.global_position
		else:
			spawn_pos = global_position
	
	# Add to scene FIRST
	get_parent().add_child(laser)
	
	# Then set GLOBAL position (this accounts for parent offset)
	laser.global_position = spawn_pos
	
	# Mark as enemy laser and set properties
	laser.is_enemy_laser = true
	laser.speed = ENEMY_LASER_SPEED
	
	# Calculate diagonal direction to player
	var direction_to_player = (player_ref.global_position - spawn_pos).normalized()
	laser.direction = direction_to_player
	
	# Rotate laser sprite to match shooting direction
	var angle = atan2(direction_to_player.y, direction_to_player.x)
	laser.rotation = angle
	
	# SET ENEMY LASER COLLISION PROPERTIES
	laser.collision_layer = 1 << 3  # Layer 4 (bit 3)
	laser.collision_mask = (1 << 0) | (1 << 1)  # Layers 1 and 2 (walls + player)
	
	print("Fixed: Laser spawned at global_position: ", laser.global_position)
	
	# Start cooldown
	can_shoot = false
	shoot_timer = SHOOT_COOLDOWN

func take_damage():
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	current_health -= 1
	is_taking_damage = true
	
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	# Evasive maneuver when hit
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity += random_direction * CHASE_SPEED * 2  # Quick dodge using CHASE_SPEED
	
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
	var spawn_position = global_position + Vector2(0, 8)  # 8 pixels lower
	health_pickup.start_position = spawn_position
	health_pickup.global_position = spawn_position
	
	print("Health pickup spawned at enemy death location")

func die():
	spawn_health_pickup()
	queue_free()

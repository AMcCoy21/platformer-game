extends CharacterBody2D

const LASER_SCENE = preload("res://laser.tscn")  # Same laser as player
const DETECTION_RANGE = 100  # How far turret can "see"
const SHOOT_RANGE = 150  # How far turret will shoot
const SHOOT_COOLDOWN = 1.5  # Time between shots
const LASER_SPEED = 300  # Should match your laser speed
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

# NEW: Targeting delay system
const TARGET_DELAY = 0.8  # Time to wait after detecting player before shooting
const TURN_DELAY = 1.0   # Time to wait after turning before can target again

var player_ref = null
var can_shoot = true
var shoot_timer = 0.0
var is_targeting_player = false

# NEW: Targeting variables
var target_timer = 0.0  # Countdown timer for targeting delay
var is_locked_on = false  # Whether we've completed targeting and can shoot
var current_facing_direction = 1  # 1 for right, -1 for left
var turn_timer = 0.0  # Countdown timer after turning
var can_turn = true  # Whether turret can turn (not in turn delay)

# Health system
var max_health = 3  # Turrets are tougher than slimes
var current_health = 3
var is_taking_damage = false
var damage_flash_duration = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var laser_spawn_point_right: Marker2D = get_node_or_null("LaserSpawnPointRight")
@onready var laser_spawn_point_left: Marker2D = get_node_or_null("LaserSpawnPointLeft")

func _ready():
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# NEW: Apply gravity - turret falls like other physics objects
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Stop vertical movement when on ground
		velocity.y = 0
	
	# NEW: Apply physics movement (this handles gravity and platform movement)
	move_and_slide()
	
	# Handle shoot cooldown
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	# Handle turn delay
	if not can_turn:
		turn_timer -= delta
		if turn_timer <= 0:
			can_turn = true
	
	# Handle targeting system
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		var player_in_range = distance_to_player <= SHOOT_RANGE
		
		if player_in_range:
			# Check if we need to turn to face the player
			var direction_to_player = player_ref.global_position - global_position
			var needed_direction = 1 if direction_to_player.x > 0 else -1
			
			# If we need to turn, turn immediately but start turn delay
			if needed_direction != current_facing_direction:
				turn_immediately(needed_direction)
				return  # Don't start targeting until turn delay is over
			
			# Only start targeting if we can turn (not in turn delay)
			if can_turn and not is_targeting_player:
				start_targeting()
			elif is_targeting_player and can_turn:
				# Continue targeting countdown
				target_timer -= delta
				
				# Visual feedback during targeting (optional)
				update_targeting_visual()
				
				# Check if we're ready to shoot
				if target_timer <= 0 and not is_locked_on:
					complete_targeting()
				
				# Shoot if we're locked on and can shoot
				if is_locked_on and can_shoot:
					shoot_at_player()
		else:
			# Player left range - reset targeting
			if is_targeting_player:
				cancel_targeting()

func turn_immediately(new_direction):
	# Turn sprite immediately
	current_facing_direction = new_direction
	animated_sprite.flip_h = (new_direction == -1)
	
	# Start turn delay (prevents shooting)
	can_turn = false
	turn_timer = TURN_DELAY
	
	# Cancel any ongoing targeting
	if is_targeting_player:
		cancel_targeting()

func start_targeting():
	is_targeting_player = true
	is_locked_on = false
	target_timer = TARGET_DELAY
	
	# Face the player (direction should already be set from turn delay)
	var direction_to_player = player_ref.global_position - global_position
	var needed_direction = 1 if direction_to_player.x > 0 else -1
	current_facing_direction = needed_direction
	animated_sprite.flip_h = (needed_direction == -1)

func complete_targeting():
	is_locked_on = true
	
	# Optional: Visual feedback that targeting is complete
	# You could play a "lock-on" animation or sound here

func cancel_targeting():
	is_targeting_player = false
	is_locked_on = false
	target_timer = 0.0
	
	# Reset visual feedback
	animated_sprite.modulate = Color.WHITE

func update_targeting_visual():
	# Optional: Add visual feedback during targeting
	# For example, flash or change color to indicate targeting
	var flash_speed = 8.0  # How fast to flash
	var flash_intensity = 0.3  # How much to flash
	var time = Time.get_time_dict_from_system()
	var seconds = time.second + time.minute * 60.0  # Simple time value
	var flash_value = (sin(seconds * flash_speed) + 1.0) * 0.5 * flash_intensity
	animated_sprite.modulate = Color(1.0 + flash_value, 1.0 - flash_value, 1.0 - flash_value)

func shoot_at_player():
	if not can_shoot or not is_locked_on:
		return
	
	# Create laser instance
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	
	# Calculate direction to determine which spawn point to use
	var direction_to_player = player_ref.global_position - global_position
	var horizontal_direction = Vector2.ZERO
	var spawn_pos = global_position + Vector2(0, -10)  # Default fallback
	
	# Determine direction and choose appropriate spawn point
	if direction_to_player.x > 0:
		# Shooting right
		horizontal_direction = Vector2.RIGHT
		animated_sprite.flip_h = false
		if laser_spawn_point_right:
			spawn_pos = laser_spawn_point_right.global_position
	else:
		# Shooting left
		horizontal_direction = Vector2.LEFT
		animated_sprite.flip_h = true
		if laser_spawn_point_left:
			spawn_pos = laser_spawn_point_left.global_position
	
	laser.position = spawn_pos
	
	# SET ENEMY LASER COLLISION PROPERTIES
	# Enemy lasers should be on layer 4 and hit layers 1 (walls) and 2 (player)
	laser.collision_layer = 1 << 3  # Layer 4 (bit 3)
	laser.collision_mask = (1 << 0) | (1 << 1)  # Layers 1 and 2 (walls + player)
	
	laser.direction = horizontal_direction
	
	# Start cooldown and reset targeting
	can_shoot = false
	shoot_timer = SHOOT_COOLDOWN
	
	# Reset targeting after shooting
	cancel_targeting()

func take_damage():
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	current_health -= 1
	is_taking_damage = true
	
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	# Interrupt targeting and turning if taking damage
	if is_targeting_player:
		cancel_targeting()
	if not can_turn:
		can_turn = true
		turn_timer = 0.0
	
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

func die():
	spawn_health_pickup()
	queue_free()

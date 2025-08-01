extends CharacterBody2D

const SPEED = 30
const CHASE_SPEED = 50  # Faster when chasing
const DETECTION_RANGE = 150  # How far the enemy can "see" the player
const ATTACK_RANGE = 15  # How close before stopping chase
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

var direction = 1
var is_chasing = false
var player_ref = null

# NEW: Health system
var max_health = 2
var current_health = 2
var is_taking_damage = false
var damage_flash_duration = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_r: RayCast2D = $RayCastR
@onready var ray_cast_l: RayCast2D = $RayCastL

# NEW: Edge detection raycasts (optional - will be created if they don't exist)
@onready var edge_cast_r: RayCast2D = get_node_or_null("EdgeCastR")
@onready var edge_cast_l: RayCast2D = get_node_or_null("EdgeCastL")

func _ready():
	# Find the player node - adjust path as needed for your scene structure
	player_ref = get_tree().get_first_node_in_group("player")
	
func _physics_process(delta: float) -> void:
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle player collision mask based on invulnerability
	if player_ref and player_ref.is_invulnerable:
		collision_mask = collision_mask & ~(1 << 1)  # Remove layer 2 (Player)
	else:
		collision_mask = collision_mask | (1 << 1)   # Add layer 2 (Player) back
	
	# Check if we should chase the player
	check_for_player()
	
	# Move based on current behavior
	if is_chasing and player_ref:
		chase_player()
	else:
		patrol()
	
	# Apply movement
	move_and_slide()

func check_for_player():
	if not player_ref:
		is_chasing = false
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Start chasing if player is within detection range
	if distance_to_player <= DETECTION_RANGE:
		is_chasing = true
	# Stop chasing if player gets too far away (give some buffer)
	elif distance_to_player > DETECTION_RANGE * 1.5:
		is_chasing = false

func chase_player():
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Stop moving if we're very close to the player (prevents jittering)
	if distance_to_player <= ATTACK_RANGE:
		velocity.x = 0
		return
	
	# Determine direction to player
	var desired_direction = 0
	if player_ref.global_position.x > global_position.x:
		desired_direction = 1
	else:
		desired_direction = -1
	
	# Check if we can move in the desired direction without falling off edge
	if can_move_in_direction(desired_direction):
		direction = desired_direction
		if direction == 1:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
		
		# Move towards player at chase speed
		velocity.x = direction * CHASE_SPEED
	else:
		# Can't move toward player without falling, so stop
		velocity.x = 0

func patrol():
	# Check for walls and edges before moving
	var hit_wall_right = ray_cast_r.is_colliding()
	var hit_edge_right = edge_cast_r != null and not edge_cast_r.is_colliding()
	
	var hit_wall_left = ray_cast_l.is_colliding()
	var hit_edge_left = edge_cast_l != null and not edge_cast_l.is_colliding()
	
	if hit_wall_right or hit_edge_right:
		direction = -1
		animated_sprite.flip_h = true
	if hit_wall_left or hit_edge_left:
		direction = 1
		animated_sprite.flip_h = false

	velocity.x = direction * SPEED

# NEW: Function to check if enemy can move in a direction without falling
func can_move_in_direction(check_direction: int) -> bool:
	if check_direction == 1:  # Moving right
		# Check for wall collision
		var wall_blocked = ray_cast_r.is_colliding()
		# Check for edge (only if edge raycast exists)
		var edge_blocked = edge_cast_r != null and not edge_cast_r.is_colliding()
		return not wall_blocked and not edge_blocked
	else:  # Moving left
		# Check for wall collision
		var wall_blocked = ray_cast_l.is_colliding()
		# Check for edge (only if edge raycast exists)
		var edge_blocked = edge_cast_l != null and not edge_cast_l.is_colliding()
		return not wall_blocked and not edge_blocked

func take_damage(damage_amount: int = 1):
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	current_health -= damage_amount  # Use the parameter instead of hardcoded 1
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
	var spawn_position = global_position + Vector2(0, 8)  # 20 pixels lower
	health_pickup.start_position = spawn_position
	health_pickup.global_position = spawn_position
	
	print("Health pickup spawned at enemy death location")

# Then in your die() function, just call:
func die():
	spawn_health_pickup()  # Add this line
	queue_free()

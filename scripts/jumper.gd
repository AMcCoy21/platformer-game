extends CharacterBody2D

const JUMP_VELOCITY = -300.0
const HORIZONTAL_SPEED = 100.0
const DETECTION_RANGE = 150
const ATTACK_RANGE = 40  # How close to get before jumping at player
const JUMP_COOLDOWN = 1.0  # Time between jumps
const IDLE_TIME = 0.5  # Time to wait on ground before next action
const HEALTH_PICKUP_SCENE = preload("res://scenes/enemies/health_pick.tscn")

var player_ref = null
var can_jump = true
var jump_timer = 0.0
var idle_timer = 0.0
var is_idle = false
var target_direction = 0

# Health system
var max_health = 2
var current_health = 2
var is_taking_damage = false
var damage_flash_duration = 0.2

# States
enum State {IDLE, JUMPING, FALLING, ATTACKING}
var current_state = State.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Add to enemies group so player can detect collision with us
	add_to_group("enemies")
	
func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump cooldown
	if not can_jump:
		jump_timer -= delta
		if jump_timer <= 0:
			can_jump = true
	
	# Handle idle timer
	if is_idle:
		idle_timer -= delta
		if idle_timer <= 0:
			is_idle = false
	
	# Update state based on physics
	update_state()
	
	# Behavior based on current state
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.JUMPING, State.FALLING:
			handle_air_state()
		State.ATTACKING:
			handle_attack_state()
	if player_ref and player_ref.is_invulnerable:
		collision_mask = collision_mask & ~(1 << 1)  # Remove layer 2 (Player)
	else:
		collision_mask = collision_mask | (1 << 1)
	
	move_and_slide()
	
	# NEW: Check for collision with player after movement
	check_player_collision()

func update_state():
	if is_on_floor():
		if abs(velocity.y) < 10:  # Not moving much vertically
			current_state = State.IDLE
	else:
		if velocity.y < 0:  # Moving up
			current_state = State.JUMPING
		else:  # Moving down
			current_state = State.FALLING

func handle_idle_state():
	# Slow down horizontal movement when on ground
	velocity.x = move_toward(velocity.x, 0, HORIZONTAL_SPEED * 2)
	
	# Don't act if we're in idle cooldown
	if is_idle:
		return
	
	# Check for player and decide action
	if player_ref and can_jump:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		if distance_to_player <= DETECTION_RANGE:
			# Calculate direction to player
			var direction_to_player = player_ref.global_position - global_position
			
			# If player is close, jump directly at them (attack jump)
			if distance_to_player <= ATTACK_RANGE:
				attack_jump(direction_to_player)
			# If player is further, make a positioning jump
			else:
				positioning_jump(direction_to_player)

func attack_jump(direction_to_player: Vector2):
	# Jump directly at the player
	velocity.y = JUMP_VELOCITY
	velocity.x = sign(direction_to_player.x) * HORIZONTAL_SPEED * 1.5  # Faster attack jump
	
	# Face the direction we're jumping
	if direction_to_player.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
	
	start_jump_cooldown()
	current_state = State.ATTACKING

func positioning_jump(direction_to_player: Vector2):
	# Jump towards player but not as aggressively
	velocity.y = JUMP_VELOCITY * 0.8  # Lower jump
	velocity.x = sign(direction_to_player.x) * HORIZONTAL_SPEED
	
	# Face the direction we're jumping
	if direction_to_player.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
	
	start_jump_cooldown()

func handle_air_state():
	# Maintain horizontal velocity while in air
	# Could add slight air control here if desired
	pass

func handle_attack_state():
	# In attack state, maintain momentum until we land
	# Could add special attack effects here
	pass

func start_jump_cooldown():
	can_jump = false
	jump_timer = JUMP_COOLDOWN
	is_idle = true
	idle_timer = IDLE_TIME

# NEW: Check for collision with player and deal damage
func check_player_collision():
	if not player_ref:
		return
		
	# Check if we're colliding with the player
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we hit the player
		if collider == player_ref:
			# Check if player is invulnerable first
			if player_ref.has_method("take_damage") and not player_ref.is_invulnerable:
				player_ref.take_damage()
				print("Jumping enemy damaged player!")
			break

func take_damage():
	# Prevent multiple hits at once
	if is_taking_damage:
		return
	
	current_health -= 1
	is_taking_damage = true
		
	# Visual feedback - flash red
	animated_sprite.modulate = Color.RED
	
	# Knockback effect - interrupt current jump
	velocity.x *= 0.5  # Reduce horizontal momentum
	
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

extends CharacterBody2D

# Movement properties
const CHASE_SPEED = 60.0
const DETECTION_RANGE = 200.0
const EXPLOSION_RANGE = 25.0  # Slightly larger for more reliable detection

# Visual feedback
const BLINK_COUNT = 6
const BLINK_DURATION = 0.2
var blink_timer = 0.0
var blinks_remaining = 0
var is_blinking = false
var original_modulate: Color

# State management
var player_ref: Node2D
var is_exploding = false
var explosion_started = false  # New flag to prevent multiple triggers
var idle_timer = 0.0  # For bobbing motion

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Store original color for blinking effect
	original_modulate = animated_sprite.modulate
	
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Add to enemies group so player can detect collision
	add_to_group("enemies")
	
	print("Flying enemy spawned and hunting for player")

func _physics_process(delta: float) -> void:
	if is_exploding:
		handle_explosion_sequence(delta)
		return
	
	if not player_ref:
		# Try to find player again if we lost reference
		player_ref = get_tree().get_first_node_in_group("player")
		return
	
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Check if we're close enough to start explosion sequence
	if distance_to_player <= EXPLOSION_RANGE and not explosion_started:
		start_explosion_sequence()
		return
	
	# Chase the player if within detection range
	if distance_to_player <= DETECTION_RANGE:
		chase_player(delta)
	else:
		# Idle floating behavior when player is far away
		idle_float(delta)
	
	move_and_slide()

func chase_player(_delta: float):
	# Calculate direction to player
	var direction = (player_ref.global_position - global_position).normalized()
	
	# Set velocity towards player
	velocity = direction * CHASE_SPEED
	
	# Face the direction we're moving
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func idle_float(delta: float):
	# Gentle floating motion when not chasing
	velocity = velocity.move_toward(Vector2.ZERO, 50.0 * delta)
	
	# Add slight bobbing motion
	idle_timer += delta
	var bob_offset = sin(idle_timer * 2.0) * 10.0
	velocity.y = bob_offset

func start_explosion_sequence():
	if explosion_started:
		return
		
	explosion_started = true
	is_exploding = true
	
	# Stop movement completely
	velocity = Vector2.ZERO
	
	# Start blinking sequence
	is_blinking = true
	blinks_remaining = BLINK_COUNT
	blink_timer = 0.0
	
	print("Flying enemy starting explosion sequence!")

func handle_explosion_sequence(delta: float):
	if is_blinking:
		blink_timer += delta
		
		if blink_timer >= BLINK_DURATION:
			blink_timer = 0.0
			blinks_remaining -= 1
			
			# Toggle between original color and red (instead of transparent)
			if blinks_remaining % 2 == 0:
				animated_sprite.modulate = Color.RED  # Flash red
			else:
				animated_sprite.modulate = original_modulate  # Back to original color
			
			# Check if blinking is done
			if blinks_remaining <= 0:
				is_blinking = false
				explode()

func explode():
	print("Flying enemy exploding!")
	# Deal damage to player if they're still close enough (larger explosion radius for damage)
	if player_ref and global_position.distance_to(player_ref.global_position) <= EXPLOSION_RANGE * 2.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage()
			print("Explosion damaged player!")
		else:
			print("Player doesn't have take_damage method!")
	else:
		if player_ref:
			print("Player too far from explosion: ", global_position.distance_to(player_ref.global_position), " pixels away")
		else:
			print("No player reference found!")
	
	# Remove the enemy
	queue_free()

# Replace the create_explosion_effect() function with this much simpler version:



# Alternative even simpler version if the above still has issues:


# Optional: Add debug information
func _draw():
	# Removed debug circles - no visual rings
	pass

# Handle taking damage from player weapons
func take_damage():
	print("Flying enemy destroyed by player weapon!")
	# Create small explosion effect
	queue_free()

# Optional: Make the enemy respect walls/obstacles
func _on_area_2d_body_entered(_body):
	# If you add an Area2D child node, you can use this to detect walls
	# and adjust flight path accordingly
	pass

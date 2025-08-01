extends StaticBody2D

@export var bounce_strength: float = 400.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement types
enum MovementType {
	STATIONARY,      # Don't move at all
	LINEAR,          # Back and forth in a straight line
	CIRCULAR         # Move in a circle
}

@export var movement_type: MovementType = MovementType.STATIONARY
@export var speed: float = 50.0
@export var wait_time: float = 1.0  # Time to wait at each end

# Linear movement settings
@export var distance: Vector2 = Vector2(200, 0)  # How far to move from start position

# Circular movement settings
@export var radius: float = 100.0
@export var clockwise: bool = true

# Internal variables
var start_position: Vector2
var moving_forward: bool = true
var wait_timer: float = 0.0
var is_waiting: bool = false
var time_elapsed: float = 0.0

# Bounce variables
var just_bounced = false  # Track if we just bounced the player

# Tween for smooth movement
var tween: Tween

func _ready():
	# Add to bouncy group so player can detect it
	add_to_group("bouncy")
	add_to_group("saw")
	
	# Set collision properly - same as enemies
	collision_layer = 4  # Layer 3 (same as enemies) so player detects us
	collision_mask = 0   # Platform doesn't need to detect anything
	
	# Set up visual appearance
	if animated_sprite:
		animated_sprite.modulate = Color.CYAN
	
	# Movement setup
	start_position = global_position
	
	# Start movement
	start_movement()

func _physics_process(delta):
	if movement_type == MovementType.CIRCULAR:
		update_circular_movement(delta)
	elif is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			continue_movement()

# This method will be called by the player's check_enemy_collision function
func take_damage():
	# Don't damage if we just bounced the player
	if just_bounced:
		return
	
	# Get reference to the player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Only damage if player is NOT actively groundpounding
	if not player.get("is_actively_groundpounding"):
		# Call the player's actual take_damage method
		player.take_damage()

# Called by player when they groundpound on this object
func bounce_player(player):
	print("=== BOUNCE TRIGGERED ===")
	# Set bounce immunity
	just_bounced = true
	
	# Clear immunity after a short delay
	await get_tree().create_timer(0.3).timeout
	just_bounced = false

# MOVEMENT FUNCTIONS
func start_movement():
	match movement_type:
		MovementType.STATIONARY:
			# Do nothing - platform stays in place
			pass
		MovementType.LINEAR:
			start_linear_movement()
		MovementType.CIRCULAR:
			start_circular_movement()

# LINEAR MOVEMENT
func start_linear_movement():
	move_to_position(start_position + distance)

func move_to_position(target_pos: Vector2):
	if tween:
		tween.kill()
	
	tween = create_tween()
	var move_distance = global_position.distance_to(target_pos)
	var move_time = move_distance / speed
	
	tween.tween_property(self, "global_position", target_pos, move_time)
	tween.tween_callback(on_position_reached)

func on_position_reached():
	if wait_time > 0:
		is_waiting = true
		wait_timer = wait_time
	else:
		continue_movement()

func continue_movement():
	match movement_type:
		MovementType.LINEAR:
			# Reverse direction
			moving_forward = !moving_forward
			var target = start_position + (distance if moving_forward else Vector2.ZERO)
			move_to_position(target)

# CIRCULAR MOVEMENT
func start_circular_movement():
	# Circular movement is handled in _physics_process
	pass

func update_circular_movement(delta):
	time_elapsed += delta
	var angle = (time_elapsed * speed / radius) * (1 if clockwise else -1)
	
	var offset = Vector2(
		cos(angle) * radius,
		sin(angle) * radius
	)
	
	global_position = start_position + offset

# UTILITY FUNCTIONS
func pause_movement():
	if tween:
		tween.pause()

func resume_movement():
	if tween:
		tween.play()

func reset_to_start():
	if tween:
		tween.kill()
	
	global_position = start_position
	moving_forward = true
	time_elapsed = 0.0
	is_waiting = false
	start_movement()

# Debug visualization in editor
func _draw():
	if Engine.is_editor_hint():
		match movement_type:
			MovementType.LINEAR:
				draw_line(Vector2.ZERO, distance, Color.CYAN, 2.0)
				draw_circle(distance, 5, Color.MAGENTA)
			MovementType.CIRCULAR:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.CYAN, 2.0)
	
	

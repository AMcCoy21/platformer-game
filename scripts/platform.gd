# MovingPlatform.gd
extends AnimatableBody2D

# Movement types
enum MovementType {
	STATIONARY,      # Don't move at all
	LINEAR,          # Back and forth in a straight line
	CIRCULAR,        # Move in a circle
	CRUMBLING        # Falls when stepped on
}

@export var movement_type: MovementType = MovementType.LINEAR
@export var speed: float = 50.0
@export var wait_time: float = 1.0  # Time to wait at each end/waypoint

# Linear movement settings
@export var distance: Vector2 = Vector2(200, 0)  # How far to move from start position

# Circular movement settings
@export var radius: float = 100.0
@export var clockwise: bool = true

# Crumbling platform settings
@export var crumble_delay: float = 1.0  # Time before platform starts falling
@export var fall_speed: float = 200.0  # How fast it falls
@export var respawn_time: float = 3.0  # Time before platform respawns
@export var shake_intensity: float = 2.0  # How much to shake before falling

# Internal variables
var start_position: Vector2
var moving_forward: bool = true
var wait_timer: float = 0.0
var is_waiting: bool = false
var time_elapsed: float = 0.0

# Crumbling variables
var is_crumbling: bool = false
var is_falling: bool = false
var is_respawning: bool = false
var crumble_timer: float = 0.0
var shake_timer: float = 0.0
var original_modulate: Color
var player_on_platform: bool = false

# Tween for smooth movement
var tween: Tween

# Reference to collision shape and area for detection
@onready var collision_shape = $CollisionShape2D
@onready var sprite = $Sprite2D  # Assuming you have a Sprite2D child
@onready var detection_area = $DetectionArea  # Area2D child for crumbling detection

func _ready():
	start_position = global_position
	original_modulate = modulate
	
	# Add platform to group for easy identification
	add_to_group("platforms")
	
	# Connect body detection for crumbling platforms
	if movement_type == MovementType.CRUMBLING and detection_area:
		# Connect the Area2D signals for player detection
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
	
	# Start movement
	start_movement()

func start_movement():
	match movement_type:
		MovementType.STATIONARY:
			# Do nothing - platform stays in place
			pass
		MovementType.LINEAR:
			start_linear_movement()
		MovementType.CIRCULAR:
			start_circular_movement()
		MovementType.CRUMBLING:
			# Crumbling platforms start stationary
			pass

func _physics_process(delta):
	if movement_type == MovementType.CIRCULAR:
		update_circular_movement(delta)
	elif movement_type == MovementType.CRUMBLING:
		update_crumbling_platform(delta)
		check_player_collision()  # Check for player collision each frame
	elif is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			continue_movement()

# Check if player is standing on this platform (collision method)
func check_player_collision():
	if is_falling or is_respawning or is_crumbling:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Only check when player is on floor
	if player.is_on_floor():
		# Get platform bounds
		var platform_shape = collision_shape.shape as RectangleShape2D
		if not platform_shape:
			return
			
		var platform_size = platform_shape.size
		var player_half_width = 10  # Adjust based on your player's width
		var platform_left = global_position.x - platform_size.x / 2 - player_half_width
		var platform_right = global_position.x + platform_size.x / 2 + player_half_width
		var platform_top = global_position.y - platform_size.y / 2
		var _platform_bottom = global_position.y + platform_size.y / 2
		
		# Check if player is within platform bounds horizontally and close vertically
		var player_x = player.global_position.x
		var player_y = player.global_position.y
		
		var horizontal_overlap = player_x >= platform_left and player_x <= platform_right
		var vertical_close = abs(player_y - platform_top) < 35  # Player is close to top of platform
		
	
		
		# Player must be within platform width and close to the top
		if horizontal_overlap and vertical_close:
			if not player_on_platform:
				print("Player stepped on crumbling platform!")
				start_crumbling()
			player_on_platform = true
		else:
			player_on_platform = false

# CRUMBLING PLATFORM LOGIC
func update_crumbling_platform(delta):
	if is_respawning:
		return
	
	if is_falling:
		# Platform is falling
		global_position.y += fall_speed * delta
		
		# Check if platform has fallen far enough to disable it
		if global_position.y > start_position.y + 1000:
			start_respawn()
	
	elif is_crumbling:
		# Platform is about to fall - shake and count down
		crumble_timer -= delta
		shake_timer += delta
		
		# Shake effect
		var shake_offset = Vector2(
			sin(shake_timer * 20) * shake_intensity,
			cos(shake_timer * 25) * shake_intensity * 0.5
		)
		global_position = start_position + shake_offset
		
		# Flash red to warn player
		var flash_speed = 8.0
		var red_intensity = (sin(shake_timer * flash_speed) + 1.0) * 0.5
		modulate = original_modulate.lerp(Color.RED, red_intensity * 0.7)
		
		# Start falling when timer expires
		if crumble_timer <= 0:
			start_falling()

func start_crumbling():
	if is_crumbling or is_falling or is_respawning:
		return
	
	is_crumbling = true
	crumble_timer = crumble_delay
	shake_timer = 0.0
	print("Platform starting to crumble!")

func start_falling():
	is_crumbling = false
	is_falling = true
	
	# Disable collision so player falls through
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Reset position to start position (removes shake offset)
	global_position = start_position
	
	print("Platform falling!")

func start_respawn():
	is_falling = false
	is_respawning = true
	
	# Hide platform
	visible = false
	
	# Wait for respawn time
	await get_tree().create_timer(respawn_time).timeout
	
	# Reset platform
	global_position = start_position
	modulate = original_modulate
	visible = true
	is_respawning = false
	
	# Re-enable collision
	if collision_shape:
		collision_shape.disabled = false
	
	print("Platform respawned!")

# Detect when player steps on platform (collision method - no Area2D needed)
func _on_body_entered(_body):
	# This function is no longer used with collision detection method
	pass

func _on_body_exited(_body):
	# This function is no longer used with collision detection method  
	pass

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
	
	# Reset crumbling state
	is_crumbling = false
	is_falling = false
	is_respawning = false
	modulate = original_modulate
	visible = true
	player_on_platform = false
	
	if collision_shape:
		collision_shape.disabled = false
	
	start_movement()

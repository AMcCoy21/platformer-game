extends StaticBody2D

const LASER_SCENE = preload("res://laser.tscn")  # Same laser as player/turret
const DETECTION_RANGE = 200  # How far hazard can "see" horizontally
const SHOOT_RANGE = 400  # How far down the laser shoots
const SHOOT_COOLDOWN = 0.5  # Time between shots (slightly longer for hazards)
const WARNING_TIME = 0.2  # Time to show warning before firing

var player_ref = null
var can_shoot = true
var shoot_timer = 0.0
var is_warning = false
var warning_timer = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var laser_spawn_point: Marker2D = get_node_or_null("LaserSpawnPoint")
@onready var warning_light: AnimatedSprite2D = get_node_or_null("WarningLight")  # Optional warning indicator

func _ready():
	# Find the player
	player_ref = get_tree().get_first_node_in_group("player")
	
func _physics_process(delta: float) -> void:
	# Handle warning state
	if is_warning:
		warning_timer -= delta
		if warning_timer <= 0:
			fire_laser()
			is_warning = false
	
	# Handle shoot cooldown
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
			if warning_light:
				warning_light.visible = false
	
	# Check for player and start warning
	if player_ref and can_shoot and not is_warning:
		check_for_player()

func check_for_player():
	# Check if player is horizontally within range (directly below or near)
	var horizontal_distance = abs(player_ref.global_position.x - global_position.x)
	
	# Also check if player is below us (not above)
	var vertical_distance = player_ref.global_position.y - global_position.y
	
	if horizontal_distance <= DETECTION_RANGE and vertical_distance > 0 and vertical_distance <= SHOOT_RANGE:
		start_warning()

func start_warning():
	if not can_shoot or is_warning:
		return
	
	is_warning = true
	warning_timer = WARNING_TIME
	
	# Visual warning - flash red or show warning light
	if warning_light:
		warning_light.visible = true
		warning_light.play("warning")  # Assumes you have a warning animation
	
	# Make main sprite flash or change color to indicate charging
	animated_sprite.modulate = Color.YELLOW

func fire_laser():
	# Create laser instance
	var laser = LASER_SCENE.instantiate()
	get_parent().add_child(laser)
	
	# Set spawn position
	var spawn_pos = global_position + Vector2(0, 10)  # Default fallback
	if laser_spawn_point:
		spawn_pos = laser_spawn_point.global_position
	
	laser.position = spawn_pos
	
	# SET ENEMY LASER COLLISION PROPERTIES
	# Enemy lasers should be on layer 4 and hit layers 1 (walls) and 2 (player)
	laser.collision_layer = 1 << 3  # Layer 4 (bit 3)
	laser.collision_mask = (1 << 0) | (1 << 1)  # Layers 1 and 2 (walls + player)
	
	# Fire straight down
	laser.direction = Vector2.DOWN
	laser.rotation = PI/2
	
	# Reset visual state
	animated_sprite.modulate = Color.WHITE
	
	# Start cooldown
	can_shoot = false
	shoot_timer = SHOOT_COOLDOWN
	

extends Area2D

var speed = 500
var direction = Vector2.RIGHT

# NEW: Distance limiting
var max_distance = 200  # Adjust this value to set laser range
var distance_traveled = 0.0

# Add a flag to track if this is an enemy laser
var is_enemy_laser = false

func _ready():
	# Connect to detect when laser hits something
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	

func _physics_process(delta):
	# Move the laser
	var movement = direction * speed * delta
	position += movement
	
	# Track distance traveled
	distance_traveled += movement.length()
	
	# Destroy laser if it's traveled too far
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body):
	# Different behavior for enemy vs player lasers
	if is_enemy_laser:
		# Enemy laser hits player or walls
		if body.is_in_group("player") or not body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage()
			queue_free()
	else:
		# Player laser (original behavior)
		# Check if we hit an enemy
		if body.has_method("take_damage"):
			body.take_damage()
		# Check if we hit a door
		elif body.has_method("take_laser_damage"):
			body.take_laser_damage()
		queue_free()

func _on_area_entered(area):
	# Check if we hit a door (Area2D version)
	if area.has_method("take_damage"):
		area.take_damage()
	queue_free()

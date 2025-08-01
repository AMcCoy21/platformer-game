extends Area2D

# Visual properties
const FLOAT_AMPLITUDE = 5.0
const FLOAT_SPEED = 3.0
const COLLECTION_DISTANCE = 30.0

var start_position: Vector2
var float_timer = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Use pre-set start_position if it exists, otherwise use current position
	if start_position == Vector2.ZERO:
		start_position = global_position
	else:
		# Make sure we're at the correct position
		global_position = start_position
	
	# Connect to player detection
	body_entered.connect(_on_body_entered)
	
	# Set up collision detection
	add_to_group("pickups")
	
	print("Health pickup spawned at position: ", start_position)

func _physics_process(delta: float) -> void:
	# Floating animation
	float_timer += delta
	var float_offset = sin(float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
	global_position.y = start_position.y + float_offset

func _on_body_entered(body):
	# Check if the player touched this pickup
	if body.is_in_group("player"):
		collect_pickup(body)

func collect_pickup(player):
	print("Health pickup collected!")
	
	# Heal the player through GameManager
	if GameManager.current_health < GameManager.max_health:
		GameManager.restore_health(1)
		
		# Update player's local health values
		if player.has_method("sync_health_from_gamemanager"):
			player.sync_health_from_gamemanager()
		else:
			# Fallback: update player health directly
			player.current_health = GameManager.current_health
			if player.health_ui:
				player.health_ui.update_health(player.current_health, player.max_health)
		
		print("Player healed! Health now: ", GameManager.current_health, "/", GameManager.max_health)
	else:
		print("Player already at full health!")
	
	# Visual feedback before destroying
	create_collection_effect()
	
	# Remove the pickup
	queue_free()

func create_collection_effect():
	# Simple visual effect when collected
	animated_sprite.modulate = Color.GREEN
	
	# Scale up briefly
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.1)

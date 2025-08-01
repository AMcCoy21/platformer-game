# Bouncer.gd
extends Area2D

@export var bounce_strength: float = 400.0  # How strong the bounce is
@export var bounce_cooldown: float = 0.2    # Prevent multiple bounces too quickly

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var can_bounce = true
var bounce_timer = 0.0

func _ready():
	# Set up collision
	collision_layer = 0     # Bouncer doesn't need to be on any layer
	collision_mask = 2      # Only detect player (layer 2)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Set up visual appearance
	if animated_sprite:
		animated_sprite.modulate = Color.SPRING_GREEN
		# You can set a specific animation here if you have one
		# animated_sprite.play("idle")
	
	print("Bouncer ready - bounce strength:", bounce_strength)

func _physics_process(delta):
	# Handle bounce cooldown
	if not can_bounce:
		bounce_timer -= delta
		if bounce_timer <= 0:
			can_bounce = true
			# Reset visual feedback when ready to bounce again
			if animated_sprite:
				animated_sprite.modulate = Color.SPRING_GREEN

func _on_body_entered(body):
	# Check if it's the player and we can bounce
	if body.is_in_group("player") and can_bounce:
		bounce_player(body)

func bounce_player(player):
	print("=== BOUNCER ACTIVATED ===")
	
	# Apply upward velocity to player
	player.velocity.y = -bounce_strength
	
	# Reset player's jump count so they can jump again after bouncing
	if "jump_count" in player:
		player.jump_count = 0
	
	# Reset dash count so they can dash again after bouncing
	if "dash_count" in player:
		player.dash_count = 0
	
	# Visual and audio feedback
	play_bounce_effect()
	
	# Start cooldown
	can_bounce = false
	bounce_timer = bounce_cooldown

func play_bounce_effect():
	# Visual feedback - flash bright
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		# You could also play a bounce animation here
		# animated_sprite.play("bounce")
	
	# Optional: Add particles, sound, screen shake, etc.
	print("BOING! Player bounced with strength:", bounce_strength)
	
	# Create a quick scale effect
	create_bounce_animation()

func create_bounce_animation():
	# Quick scale animation for visual feedback
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple tweens at once
	
	# Scale up quickly, then back down
	tween.tween_property(self, "scale", Vector2(1.2, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Also tween the sprite color back to normal
	if animated_sprite:
		tween.tween_property(animated_sprite, "modulate", Color.SPRING_GREEN, 0.3)

# Optional: Debug visualization in editor
func _draw():
	if Engine.is_editor_hint():
		# Draw bounce area
		var shape = collision_shape.shape as CircleShape2D
		if shape:
			draw_circle(Vector2.ZERO, shape.radius, Color(0, 1, 0, 0.3))
			draw_circle(Vector2.ZERO, shape.radius, Color.GREEN, false, 2.0)
		
		# Draw bounce direction arrow
		draw_line(Vector2.ZERO, Vector2(0, -30), Color.GREEN, 3.0)
		draw_circle(Vector2(0, -30), 5, Color.GREEN)

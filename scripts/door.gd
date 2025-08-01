extends StaticBody2D

@export var target_scene: String = "res://Room2.tscn"  # Scene to load when entering

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_open = false
var portal_area: Area2D  # For detecting player entry

func _ready():
	# Start with red color to indicate it's locked
	sprite.modulate = Color.RED
	
	# Set collision layer so laser can hit it and it blocks the player
	collision_layer = 1  # Layer 1 so laser can detect it and player is blocked

func take_laser_damage():
	# This function will be called by the laser when it hits
	if not is_open:
		open_door()

func open_door():
	is_open = true
	
	
	# Visual feedback - turn green then fade out
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.2)
	tween.tween_interval(0.3)  # FIXED: was tween_delay
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
	
	# Disable collision so player can pass through
	collision_shape.set_deferred("disabled", true)
	
	# Optional: Remove the door completely after animation
	tween.tween_callback(queue_free)

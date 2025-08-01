extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var health = 1  # Just like enemies - 1 hit to break

func _ready():
	add_to_group("breakable_blocks")

func take_damage(damage: int = 1):
	health -= damage
	
	if health <= 0:
		break_block()
	else:
		# Visual feedback for damage (if you want multi-hit blocks later)
		sprite.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.GRAY, 0.1)

func break_block():
	# Add particle effect or break sound here if you want
	queue_free()

extends StaticBody2D

# Simple spike script that uses existing enemy damage system
# Visual feedback settings
@onready var sprite = $Sprite2D  # Adjust this path to match your spike's sprite node
var original_color: Color

func _ready():
	# Add to enemies group so player's existing collision system detects us
	add_to_group("enemies")
	
	# Store original color for visual feedback
	if sprite:
		original_color = sprite.modulate
	
	print("Spike ready - added to 'enemies' group")

# This function is required by the player's enemy collision system
# Even though spikes don't take damage, the player checks for this method
func take_damage():
	# Spikes don't take damage, but we can add visual feedback
	spike_flash_effect()
	print("Spike: Player weapon hit me, but I'm indestructible!")

func spike_flash_effect():
	# Brief flash effect when spikes are hit or activated
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = original_color

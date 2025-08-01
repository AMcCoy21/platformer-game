# FlyingBoundary.gd
extends StaticBody2D

func _ready():
	
	
	# Make completely invisible in game
	visible = false
	
	# Optional: Make visible in editor for easier placement
	if Engine.is_editor_hint():
		visible = true
		# Add visual feedback in editor
		modulate = Color(1, 0, 0, 0.3)  # Semi-transparent red

# Optional: Draw boundaries in editor for easier setup
func _draw():
	if Engine.is_editor_hint():
		# Draw a rectangle outline to show the boundary area
		var rect = get_node("CollisionShape2D").shape.get_rect()
		draw_rect(rect, Color.RED, false, 2.0)
		
		# Add a label
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(rect.position.x + 5, rect.position.y + 20), "Flying Boundary", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.RED)

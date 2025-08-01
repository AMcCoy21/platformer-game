extends Control

var hearts = []
var max_hearts = 3  # Start with 3, will grow dynamically

# NEW: Coin UI elements
var coin_label: Label

func _ready():
	print("CanvasLayer parent: ", get_parent())
	print("CanvasLayer layer: ", get_parent().layer if get_parent() is CanvasLayer else "Not CanvasLayer")
	add_to_group("health_ui")
	
	# Make sure the Control node has a size
	size = Vector2(200, 50)
	print("HealthUI size: ", size)
	print("HealthUI position: ", position)
	
	# Create initial hearts
	create_hearts(max_hearts)
	
	# NEW: Create coin counter
	create_coin_ui()

func create_hearts(num_hearts: int):
	# Clear existing hearts
	for heart in hearts:
		if heart and is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	# Create new hearts
	for i in range(num_hearts):
		var heart = ColorRect.new()
		add_child(heart)
		heart.position = Vector2(i * 40, 0)
		heart.color = Color.RED
		heart.size = Vector2(30, 30)
		heart.visible = true
		hearts.append(heart)
	
	# Update control size to fit all hearts
	size.x = max(num_hearts * 40, 150)  # Make sure there's room for coin counter too

# NEW: Create coin counter UI
func create_coin_ui():
	# Create coin label
	coin_label = Label.new()
	add_child(coin_label)
	coin_label.position = Vector2(0, 35)  # Below the hearts
	coin_label.text = "Coins: 0"
	coin_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Make the font bigger and bold if possible
	coin_label.add_theme_font_size_override("font_size", 16)
	
	# Update initial coin count
	update_coin_count()

func update_health(current_health: int, new_max_health: int = -1):
	# If max health changed, recreate hearts
	if new_max_health != -1 and new_max_health != max_hearts:
		max_hearts = new_max_health
		create_hearts(max_hearts)
	
	# Show filled hearts based on current health
	for i in range(hearts.size()):
		if i < current_health:
			hearts[i].color = Color.RED  # Filled heart
		else:
			hearts[i].color = Color.GRAY  # Empty heart

# NEW: Update coin counter display
func update_coin_count():
	if coin_label:
		var coin_count = GameManager.get_coin_count()
		coin_label.text = "Coins: " + str(coin_count)
	

extends Control

var map_container: Control
var is_map_open = false

# Map configuration
var room_size = 20  # Size of each room square
var room_spacing = 22  # Space between rooms
var map_offset = Vector2(20, 40)  # Offset from top-left of map panel

# Define your room layout here - adjust this to match your actual game layout
# Use a 2D grid where each room has coordinates (x, y)
var room_positions = {
	"res://scenes/rooms/hub.tscn": Vector2(3, 1.2),
	"res://scenes/rooms/room_1.tscn": Vector2(2, 2),          
	"res://scenes/rooms/room_2.tscn": Vector2(4, 3),
	"res://scenes/rooms/room_3.tscn": Vector2(2, 3),     
	"res://scenes/rooms/room_4.tscn": Vector2(1, 2),      
	"res://scenes/rooms/room_5.tscn": Vector2(4, 2),   
	"res://scenes/rooms/room_6.tscn": Vector2(5, 2),      
	"res://scenes/rooms/room_7.tscn": Vector2(5, 3),     
	# Add more rooms as needed with their actual paths
}



func _ready():
	# Position map in top-right corner
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(viewport_size.x - 280, 20)
	size = Vector2(260, 300)
	
	# Create background panel
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 0.95)  # Dark blue background
	bg.size = size
	add_child(bg)
	
	# Create map container
	map_container = Control.new()
	map_container.position = Vector2(10, 10)
	map_container.size = size - Vector2(20, 20)
	add_child(map_container)
	
	# Start hidden
	visible = false
	is_map_open = false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			toggle_map()

func toggle_map():
	is_map_open = !is_map_open
	visible = is_map_open
	
	if is_map_open:
		update_visual_map()

func update_visual_map():
	# Clear existing map elements
	for child in map_container.get_children():
		child.queue_free()
	
	# Add title
	var title = Label.new()
	title.text = "MAP"
	title.position = Vector2(100, 5)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 16)
	map_container.add_child(title)
	
	# Draw rooms
	draw_rooms()
	
	# Add legend
	add_map_legend()

func draw_rooms():
	for room_path in room_positions:
		var grid_pos = room_positions[room_path]
		var screen_pos = grid_to_screen_position(grid_pos)
		
		# Create room square
		var room_rect = ColorRect.new()
		if room_path == "res://scenes/rooms/hub.tscn":
			room_rect.size = Vector2(room_size, room_size*3)
		else:
			room_rect.size = Vector2(room_size, room_size)
		room_rect.position = screen_pos
		
		# Determine room color and state
		if room_path == GameManager.current_room:
			# Current room - bright yellow
			room_rect.color = Color.YELLOW
		elif GameManager.is_room_visited(room_path):
			# Visited room - light blue
			room_rect.color = Color.LIGHT_BLUE
		else:
			# Unvisited room - dark gray (hidden)
			room_rect.color = Color.DARK_GRAY
		
		map_container.add_child(room_rect)
		
		# Add room name label (only for visited rooms)
		if GameManager.is_room_visited(room_path):
			var room_label = Label.new()
			room_label.text = get_short_room_name(room_path)
			room_label.position = screen_pos + Vector2(0, room_size + 2)
			room_label.add_theme_color_override("font_color", Color.WHITE)
			room_label.add_theme_font_size_override("font_size", 8)
			map_container.add_child(room_label)

func grid_to_screen_position(grid_pos: Vector2) -> Vector2:
	return map_offset + Vector2(grid_pos.x * room_spacing, grid_pos.y * room_spacing)

func get_short_room_name(room_path: String) -> String:
	# Convert long room names to short versions for the map
	match room_path:
		"res://scenes/rooms/hub.tscn":
			return "Hub"
		"res://scenes/rooms/room_1.tscn":
			return "R1"
		"res://scenes/rooms/room_2.tscn":
			return "R2"
		"res://scenes/rooms/room_3.tscn":
			return "R3"
		"res://scenes/rooms/room_4.tscn":
			return "R4"
		"res://scenes/rooms/room_5.tscn":
			return "R5"
		"res://scenes/rooms/room_6.tscn":
			return "R6"
		"res://scenes/rooms/room_7.tscn":
			return "R7"
		_:
			return "Room"

func add_map_legend():
	var legend_y = 200
	
	# Current room indicator
	var current_indicator = ColorRect.new()
	current_indicator.size = Vector2(12, 12)
	current_indicator.position = Vector2(20, legend_y)
	current_indicator.color = Color.YELLOW
	map_container.add_child(current_indicator)
	
	var current_label = Label.new()
	current_label.text = "Current Room"
	current_label.position = Vector2(40, legend_y - 2)
	current_label.add_theme_color_override("font_color", Color.WHITE)
	current_label.add_theme_font_size_override("font_size", 10)
	map_container.add_child(current_label)
	
	# Visited room indicator
	var visited_indicator = ColorRect.new()
	visited_indicator.size = Vector2(12, 12)
	visited_indicator.position = Vector2(20, legend_y + 20)
	visited_indicator.color = Color.LIGHT_BLUE
	map_container.add_child(visited_indicator)
	
	var visited_label = Label.new()
	visited_label.text = "Visited"
	visited_label.position = Vector2(40, legend_y + 18)
	visited_label.add_theme_color_override("font_color", Color.WHITE)
	visited_label.add_theme_font_size_override("font_size", 10)
	map_container.add_child(visited_label)
	
	# Unvisited room indicator
	var unvisited_indicator = ColorRect.new()
	unvisited_indicator.size = Vector2(12, 12)
	unvisited_indicator.position = Vector2(20, legend_y + 40)
	unvisited_indicator.color = Color.DARK_GRAY
	map_container.add_child(unvisited_indicator)
	
	var unvisited_label = Label.new()
	unvisited_label.text = "Unknown"
	unvisited_label.position = Vector2(40, legend_y + 38)
	unvisited_label.add_theme_color_override("font_color", Color.WHITE)
	unvisited_label.add_theme_font_size_override("font_size", 10)
	map_container.add_child(unvisited_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Press M to close"
	instructions.position = Vector2(20, legend_y + 65)
	instructions.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	instructions.add_theme_font_size_override("font_size", 9)
	map_container.add_child(instructions)

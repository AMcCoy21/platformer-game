extends Control

@onready var continue_button: Button
@onready var quit_button: Button
@onready var title_label: Label

func _ready():
	# Create the UI elements
	create_game_over_ui()
	
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Don't pause game since this is now a separate scene
	print("Game Over screen initialized")

func create_game_over_ui():
	# Set menu size to fill screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background (same as main menu)
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue background
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Create main container with better centering (same as main menu)
	var vbox = VBoxContainer.new()
	# Use CENTER preset but remove the custom_minimum_size constraint
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	# Set anchors to center the container properly
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	# Use offset to position relative to center point
	vbox.offset_left = -100  # Half of desired width
	vbox.offset_right = 100   # Half of desired width
	vbox.offset_top = -150    # Half of desired height
	vbox.offset_bottom = 150  # Half of desired height
	add_child(vbox)
	
	# Title (changed text)
	title_label = Label.new()
	title_label.text = "SYSTEM FAILURE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	# Make sure title takes full width of container
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer1)
	
	# Continue Button (replaces NEW GAME)
	continue_button = Button.new()
	continue_button.text = "CONTINUE"
	continue_button.custom_minimum_size = Vector2(150, 40)
	# Center the button within its container
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(continue_button)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Quit Button (replaces main menu QUIT)
	quit_button = Button.new()
	quit_button.text = "QUIT TO MENU"
	quit_button.custom_minimum_size = Vector2(150, 40)
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(quit_button)
	
	# Controls hint
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer4)
	
	var controls_label = Label.new()
	controls_label.text = "Press R to restart or Q to quit to menu"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.add_theme_color_override("font_color", Color.GRAY)
	controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(controls_label)

func _on_continue_pressed():
	print("Restarting from checkpoint...")
	
	# Go back to the current room and respawn
	get_tree().change_scene_to_file(GameManager.current_room)
	
	# The respawn will happen when the scene loads via GameManager.apply_to_player()

func _on_quit_pressed():
	print("Returning to main menu...")
	
	# Reset game state
	GameManager.reset_game()
	
	# Go back to main menu - try common paths
	var main_menu_paths = ["res://scenes/rooms/main_menu.tscn"]
		
	var scene_loaded = false
	for path in main_menu_paths:
		if ResourceLoader.exists(path):
			print("Found main menu at: ", path)
			get_tree().change_scene_to_file(path)
			scene_loaded = true
			break
	
	if not scene_loaded:
		print("ERROR: Could not find main menu scene! Please check the path.")
		print("Current working directory scenes:")
		var dir = DirAccess.open("res://")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tscn"):
					print("  Found scene: ", file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

func _input(event):
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_on_continue_pressed()
		elif event.keycode == KEY_Q:
			_on_quit_pressed()
		elif event.keycode == KEY_ESCAPE:
			_on_continue_pressed()  # Escape also continues

# Remove the _exit_tree function since we're not pausing anymore

extends Control
@onready var new_game_button: Button
@onready var continue_button: Button
@onready var quit_button: Button
@onready var title_label: Label

func _ready():
	# Create the UI elements
	create_menu_ui()
	
	# Check if save file exists to enable/disable continue
	update_continue_button()
	
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	print("Main Menu initialized")

func create_menu_ui():
	# Set menu size to fill screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue background
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Create main container with better centering
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
	
	# Title
	title_label = Label.new()
	title_label.text = "ROBOT REBUILD"
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
	
	# New Game Button
	new_game_button = Button.new()
	new_game_button.text = "NEW GAME"
	new_game_button.custom_minimum_size = Vector2(150, 40)
	# Center the button within its container
	new_game_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(new_game_button)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	# Continue Button
	continue_button = Button.new()
	continue_button.text = "CONTINUE"
	continue_button.custom_minimum_size = Vector2(150, 40)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(continue_button)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer3)
	
	# Quit Button
	quit_button = Button.new()
	quit_button.text = "QUIT"
	quit_button.custom_minimum_size = Vector2(150, 40)
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(quit_button)
	
	# Controls hint
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer4)
	
	var controls_label = Label.new()
	controls_label.text = "Controls:\nArrows = Move\nUp = Jump\nSpace = Shoot\nX = Dash\nM = Map\nS = Save, L = Load"
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 12)
	controls_label.add_theme_color_override("font_color", Color.GRAY)
	controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(controls_label)

func update_continue_button():
	# Enable continue button only if save file exists
	if GameManager.has_save_file():
		continue_button.disabled = false
		continue_button.text = "CONTINUE"
	else:
		continue_button.disabled = true
		continue_button.text = "NO SAVE DATA"

func _on_new_game_pressed():
	print("Starting new game...")
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/rooms/hub.tscn")

func _on_continue_pressed():
	print("Loading saved game...")
	if GameManager.load_game():
		# Load the saved room
		get_tree().change_scene_to_file(GameManager.current_room)
	else:
		print("Failed to load save file")

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()

func _input(event):
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_N:
			_on_new_game_pressed()
		elif event.keycode == KEY_C and not continue_button.disabled:
			_on_continue_pressed()
		elif event.keycode == KEY_Q:
			_on_quit_pressed()

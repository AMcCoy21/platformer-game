extends Control

@onready var background_panel = $BackgroundPanel
@onready var item_name_label = $BackgroundPanel/VBoxContainer/ItemNameLabel
@onready var description_label = $BackgroundPanel/VBoxContainer/DescriptionLabel
@onready var continue_label = $BackgroundPanel/VBoxContainer/ContinueLabel

var is_showing = false

func _ready():
	# Add to group so pickups can find this UI easily
	add_to_group("pickup_notification")
	
	# Hide the notification initially
	hide()
	# Make sure this UI is on top
	z_index = 100

func _input(event):
	# Only handle input if the notification is showing
	if is_showing and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			hide_notification()

func show_notification(item_name: String, description: String):
	if is_showing:
		return  # Don't show multiple notifications at once
	
	is_showing = true
	
	# Set the text
	item_name_label.text = item_name
	description_label.text = description
	
	# Pause the game
	get_tree().paused = true
	
	# Show the notification
	show()
	
	# Optional: Add a fade-in animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_notification():
	if not is_showing:
		return
	
	is_showing = false
	
	# Optional: Add a fade-out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	# Hide the notification
	hide()
	
	# Unpause the game
	get_tree().paused = false

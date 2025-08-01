extends Area2D

# What type of body part this is
enum PartType {
	LEG_SERVOS,
	ARM_CANNON,
	JUMP_BOOSTERS,
	DASH_THRUSTERS,
	HEALTH_UPGRADE,
	GROUND_SLAM
}

@export var part_type: PartType = PartType.LEG_SERVOS
@export var pickup_message: String = "LEG SERVOS acquired!"
@export var pickup_id: String = ""  # Unique identifier for this pickup (set in editor)

# NEW: Export fields for notification text
@export var item_name: String = "LEG SERVOS"
@export_multiline var item_description: String = "Jump capability restored! Press UP arrow to jump."

@onready var sprite: Sprite2D = $Sprite2D
var is_collected = false
var current_room_path: String

func _ready():
	# Get current scene path
	current_room_path = get_tree().current_scene.scene_file_path
	
	# Generate pickup_id if not set in editor
	if pickup_id == "":
		var type_name = PartType.keys()[part_type].to_lower()
		pickup_id = type_name + "_" + str(global_position.x) + "_" + str(global_position.y)
	
	# Set default notification text based on part type if not already set
	set_default_notification_text()
	
	# Check if this pickup has already been collected
	if GameManager.is_pickup_collected(current_room_path, pickup_id):
		# Hide the pickup if already collected
		visible = false
		set_physics_process(false)
		set_process(false)
		print("Pickup already collected: ", pickup_id)
		return
	
	# Connect the area entered signal to detect player
	body_entered.connect(_on_body_entered)

func set_default_notification_text():
	# Only set defaults if the text hasn't been customized in the editor
	if item_name == "LEG SERVOS" and item_description == "Jump capability restored! Press UP arrow to jump.":
		match part_type:
			PartType.LEG_SERVOS:
				item_name = "LEG SERVOS"
				item_description = "Press UP arrow to jump."
			PartType.ARM_CANNON:
				item_name = "ARM CANNON"
				item_description = "Press SPACE to shoot laser bolts."
			PartType.JUMP_BOOSTERS:
				item_name = "JUMP BOOSTERS"
				item_description = "Press UP arrow while in air for double jump."
			PartType.DASH_THRUSTERS:
				item_name = "DASH THRUSTERS"
				item_description = "Press ESC to dash quickly."
			PartType.HEALTH_UPGRADE:
				item_name = "HEALTH CORE"
				item_description = "Maximum health increased! Health fully restored."
			PartType.GROUND_SLAM:
				item_name = "GROUND SLAM UNIT"
				item_description = "Press DOWN while in air to slam down."

func _on_body_entered(body):
	# Check if it's the player and hasn't been collected yet
	if body.name == "Player" and not is_collected:
		collect_part(body)

func collect_part(player):
	is_collected = true
	
	# Mark as collected in GameManager
	GameManager.collect_pickup(current_room_path, pickup_id)
	
	# Show the pickup notification BEFORE giving abilities
	show_pickup_notification()
	
	# Give the player the appropriate ability
	match part_type:
		PartType.LEG_SERVOS:
			player.unlock_leg_servos()
		PartType.ARM_CANNON:
			player.unlock_arm_cannon()
		PartType.JUMP_BOOSTERS:
			player.unlock_jump_boosters()
		PartType.DASH_THRUSTERS:
			player.unlock_dash_thrusters()
		PartType.HEALTH_UPGRADE:
			player.increase_max_health()
		PartType.GROUND_SLAM:
			if player.has_method("unlock_ground_slam"):
				player.unlock_ground_slam()
	
	# Visual feedback - make it disappear with style
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_callback(queue_free)  # Remove from scene after animation

func show_pickup_notification():
	# Find the pickup notification UI
	var pickup_notification = get_tree().get_first_node_in_group("pickup_notification")
	
	# If not found by group, try to find it by path
	if not pickup_notification:
		var canvas_layer = get_tree().get_first_node_in_group("main_ui")
		if canvas_layer:
			pickup_notification = canvas_layer.get_node_or_null("PickupNotification")
	
	# Last resort: search by name
	if not pickup_notification:
		pickup_notification = get_tree().get_nodes_in_group("pickup_notification")
		if pickup_notification.size() > 0:
			pickup_notification = pickup_notification[0]
		else:
			pickup_notification = null
	
	# Show the notification if found
	if pickup_notification and pickup_notification.has_method("show_notification"):
		pickup_notification.show_notification(item_name, item_description)
	else:
		print("Warning: PickupNotification UI not found!")
		print("Make sure to add the PickupNotification to the 'pickup_notification' group")

# Portal.gd - Updated version with smooth transitions
extends Area2D

@export var target_scene: String = "res://scenes/rooms/room_2.tscn"
@export var spawn_point_id: String = "from_main"  # ID for where player should spawn in target room

var player_in_area = false

func _ready():
	# Connect the signal to detect player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_area = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_area = false

func _input(event):
	# Only activate portal when player is in area and presses up
	if player_in_area:
		# Freeze the player immediately when transition starts
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(false)  # Stop physics processing
			player.velocity = Vector2.ZERO      # Stop any movement
		
		# Use SceneTransition for smooth fade
		SceneTransition.change_scene(target_scene, spawn_point_id)

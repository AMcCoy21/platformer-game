# SpawnPoint.gd - Create this as a new script
extends Node2D

@export var spawn_id: String = "default"  # Unique identifier for this spawn point

func _ready():
	# Add to spawn points group so GameManager can find all spawn points
	add_to_group("spawn_points")
	
	# Optional: Make spawn points visible in editor but invisible in game
	visible = true
	
	# You can add visual feedback in editor
	if Engine.is_editor_hint():
		visible = true

extends Node

# Save file path
const SAVE_FILE = "user://savegame.dat"
const GAME_OVER_SCENE = "res://scenes/UI/game_over.tscn" 

# Player abilities - persist across scenes
var has_leg_servos = false
var has_arm_cannon = false
var has_jump_boosters = false
var has_dash_thrusters = false
var has_ground_slam = false

# Player stats - persist across scenes
var max_health = 3
var current_health = 3

# Coin system
var coin_count = 0

# Room tracking (for map system)
var current_room = "res://game.tscn"
var last_room = ""
var visited_rooms = {}  # Dictionary to track which rooms have been visited

# Pickup tracking system
var collected_pickups = {}  # Dictionary to track which pickups have been collected
# Format: {"room_path|pickup_id": true, "room_path|pickup_id": true}

# Spawn point system
var target_spawn_point_id: String = ""  # Which spawn point to use when entering a room
var default_spawn_position: Vector2 = Vector2.ZERO  # Fallback position

func _ready():
	print("GameManager initialized")
	# Mark starting room as visited
	mark_room_visited("res://game.tscn")

func _input(event):
	# Manual save with S key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			if save_game():
				print("=== GAME SAVED (S key) ===")
			else:
				print("=== SAVE FAILED ===")
		# Manual load with L key
		elif event.keycode == KEY_L:
			if load_game():
				print("=== GAME LOADED (L key) ===")
				# Reload current scene to apply loaded state
				get_tree().change_scene_to_file(current_room)
			else:
				print("=== LOAD FAILED ===")
		# Debug: Quick test abilities with Spacebar
		elif event.keycode == KEY_SPACE:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("_debug_unlock_next_ability"):
				player._debug_unlock_next_ability()

# Coin collection function
func collect_coin():
	coin_count += 1
	print("GameManager: Coin collected! Total: ", coin_count)
	
# Get current coin count
func get_coin_count() -> int:
	return coin_count

# Called when player collects a body part
func unlock_ability(ability_type: String):
	match ability_type:
		"leg_servos":
			has_leg_servos = true
			print("GameManager: Leg Servos unlocked globally")
		"arm_cannon":
			has_arm_cannon = true
			print("GameManager: Arm Cannon unlocked globally")
		"jump_boosters":
			has_jump_boosters = true
			print("GameManager: Jump Boosters unlocked globally")
		"dash_thrusters":
			has_dash_thrusters = true
			print("GameManager: Dash Thrusters unlocked globally")
		"ground_slam":
			has_ground_slam = true
			print("GameManager: Ground Slam unlocked globally")
	
	# Auto-save when getting new abilities
	auto_save()

# Mark a pickup as collected
func collect_pickup(room_path: String, pickup_id: String):
	var pickup_key = room_path + "|" + pickup_id
	collected_pickups[pickup_key] = true
	print("GameManager: Pickup collected - ", pickup_key)
	
	# Auto-save when collecting important items
	auto_save()

# Check if a pickup has been collected
func is_pickup_collected(room_path: String, pickup_id: String) -> bool:
	var pickup_key = room_path + "|" + pickup_id
	return collected_pickups.has(pickup_key)

# Called when player takes damage
func take_damage():
	current_health -= 1
	current_health = max(current_health, 0)  # Don't go below 0
	print("GameManager: Health now ", current_health)
	return current_health

# Called when player health is restored
func restore_health(amount: int = 1):
	current_health += amount
	current_health = min(current_health, max_health)  # Don't exceed max
	print("GameManager: Health restored to ", current_health)

# NEW: Simple respawn function - always go to spawn point "1" in current room
func respawn_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("GameManager: No player found for respawn")
		return
	
	# Use smooth transition for respawning
	await SceneTransition.quick_fade()
	
	# Look for spawn point with ID "1" in the current room
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	var spawn_found = false
	
	print("GameManager: Looking for spawn point '1' in current room")
	print("GameManager: Found ", spawn_points.size(), " spawn points total")
	
	for spawn_point in spawn_points:
		print("GameManager: Checking spawn point: ", spawn_point.spawn_id)
		if spawn_point.spawn_id == "1":
			player.global_position = spawn_point.global_position
			print("GameManager: Player respawned at spawn point 1: ", spawn_point.global_position)
			spawn_found = true
			break
	
	# Fallback if spawn point "1" not found
	if not spawn_found:
		print("GameManager: Spawn point '1' not found, using fallbacks...")
		
		# Try to use player's last safe position first
		if "last_safe_position" in player and player.last_safe_position != Vector2.ZERO:
			player.global_position = player.last_safe_position
			print("GameManager: Player respawned at last safe position: ", player.last_safe_position)
		# Try any available spawn point
		elif spawn_points.size() > 0:
			player.global_position = spawn_points[0].global_position
			print("GameManager: Player respawned at first available spawn point: ", spawn_points[0].global_position)
		else:
			# Safe fallback for your starting room - adjust this position!
			var safe_position = Vector2(100, 300)  # Change this to a safe spot in your starting room
			player.global_position = safe_position
			print("GameManager: Player respawned at safe fallback position: ", safe_position)
	
	# Reset player state completely
	player.velocity = Vector2.ZERO
	
	# IMPORTANT: Reset invulnerability state
	if "is_invulnerable" in player:
		player.is_invulnerable = false
		print("GameManager: Player invulnerability reset")
	
	# Reset collision mask to normal (re-enable enemy collision)
	if player.has_method("get") and "collision_mask" in player:
		player.collision_mask = player.collision_mask | (1 << 2)  # Re-enable layer 3 (Enemies)
		print("GameManager: Player collision mask reset")
	
	# Reset visual appearance
	if "animated_sprite" in player and player.animated_sprite:
		player.animated_sprite.modulate = Color.WHITE
		print("GameManager: Player appearance reset")
	
	# Restore health to full when respawning
	current_health = max_health
	player.current_health = current_health
	if player.health_ui:
		player.health_ui.update_health(current_health, max_health)
	
	print("GameManager: Respawn complete - Health restored to ", current_health)

# Set which spawn point to use in the target room
func set_target_spawn_point(spawn_id: String):
	target_spawn_point_id = spawn_id
	print("GameManager: Target spawn point set to: ", spawn_id)

# Position player at correct spawn point when scene loads
func position_player_at_spawn():
	# Wait a frame to ensure scene is fully loaded
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("GameManager: No player found for spawn positioning")
		return
	
	# If we have a target spawn point, try to use it
	if target_spawn_point_id != "":
		var spawn_points = get_tree().get_nodes_in_group("spawn_points")
		
		for spawn_point in spawn_points:
			if spawn_point.spawn_id == target_spawn_point_id:
				player.global_position = spawn_point.global_position
				print("GameManager: Player positioned at spawn point: ", target_spawn_point_id)
				
				# Clear the target spawn point
				target_spawn_point_id = ""
				return
		
		print("GameManager: Spawn point '", target_spawn_point_id, "' not found!")
	
	# If no spawn point found, use default position or leave player where they are
	if default_spawn_position != Vector2.ZERO:
		player.global_position = default_spawn_position
		print("GameManager: Player positioned at default spawn")

# Modified change_room function
func change_room(new_room: String):
	last_room = current_room
	current_room = new_room
	mark_room_visited(new_room)
	print("GameManager: Changed from ", last_room, " to ", current_room)
	
	# Auto-save when entering new rooms
	auto_save()

# Legacy function - now uses the new respawn_player()
func smooth_respawn_player():
	respawn_player()

# Mark a room as visited
func mark_room_visited(room_path: String):
	visited_rooms[room_path] = true
	print("GameManager: Room visited - ", room_path)

# Check if a room has been visited
func is_room_visited(room_path: String) -> bool:
	return visited_rooms.has(room_path)

# Get friendly room name for display
func get_room_name(room_path: String) -> String:
	match room_path:
		"res://game.tscn":
			return "Starting Area"
		"res://room_2.tscn":
			return "East Chamber"
		_:
			return "Unknown Area"

# Apply saved state to a newly loaded player
func apply_to_player(player):
	if not player:
		return
		
	# Set abilities
	player.has_leg_servos = has_leg_servos
	player.has_arm_cannon = has_arm_cannon
	player.has_jump_boosters = has_jump_boosters
	player.has_dash_thrusters = has_dash_thrusters
	player.has_ground_slam = has_ground_slam
	
	# Set health - if coming from game over, restore to full
	if current_health <= 0:
		current_health = max_health
		print("GameManager: Restoring health after game over")
	
	player.current_health = current_health
	player.max_health = max_health
	
	# Update health UI if it exists
	if player.health_ui:
		player.health_ui.update_health(current_health, max_health)
	
	# If health was 0 (coming from game over), position at spawn point 1
	if current_health == max_health:
		call_deferred("position_player_at_spawn_point_1", player)
	
	print("GameManager: Applied state to player - Health:", current_health, " Abilities:", [has_leg_servos, has_arm_cannon, has_jump_boosters, has_dash_thrusters, has_ground_slam])

# NEW: Position player at spawn point 1 (for game over respawn)
func position_player_at_spawn_point_1(player):
	if not player:
		return
		
	# Look for spawn point with ID "1"
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	
	for spawn_point in spawn_points:
		if spawn_point.spawn_id == "1":
			player.global_position = spawn_point.global_position
			print("GameManager: Positioned player at spawn point 1 after game over")
			return
	
	print("GameManager: No spawn point 1 found, player stays at scene default position")

# Reset everything (for new game)
func reset_game():
	has_leg_servos = false
	has_arm_cannon = false
	has_jump_boosters = false
	has_dash_thrusters = false
	has_ground_slam = false
	current_health = max_health
	max_health = 3
	coin_count = 0
	current_room = "res://game.tscn"
	last_room = ""
	visited_rooms.clear()
	collected_pickups.clear()  # Clear collected pickups
	target_spawn_point_id = ""  # Clear spawn point
	default_spawn_position = Vector2.ZERO  # Clear default spawn
	mark_room_visited("res://game.tscn")  # Mark starting room
	print("GameManager: Game state reset")

# Save game data to file
func save_game():
	var save_data = {
		"abilities": {
			"has_leg_servos": has_leg_servos,
			"has_arm_cannon": has_arm_cannon,
			"has_jump_boosters": has_jump_boosters,
			"has_dash_thrusters": has_dash_thrusters,
			"has_ground_slam": has_ground_slam
		},
		"health": {
			"max_health": max_health,
			"current_health": current_health
		},
		"coins": coin_count,
		"rooms": {
			"current_room": current_room,
			"visited_rooms": visited_rooms
		},
		"pickups": collected_pickups,  # Save collected pickups
		"version": "1.0"  # For future save compatibility
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("GameManager: Game saved successfully")
		return true
	else:
		print("GameManager: Failed to save game")
		return false

# Load game data from file
func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("GameManager: No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("GameManager: Failed to open save file")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("GameManager: Failed to parse save file")
		return false
	
	var save_data = json.data
	
	# Load abilities
	if save_data.has("abilities"):
		var abilities = save_data["abilities"]
		has_leg_servos = abilities.get("has_leg_servos", false)
		has_arm_cannon = abilities.get("has_arm_cannon", false)
		has_jump_boosters = abilities.get("has_jump_boosters", false)
		has_dash_thrusters = abilities.get("has_dash_thrusters", false)
		has_ground_slam = abilities.get("has_ground_slam", false)
	
	# Load health
	if save_data.has("health"):
		var health = save_data["health"]
		max_health = health.get("max_health", 3)
		current_health = health.get("current_health", max_health)
	
	# Load coin count
	if save_data.has("coins"):
		coin_count = save_data["coins"]
	else:
		coin_count = 0  # Default for old saves
	
	# Load rooms
	if save_data.has("rooms"):
		var rooms = save_data["rooms"]
		current_room = rooms.get("current_room", "res://game.tscn")
		visited_rooms = rooms.get("visited_rooms", {})
	
	# Load collected pickups
	if save_data.has("pickups"):
		collected_pickups = save_data["pickups"]
	else:
		collected_pickups = {}
	
	print("GameManager: Game loaded successfully")
	print("Loaded abilities: ", [has_leg_servos, has_arm_cannon, has_jump_boosters, has_dash_thrusters, has_ground_slam])
	print("Loaded health: ", current_health, "/", max_health)
	print("Loaded coins: ", coin_count)
	print("Loaded pickups: ", collected_pickups.size(), " items collected")
	return true

# Check if save file exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

# Auto-save when important events happen
func auto_save():
	save_game()
func show_game_over():
	print("GameManager: Showing game over screen")
	
	# Change to the game over scene
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

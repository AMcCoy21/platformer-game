# SceneTransition.gd - Create this as an AutoLoad singleton
extends CanvasLayer

@onready var color_rect = ColorRect.new()
@onready var tween: Tween

var is_transitioning = false

func _ready():
	# Set up the fade overlay
	color_rect.color = Color.BLACK
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(color_rect)
	
	# Start transparent
	color_rect.color.a = 0.0
	
	# Make sure this layer is on top
	layer = 100

# Smooth transition to a new scene
func change_scene(target_scene: String, spawn_point_id: String = ""):
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Set spawn point before transition
	if spawn_point_id != "":
		GameManager.set_target_spawn_point(spawn_point_id)
	
	# Fade out
	await fade_out()
	
	# Change the scene
	GameManager.change_room(target_scene)
	get_tree().change_scene_to_file(target_scene)
	
	# Wait a moment for the scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade in
	await fade_in()
	
	is_transitioning = false

# Fade to black
func fade_out(duration: float = 1.0):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished

# Fade from black
func fade_in(duration: float = 2.0):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished

# Quick fade for other uses (like respawning)
func quick_fade():
	await fade_out(0.1)
	await fade_in(0.1)

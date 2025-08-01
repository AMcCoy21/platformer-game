extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("respawn_from_fall"):
		body.respawn_from_fall()
		timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale=1.0
	

extends Area2D




func _on_body_entered(body: Node2D) -> void:
	print ("+1 coin")
	GameManager.collect_coin()
	# After calling GameManager.collect_coin()
	var health_ui = get_tree().get_first_node_in_group("health_ui")
	if health_ui and health_ui.has_method("update_coin_count"):
		health_ui.update_coin_count()
	queue_free()

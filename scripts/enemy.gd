extends CharacterBody2D

const SPEED = 60
var direction = 1
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_r: RayCast2D = $RayCastR
@onready var ray_cast_l: RayCast2D = $RayCastL

func _physics_process(_delta: float) -> void:
	if ray_cast_r.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_l.is_colliding():
		direction = 1	
		animated_sprite.flip_h = false
	
	velocity.x = direction * SPEED
	velocity.y = 0
	
	# Check if we're colliding with an invulnerable player
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we hit the player and they're invulnerable, don't push them
		if collider.name == "Player" and collider.is_invulnerable:
			velocity.x = 0  # Stop moving temporarily
			break
	
	move_and_slide()

func take_damage():
	queue_free()

extends CharacterBody2D

const GRAVITY : int = 4500
const JUMP_SPEED : int = -1800

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false
			if Input.is_action_pressed("Up"):
				velocity.y = JUMP_SPEED
			elif Input.is_action_pressed("Down"):
				$AnimatedSprite2D.play("duck")
				$RunCol.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")	
	
	move_and_slide()
	
func die():
	$AnimatedSprite2D.play("dead")

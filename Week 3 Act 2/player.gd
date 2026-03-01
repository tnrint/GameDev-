extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

const speed = 150
const jump_power = -350.0

var gravity = 900 

var weapon_equip: bool

func _ready():
	weapon_equip = false

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("JUMP") and is_on_floor():
		velocity.y = jump_power
		
	var direction = Input.get_axis("LEFT", "RIGHT")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	move_and_slide()
	handle_movement_animation(direction)
	
func handle_movement_animation(dir):
	if !weapon_equip:
		if is_on_floor():
			if !velocity.x:
				animated_sprite.play("IDLE")
			if velocity.x:
				animated_sprite.play("RUN")
				toggle_flip_sprite(dir)
			if velocity.y:
				animated_sprite.play("JUMP")
		elif !is_on_floor():
			animated_sprite.play("FALLING")
	

func toggle_flip_sprite(dir):
	if dir == 1:
		animated_sprite.flip_h = false
	if dir == -1:
		animated_sprite.flip_h = true

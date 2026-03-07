extends CharacterBody2D
class_name bat

# =========================
# CONSTANTS
# =========================
const SPEED: float = 60.0
const GRAVITY: float = 900.0
const CHASE_RANGE: float = 220.0
const ATTACK_RANGE: float = 60.0
const ATTACK_COOLDOWN: float = 1.5
const KNOCKBACK_FORCE: float = 300.0
const BITE_OFFSET: float = 30.0
# =========================
# STATS
# =========================
var health: int = 300
var max_health: int = 300
var damage_to_deal: int = 15

var dead: bool = false
var is_chasing: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var taking_damage: bool = false

# =========================
# NODE REFERENCES
# =========================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bite_area: Area2D = $Bite
@onready var bite_collision: CollisionShape2D = $Bite/CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
# =========================
# TARGET
# =========================
var player: CharacterBody2D = null

# =========================
# READY
# =========================
func _ready():
	# Connect attack area signal
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	
	bite_area.body_entered.connect(_on_bite_body_entered)
	bite_collision.disabled = true
	bite_area.monitoring = false
	
	# Get player reference
	if get_tree().has_group("player"):
		player = get_tree().get_first_node_in_group("player")
	print("player")

# =========================
# PHYSICS PROCESS
# =========================
func _physics_process(_delta: float) -> void:
	
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Apply gravity

	if not player:
		player = get_tree().get_first_node_in_group("player")
	handle_movement()
	handle_animation()

	move_and_slide()
# =========================
# PLAYER DETECTION
# =========================
func _on_detection_body_entered(body):

	if body.is_in_group("player"):
		player = body
		is_chasing = true


func _on_detection_body_exited(body):

	if body == player:
		player = null
		is_chasing = false

# =========================
# PLAYER DETECTION
# =========================
func check_player_distance() -> void:
	if not player:
		return

	var dist: float = global_position.distance_to(player.global_position)
	is_chasing = dist <= CHASE_RANGE

	if can_attack:
		attack()

# =========================
# MOVEMENT
# =========================
func handle_movement() -> void:
	if is_attacking:
		velocity.x = 0
		return
		
	if is_chasing and player:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * SPEED
		if dir.x > 0:
			sprite.flip_h = false
			bite_area.position.x = BITE_OFFSET
		else:
			sprite.flip_h = true
			bite_area.position.x = -BITE_OFFSET
		var distance = global_position.distance_to(player.global_position)
		if distance <= ATTACK_RANGE and can_attack:
			attack()
	else:
		velocity.x = 0

# =========================
# ATTACK
# =========================
func attack() -> void:
	if is_attacking or dead:
		return

	is_attacking = true
	can_attack = false
	sprite.play("Attack")

	# Wind-up frames
	await get_tree().create_timer(0.4).timeout

	# Enable attack hitbox
	bite_collision.disabled = false
	bite_area.monitoring = true

	# Active frames
	await get_tree().create_timer(0.25).timeout

	# Disable attack hitbox
	bite_collision.disabled = true
	bite_area.monitoring = false

	is_attacking = false

	# Cooldown
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	can_attack = true

# =========================
# ATTACK SIGNAL
# =========================
func _on_bite_body_entered(body: Node) -> void:
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage_to_deal, global_position)

# =========================
# ANIMATION
# =========================
func handle_animation() -> void:
	if is_attacking or dead:
		return
	if taking_damage:
		sprite.play("hurt")
		return

	if abs(velocity.x) > 1.0:
		sprite.play("fly")
	else:
		sprite.play("idle")

# =========================
# DAMAGE
# =========================
func take_damage(amount: int, attacker_position: Vector2) -> void:
	if dead:
		return

	taking_damage = true
	health -= amount

	# Apply knockback
	var knock_dir: Vector2 = (global_position - attacker_position).normalized()
	velocity.x = knock_dir.x * KNOCKBACK_FORCE
	velocity.y = knock_dir.y * KNOCKBACK_FORCE

	# Flash red

	if health <= 0:
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = Color.WHITE
		taking_damage = false

# =========================
# DEATH
# =========================
func die() -> void:
	if dead:
		return
		
	dead = true
	is_chasing = false
	is_attacking = false
	velocity = Vector2.ZERO
	
	bite_collision.disabled = true
	bite_area.monitoring = false
	$CollisionShape2D.disabled = true
	sprite.play("dead")

	await sprite.animation_finished
	queue_free()

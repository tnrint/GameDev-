extends Node

var stump_scene = preload("res://Stump.tscn")
var rock_scene = preload("res://rock.tscn")
var bird_scene = preload("res://Bird.tscn")

var obstacle_types := [stump_scene, rock_scene]
var obstacles : Array
var bird_height := [200, 390]

const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)

var difficulty
const MAX_DIFFICULTY : int = 2

var score : int
const SCORE_MODIFIER : int = 10
var high_score : int

var speed : float
const START_SPEED : float = 4.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000

var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs 

var current_level := 1
var break_active := false
var game_finished := false

func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	score = 0
	show_score()
	game_running  = false
	break_active = false
	game_finished = false
	current_level = 1
	difficulty = 0
	
	get_tree().paused = false
	
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0,0)
	
	$HUD.get_node("StartLabel").text = "PRESS SPACE TO START"
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(_delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
			
		adjust_difficulty()
		generate_obs()
		
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		score += speed
		show_score()
		
		var displayed_score = score / SCORE_MODIFIER
		
		if displayed_score >= 1000 and current_level == 1:
			start_level_2()
		
		if displayed_score >= 1400 and break_active:
			end_break()
		
		if displayed_score >= 2000 and not game_finished:
			player_win()
		
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
				
	else:
		if Input.is_action_just_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	if break_active:
		return
	
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) - 40
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_height[randi() % bird_height.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)
	
func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "Dino":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func start_level_2():
	current_level = 2
	break_active = true
	
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	$HUD.get_node("StartLabel").text = "LEVEL 2"
	$HUD.get_node("StartLabel").show()
	
	await get_tree().create_timer(1.5).timeout
	$HUD.get_node("StartLabel").hide()
	
	speed += 2
	difficulty = MAX_DIFFICULTY

func end_break():
	break_active = false
	speed += 2

func player_win():
	game_running = false
	game_finished = true
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	$Dino.velocity = Vector2i.ZERO
	$Dino.get_node("AnimatedSprite2D").play("idle")
	
	$HUD.get_node("StartLabel").text = "YOU WIN!"
	$HUD.get_node("StartLabel").show()

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$Dino.die()
	$GameOver.show()

extends Node2D

@export var bat_scene: PackedScene
@export var frog_scene: PackedScene
@onready var spawn_point = $EnemySpawn
@onready var spawn_point1 = $EnemySpawn1

func _ready():
	var bat1 = bat_scene.instantiate()
	var frog1 = frog_scene.instantiate()
	bat1.global_position = spawn_point.global_position
	frog1.global_position = spawn_point1.global_position
	add_child(bat1)
	add_child(frog1)

extends Node2D

onready var ground = $Ground
onready var clouds = $Clouds
onready var tents = $tents
onready var rails = $Railing

func _ready():
	set_process(false)
	visible = false

func _process(delta):
	var SCREEN_SIZE = get_parent().rect_size
	self.scale = Vector2(SCREEN_SIZE.y/1080,SCREEN_SIZE.y/1080)
	clouds.position.x -= delta*3
	tents.position.x -= delta*13
	ground.position.x -= delta*25
	rails.position.x -= delta*25

extends "res://Screens/ScreenWithMenuElements.gd"

onready var music:AudioStreamPlayer = $AudioStreamPlayer
onready var anim:AnimationPlayer = $AnimationPlayer
onready var sequence = [
	0.0,
	4.51
]

#func command_0():
#	var tw = create_tween()
#	tw.tween_property($Label,"modulate:a",1.0)
#	tw.tween_property($Label,"modulate:a",0.0)
#func command_1():
#	tw

func _ready():
	anim.play("New Anim")
	var timing = music.get_playback_position()
	anim.seek(timing,true)

#func _process(delta):
#	var timing = music.get_playback_position()
#	anim.current_animation_position = timing

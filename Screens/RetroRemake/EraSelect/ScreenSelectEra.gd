extends "res://Screens/ScreenWithMenuElements.gd"

onready var scroller = $ActorScroller

func _ready():
	$Music.load_song("17 - Dearly Beloved ~reprise~")
	# Wipe this data so the chapter select screens don't
	# navigate to the wrong chapter
	Globals.currentEpisodeData = null
	
	match Globals.previous_screen:
		"RE-ScreenTitleMenu":
			$ActorScroller.set_selection(1,false)
		"ScreenTitleMenu":
			$ActorScroller.set_selection(2,false)

func _input(event):
	scroller.input(event)

func _process(delta):
	var s = get_viewport().get_visible_rect().size
	$"Not an ActorScroller".position.x=s.x-670
	$"Not an ActorScroller".position.y=s.y/2

func _on_ActorScroller_input_accepted(selection,destName):
	if destName!="":
		OffCommandNextScreen(destName)

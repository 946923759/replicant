extends "res://Screens/ScreenWithMenuElements.gd"

onready var scroller = $ActorScroller

func _ready():
	$ActorScroller/Retro.unlocked = Globals.installedPacks & Globals.DLC_PACK.RETRO_REMAKE
	$ActorScroller/Reborn.unlocked = Globals.installedPacks & Globals.DLC_PACK.REBORN_REMAKE
	#If running from the editor
	if OS.is_debug_build() and !OS.has_feature("standalone"):
		$ActorScroller/Retro.unlocked = true
		$ActorScroller/Reborn.unlocked = true

	$Music.load_song("17 - Dearly Beloved ~reprise~")
	# Wipe this data so the chapter select screens don't
	# navigate to the wrong chapter
	Globals.currentEpisodeData = null
	
#	match Globals.previous_screen:
#		"RE-ScreenTitleMenu":
#			$ActorScroller.set_selection(1,false)
#		"ScreenTitleMenu":
#			$ActorScroller.set_selection(2,false)
	
	
	if Globals.previous_screen.begins_with("RR"):
		$ActorScroller.set_selection(0,false)
	elif Globals.previous_screen.begins_with("RE"):
		$ActorScroller.set_selection(1,false)
	else: #Default to Fire Moth
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

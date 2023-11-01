extends Control
signal button_pressed(destination,episode)

onready var title = $Title
onready var desc = $Description
onready var buttons = $HBoxContainer
onready var click = $AudioStreamPlayer

var thisEpisode:Globals.Episode
var partDestinations:Array

func _ready():
	for i in range(buttons.get_child_count()):
		buttons.get_child(i).connect("pressed",self,"buttonTrigger",[i])
#	setNumParts2(["Test 1","Test 2","Test 3","test1.txt","test2.txt","test3.txt"])

func setEpisode(episode:Globals.Episode,playerReadAlready:bool=false):
	thisEpisode=episode
	if INITrans.HasString("ChapterParts",episode.title):
		title.text = INITrans.GetString("ChapterParts",episode.title,false)
		desc.text  = INITrans.GetString("ChapterDescriptions",episode.title,false)
	else:
		title.text=episode.title
		desc.text=episode.desc
		
	if episode.isSub: #e98900
		$LeftColoring.modulate=Color("#00abff")
	else:
		$LeftColoring.modulate=Color("#e98900")
	$LabelMain.visible=episode.isSub==false
	$LabelSub.visible=episode.isSub
		
	setNumParts(episode.parts)
	
	$Check.visible=playerReadAlready

func setNumParts(partDestinations_:Array):
	self.partDestinations=partDestinations_
	var length = partDestinations.size()
	for i in range(buttons.get_child_count()):
		var button = buttons.get_child(i)
		if i < length:
			button.visible=true
			button.get_child(0).text="Part "+String(i+1)
		else:
			button.visible=false

func getNumParts()->int:
	var n = 0
	for i in range(buttons.get_child_count()):
		if buttons.get_child(i).visible:
			n+=1
	return n

func getPartActorFrame():
	return $HBoxContainer
##Not necessary right now
#func setNumParts2(partNamesAndDestinations:Array):
#	var length:int = partNamesAndDestinations.size()
#	partDestinations.resize(length/2)
#	for i in range(length/2):
#		buttons.get_child(i).get_child(0).text=partNamesAndDestinations[i]
#		partDestinations[i]=partNamesAndDestinations[i+length/2]
#
#	#for i in range(length/2,length):
#	#	partDestinations

func buttonTrigger(b:int):
	click.play()
	if b > partDestinations.size()-1:
		printerr("Pressed a button that shouldn't be pressable")
		return
	print(String(b)+" was pressed! Destination is "+partDestinations[b])
	emit_signal("button_pressed",partDestinations[b],thisEpisode)

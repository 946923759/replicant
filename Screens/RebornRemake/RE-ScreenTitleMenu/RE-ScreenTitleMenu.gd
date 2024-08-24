extends "res://Screens/ScreenWithMenuElements.gd"

export (String) var startingMenu = "ItemScrollerV2"
var curMenuActor:Node

"""
All character display conditions:
	Kiana = None
	Mei = Chapter 2
	Kyuushou = Chapter 1-2 to 5-14, then Chapter 11+
	Himeko = Chapter 3
	Theresa = Chapter 3
"""


func _ready():
	$Music.load_song("re/1-01 - FINAL FANTASY XIII-2 Overture")
	
	var saveData = Globals.playerData['completedReborn']
	$Background/Kyuushou.visible = saveData[1] & 1
	$Background/Mei.visible = saveData[1] & 1<<8
	
	$Background/Kiana.set_meta("zorder",1)
	$Background/Kyuushou.set_meta("zorder",1)
	
	$Background/Seele.set_meta("zorder",1.5)
	$Background/Mei.set_meta("zorder",1.5)
	$Background/Himeko.set_meta("zorder",1.6)
	
	$Background/Theresa.set_meta("zorder",2.5)
	$Background/Bronya.set_meta("zorder",2.1)
	$"Background/Sin Mal".set_meta("zorder",2.7)
	$Background/Estherine.set_meta("zorder",2.7)
	$Background/Ninti.set_meta("zorder",3)
	
	for c in $Background.get_children():
		c.set_meta("start_position",c.rect_position)
	
	curMenuActor=get_node(startingMenu)
	curMenuActor.connect("switch_submenus",self,"switch_submenus")
	var n = get_node_or_null("ItemScroller_Story")
	if n:
		n.connect("switch_submenus",self,"switch_submenus")
		n.OffCommand()

func update_background_parallax(mousePos:Vector2):
		var mousePosOffsetFromCenter = mousePos-Globals.gameResolution/2
		for c in $Background.get_children():
			
			c.rect_position = c.get_meta("start_position")-mousePosOffsetFromCenter*c.get_meta("zorder")*.03
		#$Background.rect_position = Vector2(347,0)-mousePosOffsetFromCenter*.03
		#$DebugLabel2.text = "Mouse: "+String(mousePosOffsetFromCenter)
		#$smSprite.rect_position=-mousePosOffsetFromCenter*.05
		#$Kyuushou.rect_position=-mousePosOffsetFromCenter*.03
		#When mousePos is Globals.gameResolution/2, offset should be 0
		#The size of the image is gameResolution*1.2
		#So when the mouse is all the way on the left it would be
		#gameResolution.x*1.1 -gameResolution.x/2+mousePosOffsetFromCenter
		#$smSprite.rect_position = SCREEN_SIZE*1.1 - SCREEN_SIZE/2+mousePosOffsetFromCenter
		
func _input(event):
	
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#var SCREEN_SIZE = Globals.gameResolution
		#var mouseZoom = Globals.gameResolution*1.2
		if !OS.has_feature("mobile"):
			update_background_parallax(event.position)
	curMenuActor.input(event)

func switch_submenus(newMenu:String):
	print("Switching to "+newMenu)
	var SCREEN_SIZE = get_viewport().get_visible_rect().size
	curMenuActor.OffCommand()
	curMenuActor=get_node(newMenu)
	curMenuActor.rect_position.x=SCREEN_SIZE.x
	curMenuActor.OnCommand()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		curMenuActor.input_cancel()

func ItemScrollerNewScreen(selectionNum, destinationName):
	#print("new screen!")
	if destinationName!="":
		OffCommandNextScreen(destinationName)
		$ConfirmSound.play()



func _on_ItemScrollerV2_selection_changed(newSel, IsLocked:bool=false, playSound:bool=true):
	if playSound:
		$CursorSound.play()
	pass

var presses = 0
func _on_Logo_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		presses+=1
		if presses >= 10:
			for c in $Background.get_children():
				c.visible=true
		#print("Pressed! "+String(presses))
	pass # Replace with function body.

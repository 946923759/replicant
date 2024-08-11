extends "res://Screens/ScreenWithMenuElements.gd"

export (String) var startingMenu = "ItemScroller_MainMenu"
var curMenuActor:Node

func _ready():
	curMenuActor=get_node(startingMenu)
	curMenuActor.connect("switch_submenus",self,"switch_submenus")
	var n = get_node_or_null("ItemScroller_Story")
	if n:
		n.connect("switch_submenus",self,"switch_submenus")
		n.OffCommand()
	
func _input(event):
	curMenuActor.input(event)

func switch_submenus(newMenu:String):
	print("Switching to "+newMenu)
	var SCREEN_SIZE = get_viewport().get_visible_rect().size
	curMenuActor.OffCommand()
	curMenuActor=get_node(newMenu)
	curMenuActor.position.x=SCREEN_SIZE.x
	curMenuActor.OnCommand()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		curMenuActor.input_cancel()

func ItemScrollerNewScreen(selectionNum, destinationName):
	if destinationName!="":
		OffCommandNextScreen(destinationName)


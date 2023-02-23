extends Control

var MAINMENU = [
	{
		'name':"Read",
		'submenu':true,
		'screen':"ScreenSelectChapter"
	},
	{
		'name':"Gallery",
		'screen':"ScreenGallery"
	},
	{
		'name':"Music",
		"screen":"ScreenSoundTest"
	},
	{
		"name":'Options'
	},
	{
		"name":"Quit",
		"screen":"Quit"
	}
]

var SUBMENU_READ = [
	{
		'name':"Main Story",
		'screen':"RR-ScreenSelectChapter"
	},
	{
		'name':"World Boss",
		'screen':"RR-WorldBossSelectChapter"
	},
	{
		'name':"LOCKED ITEM PLACEHOLDER",
		'locked':true
	}
]

export (String) var startingMenu = "ItemScroller_MainMenu"
var curMenuActor:Node

func _ready():
	curMenuActor=get_node(startingMenu)
	curMenuActor.connect("switch_submenus",self,"switch_submenus")
	$ItemScroller_Story.connect("switch_submenus",self,"switch_submenus")
	$ItemScroller_Story.OffCommand()
	
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
		$smScreenInOut.OffCommand(destinationName)

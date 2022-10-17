extends Control

var MAINMENU = [
	{
		'name':"Read",
		#'submenu':false,
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

const SPACING = 200

var next_screen:String = ""

onready var t:Tween = $Tween
func _ready():
	#var quad = $ColorRect
	#quad.visible=true
	var f:Node2D = $ActorFrame
	var count = f.get_child_count()
	var center = floor(count/2)
	for i in range(count):
		var c = f.get_child(i)
		c.connect("clicked",self,"handle_clicked",[i])
		c.position = Vector2(100,-SPACING*center+i*SPACING)
		c.set_by_name(MAINMENU[i]['name'])
		t.interpolate_property(c,"position:x",null,-274,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT,.3+.1*i)
	#t.interpolate_property(quad,"modulate:a",1,0,.5)
	t.start()
	$smSound.load_song("Significance");

func _process(_delta):
	$ActorFrame.position.x=get_viewport().get_visible_rect().size.x

#If Android back button pressed
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		$ColorRect.OffCommand("Quit")

func handle_clicked(sender:int):
	var info = MAINMENU[sender]
	#t.interpolate_property($ColorRect,"modulate:a",0,1,.5)
	if 'screen' in info:
		next_screen = info['screen']
		#print("Go to "+next_screen)
		$ColorRect.OffCommand(next_screen)
		#t.start()
		#yield(t,"tween_completed")
		#Globals.change_screen(get_tree(),next_screen)
	elif info['name']=="Options":
		pass
	else:
		print("No screen in dict!")
		print(info)

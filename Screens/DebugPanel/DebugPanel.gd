extends Panel

export(bool) var show_close_button = true
export(bool) var show_in_release_builds = false
#var SCREENS = ["ScreenInit","ScreenTitleMenu","ScreenTitleMenu_Debug","ScreenMap","CutsceneFromFile","Quit"]
onready var SCREENS = Globals.SCREENS.keys()

func _ready():
	var vbox = $TabContainer/ScrollContainer/AllScreens
	vbox.get_child(0).visible = show_close_button
	for k in SCREENS:
		var btn = Button.new()
		btn.text = k
		btn.connect("pressed",self,"jump",[k])
		vbox.add_child(btn)
	self.visible = OS.is_debug_build() or show_in_release_builds

func jump(screen):
	Globals.change_screen(get_tree(), screen)


func _on_Button_pressed():
	self.visible=false

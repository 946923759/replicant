class_name smScreenInOut
extends ColorRect

export(float,0,5,.1) var timeToTweenIn=.5
export(float,0,5,.1) var timeToTweenOut=.5

var t:Tween
func _init():
	t=Tween.new()
	self.add_child(t)
	
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if timeToTweenIn>0 or timeToTweenOut>0:
		visible=true

func _ready():
	t.interpolate_property(self,"modulate:a",1,0,timeToTweenIn)
	t.start()
	
func OffCommand(next_screen:String, prev_screen:String=""):
	if t.is_active():
		return
	t.interpolate_property(self,'visible',null, true, 0.0)
	t.interpolate_property(self,"modulate:a",0,1,timeToTweenOut)
	t.start()
	yield(t,"tween_all_completed")
	Globals.change_screen(get_tree(), next_screen, prev_screen)

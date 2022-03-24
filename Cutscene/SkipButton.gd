extends Control

func _ready():
	self.connect("mouse_entered",self,"setHighlight")
	self.connect("mouse_exited",self,"setNormal")
	
func setHighlight():
	$n.visible=false
	$hl.visible=true
	
func setNormal():
	$n.visible=true
	$hl.visible=false

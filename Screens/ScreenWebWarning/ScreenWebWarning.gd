extends "res://Screens/ScreenWithMenuElements.gd"

onready var t = $Tween
onready var af = $DialogueActorFrame2

func _ready():
	if ThisScreenIsAnOverlay:
		$smQuad.visible=false
		
	var rect_size:Vector2 = get_viewport().get_visible_rect().size
	af.rect_size = rect_size
	t.interpolate_property(af,"rect_position:x",rect_size.x,0,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT,0)
	t.interpolate_property(af,"modulate:a",0,1,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT,0)
	t.start()

func OffCommandNextScreen(scr:String=""):
	var rect_size:Vector2 = get_viewport().get_visible_rect().size
	t.interpolate_property(af,"rect_position:x",null,-rect_size.x,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT,0)
	t.interpolate_property(af,"modulate:a",null,0,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT,0)
	t.start()
	
	.OffCommandNextScreen(NextScreen)

func _on_OKButton_pressed():
	$AudioStreamPlayer.play()
	OffCommandNextScreen()

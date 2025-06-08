extends "res://Screens/ScreenWithMenuElements.gd"

var SCREEN_SIZE:Vector2
var current_instruction = 0
onready var instructions = [
	[3.1,"show_text"],
	[7.3,"show_text", $RandomizedLabel2],
	[12.0,"fade_text", [$RandomizedLabel, $RandomizedLabel2]],
	[13.0,"show_girls"],
	[16.0,"show_text_3"],
	[20.0,"show_text_4"],
	[24.0,"fade_text_2"],
	[26.0,"show_parallax"],
	[28.0,"show_text", $RandomizedLabel5],
	[32.0,"show_text", $RandomizedLabel6],
	[36.0,"fade_text",[$RandomizedLabel5, $RandomizedLabel6]],
	[40.0,"show_snow"],
	[42.0,"show_text", $RandomizedLabel7],
	[44.0,"show_text", $RandomizedLabel8],
	[46.0,"show_kyuushou"],
	[50.0,"fade_text_3"],
	#[55.0,"fade_text_3"],
	[INF,""]
]

onready var audio:AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	SCREEN_SIZE = self.rect_size
	$Parallax.modulate = Color.transparent
	$Parallax.visible = false
	$TextureRect.modulate = Color.black
	$TextureRect2.visible = false
	$RandomizedLabel.modulate = Color.transparent
	$RandomizedLabel2.modulate = Color.transparent
	
	$AudioStreamPlayer.connect("finished",Globals,"change_screen",[get_tree(),"ScreenTitleMenu"])
	
	var tw = create_tween()
	tw.set_parallel()
	tw.tween_callback($AudioStreamPlayer,"play")
	tw.tween_property($TextureRect, "modulate", Color.white, .5).set_delay(.1)
	tw.tween_property($TextureRect,"rect_position:y",-$TextureRect.rect_size.y+SCREEN_SIZE.y,8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property($TextureRect,"modulate", Color.black,1).set_delay(8).from(Color.white)


func _process(delta):
	var timing = audio.get_playback_position()
	var inst = instructions[current_instruction]
	if timing >= inst[0]:
		SCREEN_SIZE = self.rect_size
		if len(inst) > 2:
			call(inst[1], inst[2])
		else:
			call(inst[1])
		current_instruction+=1

func _input(event):
	if event is InputEventJoypadButton or event is InputEventMouseButton:
		finished()
	
func finished():
	if OffCommandNextScreen():
		set_process(false)
		set_process_input(false)
	#Globals.change_screen(get_tree(),"ScreenTitleMenu")

func show_text(o=null):
	if not o:
		o = $RandomizedLabel
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(o,"visible",true,0.0)
	tw.tween_property(o,"modulate:a",1.0,.3).from(0.0)
	tw.tween_property(o,"randomized_amount",0,.5).from(o.randomized_amount).set_delay(.3)

#func show_text_2():
#	show_text($RandomizedLabel2)
	#var tw = create_tween()
	#tw.set_parallel(true)
	#tw.tween_property($RandomizedLabel2,"visible",true,0.0)
	#tw.tween_property($RandomizedLabel2,"modulate:a",1.0,.3)
	#tw.tween_property($RandomizedLabel2,"randomized_amount",0,.5).from($RandomizedLabel2.randomized_amount).set_delay(.3)

func fade_text(varargs:Array = []):
	var tw = create_tween()
	tw.set_parallel(true)
	for node in varargs:
		#node.rect_pivot_offset = node.rect_size/2
		#tw.tween_property(node,"rect_scale",Vector2(2,0), .5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(node,"modulate", Color.transparent, .5)
	tw.set_parallel(false)
	for node in varargs:
		tw.tween_callback($RandomizedLabel,"set_process",[false])
	

#func fade_text_1():
#	fade_text([$RandomizedLabel, $RandomizedLabel2])
#	var tw = create_tween()
#	tw.set_parallel(true)
#	tw.tween_property($RandomizedLabel,"modulate", Color.transparent, .5)
#	tw.tween_property($RandomizedLabel2,"modulate", Color.transparent, .5)
#	tw.set_parallel(false)
#	tw.tween_callback($RandomizedLabel,"set_process",[false])
#	tw.tween_callback($RandomizedLabel2,"set_process",[false])

func show_girls():
	$TextureRect.rect_position.y = 0
	var tw = create_tween()
	tw.set_parallel()
	tw.tween_property($girls,"visible",true,0.0)
	tw.tween_property($girls,"modulate",Color.white,.3).from(Color.black)
	tw.tween_property($girls,"rect_position:y",SCREEN_SIZE.y-$girls.rect_size.y,8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property($girls,"modulate", Color.transparent,1).set_delay(8).from(Color.white)
	tw.tween_property($girls,"visible", false,0).set_delay(9)


func show_text_3():
	show_text($RandomizedLabel3)

func show_text_4():
	show_text($RandomizedLabel4)
	
func fade_text_2():
	fade_text([$RandomizedLabel3, $RandomizedLabel4])
	
func show_parallax():
	#print("Called c0")
	$ParallaxAlt.modulate = Color.black
	$kyuushou.modulate = Color(0,0,0,0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property($kyuushou,"visible",true,0.0)
	tw.tween_property($ParallaxAlt,"visible",true, 0.0)
	tw.tween_callback($ParallaxAlt,"set_process",[true])
	tw.tween_property($ParallaxAlt,"modulate", Color(.8,.8,.8,1), .5)
	#tw.tween_property($ParallaxAlt,"modulate", Color.transparent,1).set_delay(8).from(Color.white)
	tw.tween_property($kyuushou,"modulate",Color.black,1).set_delay(8).from(Color(0,0,0,0))
	tw.tween_property($ParallaxAlt,"visible", false,0).set_delay(9)
	tw.tween_callback($ParallaxAlt,"set_process", [false]).set_delay(9)


func show_snow():
	var tw = create_tween()
	tw.set_parallel()
	tw.tween_property($TextureRect2,"visible",true,0.0)
	tw.tween_property($TextureRect2,"modulate",Color.white,.5).from(Color.black)
	tw.tween_property($TextureRect2,"rect_position:y",SCREEN_SIZE.y-$TextureRect2.rect_size.y,8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

#func show_text_7():
#	show_text($RandomizedLabel7)
#
#func show_text_8():
#	show_text($RandomizedLabel8)

func show_kyuushou():
	var tw = create_tween()
	$kyuushou.visible = false
	$KianaSleep.visible = true
	#These two draw under kiana image
	$logo.visible = true
	$VBoxContainer.visible=true

	#tw.tween_property($KianaSleep,"visible",true,0.0)
	#tw.tween_property($KianaSleep,"logo",true,0.0)
	#tw.tween_property($KianaSleep,"self_modulate",Color.white,0.0)
	tw.tween_property($TextureRect2,"modulate",Color.transparent,1.0)
	tw.tween_property($KianaSleep2,"visible",true,0.0).set_delay(5)
	tw.tween_property($KianaSleep,"modulate:a",0.0,1.0)
	tw.tween_property($KianaSleep2,"modulate:a",0.0,3.0)
	#Make logo transparent after waiting 3 seconds on black screen
	tw.tween_property($logo,"modulate:a",0.0,3.0).set_delay(3)
	tw.parallel().tween_property($VBoxContainer,"modulate:a", 0.0, 3.0).set_delay(3)

func fade_text_3():
	fade_text([$RandomizedLabel7, $RandomizedLabel8])

#func show_logo():
#	var tw = create_tween()
#	tw.set_parallel()
#	tw.tween_property($logo,"modulate",Color.white,3.0)
#	tw.tween_property($VBoxContainer,"modulate:a", 1.0, 3.0)

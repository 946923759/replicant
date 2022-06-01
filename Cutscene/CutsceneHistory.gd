extends Control

onready var scrollContainer=$ScrollContainer
onready var container = $ScrollContainer/GridContainer
var font = preload("res://Cutscene/TextFont.tres")
const fadeTop = preload("res://Cutscene/FadeTopShader.tres")

func _ready():
	if true: #!OS.is_debug_build()
		for i in range(2,6):
			$ScrollContainer/GridContainer.get_child(i).visible=false
	#test_history()

func test_history():
	for i in range(100):
		container.add_child(LoadSpeaker("Speaker"+String(i)))
		container.add_child(LoadText("Text "+String(i)))

func LoadSpeaker(s:String)->Label:
	var l = Label.new()
	#l.material=fadeTop
	l.set("custom_fonts/font",font)
	l.text=s
	#How the fuck is anyone supposed to figure this out?
	l.size_flags_vertical=1 
	var width = font.get_string_size(l.text).x
	if width > 300:
		l.rect_scale.x=300/width
	#else:
	#	tn.rect_scale.x=1.0
	#for property in d:
	#	l.set(property,d[property])
	#l.set("custom_fonts/font",font)
	#l.add_to_group("Translatable")
	return l
func LoadText(s:String)->RichTextLabel:
	var l = Label.new()
	#l.material=fadeTop
	l.set("custom_fonts/font",font)
	l.rect_min_size=Vector2(1300,0)
	l.autowrap=true
	l.text=s
	return l

var last_history_number:int=0
func set_history(arr):
	if arr.size()>last_history_number:
		for i in range(last_history_number,arr.size()):
			container.add_child(LoadSpeaker(arr[i][0]))
			container.add_child(LoadText(arr[i][1]))
		last_history_number=arr.size()
	scrollContainer.scroll_vertical = scrollContainer.get_v_scrollbar().max_value	
#func OnCommand():
#	scrollContainer.scroll_vertical = scrollContainer.get_v_scrollbar().max_value	

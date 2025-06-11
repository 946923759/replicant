extends Control

const MAXIMUM_WIDTH = 1500

export(String) var chapter_name = "Chapter 1"
export(String) var chapter_full_name = "Meet And Redemption"
export(String) var chapter_description = "It seems like a normal quest..."
export(Texture) var chapter_background
export(float, -1000, 0, 1) var collapsed_x_offset: float = -625

onready var _rect_min_size = rect_min_size
var rect_dest_size:Vector2 = Vector2.ZERO setget , get_rect_size

var is_expanded:bool = false
var chapter_episodes:Array
#var partDestinations:Array

onready var tw:Tween = $Tween
var scroller:VBoxContainer

func _ready():
	$Label.text = chapter_name
	$Label.visible_characters = len(chapter_name)
	if chapter_background:
		$TextureRect.texture = chapter_background
	$TextureRect.rect_position.x = collapsed_x_offset
	
	for c in get_children():
		if c is VBoxContainer:
			scroller = c
			c.visible = false

func get_rect_size():
	if is_expanded:
		return Vector2(MAXIMUM_WIDTH, rect_size.y)
	else:
		return _rect_min_size

func set_chapter(chapter_name:String, chapter_data:Array):
	chapter_episodes=chapter_data
	self.chapter_name = chapter_name
	$Label.text = chapter_name
	$Label.visible_characters = len(chapter_name)
	
	if INITrans.HasString("ChapterSubtitles", chapter_name):
		chapter_full_name = INITrans.GetString("ChapterSubtitles", chapter_name, false)
	
	var num_episodes = len(chapter_data)
	for i in range(scroller.get_child_count()):
		var c = scroller.get_child(i)
		if i < num_episodes:
			var ep:Globals.Episode = chapter_data[i]
			c.visible = true
			c.text = ep.title
		else:
			c.visible = false


func GainFocus():
	#print("???")
	#rect_size.x = MAXIMUM_WIDTH
	tw.stop_all()
	tw.interpolate_property(self,"rect_min_size:x",null,MAXIMUM_WIDTH,.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
	#$Label.text = "fuck you"
	#tw.interpolate_callback(self,0.1, "print2",["???"])
	#tw.interpolate_callback($Label,0.1,"set_text",["JOIJOJIOAIJSFOJISDOAJ"])
	#tw.interpolate_callback(self,0.5,"wrap_set_text","e")
	var full_text = chapter_name+": "+chapter_full_name
	tw.interpolate_callback($Label,0.001,"set_text",full_text)
	tw.interpolate_property($Label,"visible_characters",len(chapter_name),len(full_text), .1)
	if scroller:
		tw.interpolate_callback(scroller,.1,"set_visible",true)
		for i in range(scroller.get_child_count()):
			var c = scroller.get_child(i)
			c.modulate.a = 0.0
			c.rect_position.x = -300
			tw.interpolate_property(c,"rect_position:x", null, 0.0, 0.3,Tween.TRANS_QUAD,Tween.EASE_OUT, .1+i*.1)
			tw.interpolate_property(c,"modulate:a", null, 1.0, .3, Tween.TRANS_LINEAR, Tween.EASE_IN, .1+i*.1)
	#tw.interpolate_property($PartScroller)
	#tw.interpolate_property($Label,"text",null,chapter_name+": "+chapter_full_name, .3)
	#tw.interpolate_property($TextureRect,"rect_position:x",null,0, .3, Tween.TRANS_QUAD,Tween.EASE_OUT)
	tw.start()
	is_expanded = true
	pass

func GainFocusNoTween():
	rect_min_size.x = MAXIMUM_WIDTH
	is_expanded = true
	if scroller:
		scroller.visible = true
		for i in range(scroller.get_child_count()):
			var c = scroller.get_child(i)
			c.modulate.a = 1.0
	
func LoseFocus():
	#rect_size.x = rect_min_size.x
	tw.stop_all()
	tw.interpolate_property(self,"rect_min_size:x",null,_rect_min_size.x,.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
	tw.interpolate_callback($Label,.1,"set_text",chapter_name)
	if scroller:
		for i in range(scroller.get_child_count()):
			var c = scroller.get_child(i)
			tw.interpolate_property(c,"modulate:a", null, 0.0, .3, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tw.interpolate_callback(scroller,.3,"set_visible",false)

	#tw.interpolate_property($Label,"text",null,chapter_name, .3)
	#tw.interpolate_property($TextureRect,"rect_position:x",null,collapsed_x_offset, .3)
	tw.start()
	is_expanded = false
	pass

extends Control

const MAXIMUM_WIDTH = 1500

export(String) var chapter_name = "Chapter 1"
export(String) var chapter_full_name = "Meet And Redemption"
export(String) var chapter_description = "It seems like a normal quest..."
export(Texture) var chapter_background
export(float, -1000, 0, 1) var collapsed_x_offset: float = -625

onready var _rect_min_size = rect_min_size
var is_expanded:bool = false
var rect_dest_size:Vector2 = Vector2.ZERO setget , get_rect_size

onready var tw:Tween = $Tween

func _ready():
	$Label.text = chapter_name
	if chapter_background:
		$TextureRect.texture = chapter_background
	$TextureRect.rect_position.x = collapsed_x_offset

func get_rect_size():
	if is_expanded:
		return Vector2(MAXIMUM_WIDTH, rect_size.y)
	else:
		return _rect_min_size

#func print2(s):
#	print(s)
func wrap_set_text(t:String):
	print("Triggered")
	#$Label.set_text(t)

func GainFocus():
	#print("???")
	#rect_size.x = MAXIMUM_WIDTH
	tw.stop_all()
	tw.interpolate_property(self,"rect_min_size:x",null,MAXIMUM_WIDTH,.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
	#$Label.text = "fuck you"
	#tw.interpolate_callback(self,0.1, "print2",["???"])
	#tw.interpolate_callback($Label,0.1,"set_text",["JOIJOJIOAIJSFOJISDOAJ"])
	#tw.interpolate_callback(self,0.5,"wrap_set_text","e")
	tw.interpolate_callback($Label,0.1,"set_text",chapter_name+": "+chapter_full_name)
	#tw.interpolate_property($Label,"text",null,chapter_name+": "+chapter_full_name, .3)
	#tw.interpolate_property($TextureRect,"rect_position:x",null,0, .3, Tween.TRANS_QUAD,Tween.EASE_OUT)
	tw.start()
	is_expanded = true
	pass

func GainFocusNoTween():
	rect_min_size.x = MAXIMUM_WIDTH
	is_expanded = true
	
func LoseFocus():
	#rect_size.x = rect_min_size.x
	tw.stop_all()
	tw.interpolate_property(self,"rect_min_size:x",null,_rect_min_size.x,.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
	tw.interpolate_callback($Label,.1,"set_text",chapter_name)
	#tw.interpolate_property($Label,"text",null,chapter_name, .3)
	#tw.interpolate_property($TextureRect,"rect_position:x",null,collapsed_x_offset, .3)
	tw.start()
	is_expanded = false
	pass

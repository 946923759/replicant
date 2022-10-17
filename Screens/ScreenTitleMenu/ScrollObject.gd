extends Node2D
tool
signal clicked()

export(int,"Read","Gallery","Music","Options","Quit") var ToLoad setget set_sprite
var l = ["Read","Gallery","Music","Options","Quit"]

onready var text = $Node2D/Text
onready var texthl = $Node2D/TextHighlight

func set_sprite(i):
	#$Sprite2.load(l[i])
	#$Sprite2.texture = load("res://Screens/ScreenTitleMenu/"+l[i]+".png")
	text.frame=i*2
	texthl.frame=i*2+1
	ToLoad=i

func set_by_name(n):
	var j = l.find(n)
	if j != -1:
		text.frame=j*2
		texthl.frame=j*2+1
	#$Sprite2.texture = load("res://Screens/ScreenTitleMenu/"+n+".png")
	pass
	
onready var t = $Tween
#onready var hl = $TextureRect2
onready var hl = $Sprite

func _ready():
	set_sprite(ToLoad)
	#$Sprite2.load(l[ToLoad])


func _on_TextureRect2_mouse_entered():
	t.stop_all()
	#hl.modulate.a=1.0
	texthl.visible=true
	t.interpolate_property(hl,"toDraw",0,360.0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property(hl,"modulate:a",null,1.0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.interpolate_property(texthl,"modulate:a",0,1.0,.2,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()
	#hl.texture.region.position.y=0
	#print($TextureRect2.texture)
	#pass # Replace with function body.


func _on_TextureRect2_mouse_exited():
	t.stop_all()
	t.interpolate_property(hl,"modulate:a",null,0,.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	t.start()
	#texthl.modulate.a=0.0
	texthl.visible=false
	
	#hl.toDraw=0
	#hl.texture.region.position.y=104
	#pass # Replace with function body.


func _on_TextureRect2_gui_input(event):
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed) or (event is InputEventScreenTouch and event.index==1):
		emit_signal("clicked")

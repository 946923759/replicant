extends TextureRect

var music_database
func _ready():
	music_database = SoundTest.load_music_database()
	self.modulate.a = 0.0
	self.visible=true
	#print($Label.get("custom_fonts/font").get_string_size("Lorem Ipsum whatever"))

func songChangedMessageCommand(newSong:String):
	#self.x = get_viewport().get_visible_rect().size.x - self.rect_size.x
	var t:SceneTreeTween = get_tree().create_tween()
	#t.tween_callback()
	
	var track_name = newSong
	for v in music_database:
		if v.file_name.begins_with(newSong):
			track_name = v.original_name
	var label_size = $Label.get("custom_fonts/font").get_string_size(track_name).x + 200
	#print(label_size)
	
	t.tween_property($Label, "text", track_name, 0.0)
	t.tween_property(self,"rect_position:x",get_viewport().get_visible_rect().size.x - label_size, 0.0)
	t.tween_property(self,"modulate:a",1.0, .5).from(0.0)
	t.tween_property(self,"rect_position:x",get_viewport().get_visible_rect().size.x, .5).set_delay(1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

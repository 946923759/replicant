extends Control

"""
The super epic gallery screen written by Amaryllis Works!
HOW TO USE:
	1. Create your categories in the GALLERY category.
	2. Add the images to each category. Each entry is an array, because some images are similar to each other.
	   For now, only 15 entries can fit (Unless you make the container smaller).
	   YOUR IMAGES MUST BE IN THE BACKGROUNDS FOLDER!
	3. Make a GridContainer for each gallery category. Hint: Press Ctrl+D to duplicate it.
	   The position of the GridContainer does not matter, the engine will move them all to GalleryBase and hide them.
	4. Render your thumbanils for the "thumb" directory.
	   Hint: for f in *.png; do convert "$f" -resize 320x "../thumb/011_$f"; done
	
	The gallery entries will be unlocked automatically. When you see an image during
	the VN, it will be unlocked for the gallery. There is no need to use any commands
	to unlock an image.
	If you would like to manually unlock something (Maybe as a bonus), add it to
	Globals.playerData['CGunlock'].
"""

var GALLERY = {
	"Base":[
		['009/001_1280x720'],
		['009/002_1280x720'],
		['009/003_1280x720'],
		['009/005_1280x720'],
		['009/008_1280x720'],
		['009/012_1280x720'],
		
	],
	"Outdoors1":[
		['009/004_1280x720','009/013_1280x720'],
		['009/014_1280x720','009/015_1280x720'],
		['009/047_1280x720','009/039_1280x720']
	],
	"Outdoors2":[
		['009/064_1280x720','009/065_1280x720']
	],
	"BronyaSeele":[
		['009/021_1280x720'],
		['009/029_1280x720'],
		['009/030_1280x720'],
		['009/048_1280x720'],
		['009/050_1280x720'],
		['009/037_1280x720'],
		['009/054_1280x720'],
		['009/055_1280x720'],
		['009/057_1280x720'],
		['009/069_1280x720']
	],
	"Others":[
		['009/023_1280x720'],
		['009/022_1280x720','009/041_1280x720'],
		['009/024_1280x720'],
		['009/034_1280x720','009/035_1280x720','009/036_1280x720'],
		['009/049_1280x720'],
		['009/040_1280x720'],
		['009/031_1280x720','009/053_1280x720'],
		['009/056_1280x720'],
		['009/070_1280x720'],
		['009/071_1280x720'],
		['009/072_1280x720'],
		['009/073_1280x720'],
		['011/030_1280x720'],
		['011/023_1280x720']
	],
	"Misc":[
		['CG054_waifu2x_art_noise0_scale_tta_1'],
		['007/005_1280x720'],
		['009/074_1280x720'],
		['011/029_1280x720'],
		['007/013_1280x720']
	]
}

onready var galleryFullscreen:Control = $GalleryFullscreen
onready var t:Tween = $Tween
var GalleryObject = preload("res://Screens/ScreenGallery/GalleryObject.tscn")

export(bool) var mute_music_in_debug=true

#var unlockCache:Array = []
func is_image_unlocked(s:String)->bool:
	var unlockList = Globals.playerData['CGunlock']
	#unlockList = ['009/001_1280x720','009/008_1280x720']
	#return true
	return (s in unlockList)

func _ready():
	#print(Globals.playerData['CGunlock'])
	if OS.is_debug_build() == false or mute_music_in_debug==false:
		$AudioStreamPlayer.load_song("Significance");
	
	#Remove template objects
	#$Galleries/GalleryBase.get_child(0).visible=false
	#$Galleries/GalleryBase.get_child(1).visible=false

	galleryFullscreen.visible=false
	
	var galleryBasePos:Vector2=get_node("Galleries/GalleryBase").rect_position
	
	for k in GALLERY:
		var galleryActorFrame:GridContainer = get_node("Galleries/Gallery"+k)
		for i in range(len(GALLERY[k])):
			var galleryEntry:Array = GALLERY[k][i]
			var m = GalleryObject.instance()
			var thumbName = galleryEntry[0].replace("/","_")
			galleryActorFrame.add_child(m)
			
			var unlockedEntries:Array = []
			for g in galleryEntry:
				if is_image_unlocked(g):
					unlockedEntries.append(g)
			m.setUnlockedCount(len(unlockedEntries),len(galleryEntry),unlockedEntries)
			m.icon.loadVNBG("thumb/"+thumbName)
			if len(unlockedEntries)>0:
				m.icon.connect("gui_input",self,"gallery_icon_clicked_wrapper",[m])
		if galleryActorFrame.name!="GalleryBase":
			galleryActorFrame.rect_position=galleryBasePos
			galleryActorFrame.visible=false
			
	for i in range($Sections.get_child_count()):
		var c:Control = $Sections.get_child(i)
		toggle_section_highlighted(c,i==0)
		c.get_node("TextureRect2").connect("gui_input",self,"set_gallery_input_wrapper",[c.name])
	pass

func toggle_section_highlighted(c:Control,visible:bool=false):
	c.get_node("TextureRect").visible=visible
	c.get_node("TextureRect2").visible=!visible

func set_gallery_to(name:String):
	for i in range($Sections.get_child_count()):
		var c:Control = $Sections.get_child(i)
		toggle_section_highlighted(c,c.name==name)
	for gallery in get_node("Galleries").get_children():
		gallery.visible=(gallery.name == "Gallery"+name)
	$Click.play()

func set_gallery_input_wrapper(event:InputEvent,name:String):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		set_gallery_to(name)


#GALLERY FULL SCREEN IMAGE HANDLING HERE
var currentFullscreenImages:Array = []
var currentFullscreenImage:int=0

func galleryFull_LoadImages(arr:Array):
	var arrLen = len(arr)
	for i in range(1,galleryFullscreen.get_child_count()):
		var c = galleryFullscreen.get_child(i)
		VisualServer.canvas_item_set_z_index(c.get_canvas_item(),4-i)
		#if !(c is smSprite):
		#	#print("not smSprite!")
		#	continue
			
		if (i-1) < arrLen:
			c.loadVNBG(arr[i-1]) #Skip black background
			c.visible=true
		else:
			c.visible=false
		#c.modulate.a=1.0

func galleryFull_OnCommand():
	galleryFullscreen.visible=true
	#galleryFullscreen.get_child(1).modulate.a=1.0
	t.interpolate_property(galleryFullscreen,"modulate:a",0,1,.5)

	#Stupid hack to stop it blending transparencies while tweenng visible
	galleryFullscreen.get_child(1).modulate.a=1.0
	for i in range(2,galleryFullscreen.get_child_count()):
		galleryFullscreen.get_child(i).modulate.a=0.0
		t.interpolate_property(galleryFullscreen.get_child(i),"modulate:a",null,1.0,0,Tween.TRANS_LINEAR,Tween.EASE_IN,.5)

	t.start()
func galleryFull_OffCommand():
	#galleryFullscreen.visible=true
	t.interpolate_property(galleryFullscreen,"modulate:a",1,0,.5)
	t.interpolate_property(galleryFullscreen,"visible",true,false,0,Tween.TRANS_LINEAR,Tween.EASE_IN,.5)
	t.start()
	
func galleryFull_NextImage():
	if t.is_active():
		return
	if currentFullscreenImage < len(currentFullscreenImages)-1:
		t.interpolate_property(galleryFullscreen.get_child(currentFullscreenImage+1),"modulate:a",null,0,.5)
		t.start()
		#print("Modulate galleryObj "+String(currentFullscreenImage)+" to 0")
		currentFullscreenImage+=1
	else:
		galleryFull_OffCommand()
	
	
func gallery_icon_clicked(entries:Array):
	$Click.play()
	currentFullscreenImages=entries
	currentFullscreenImage=0
	galleryFull_LoadImages(currentFullscreenImages)
	galleryFull_OnCommand()

func gallery_icon_clicked_wrapper(event:InputEvent,galleryObject):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		gallery_icon_clicked(galleryObject.unlockedEntries)
		
		#print(GALLERY[galleryKey][galleryIndex])

func _on_TextureRect2_mouse_entered():
	#print("Mouse entered")
	pass # Replace with function body.


func _on_GalleryFullscreen_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		galleryFull_NextImage()
	pass # Replace with function body.


func _on_BackButton_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		#get_tree().change_scene("res://TitleScreen.tscn")
		$smScreenInOut.OffCommand("ScreenTitleMenu")

extends Control

export (String) var PrevScreen
export (String) var NextScreen
export (bool) var HandlePhysicalBButton=true
export (bool) var HandleRightClickAsB=false
export (bool) var HandlePhysicalAButton=false
export (bool) var ThisScreenIsAnOverlay=false
#export (bool) var ShowBackButton=true

onready var fadeOut = $smScreenInOut
onready var backButton = get_node_or_null("BackButton")
onready var debugOverlay = $CanvasLayer/smQuad/VBoxContainer

func _ready():
	$CanvasLayer/smQuad.visible=false
	#$CanvasLayer/Watermark.visible = OS.is_debug_build() and $CanvasLayer/Watermark.visible
	$smScreenInOut.visible=(!ThisScreenIsAnOverlay)
	if backButton and !backButton.visible:
		backButton.mouse_filter=Control.MOUSE_FILTER_IGNORE
	debugOverlay.get_node("LabelReload").text = "KEY 2: Reload - "+self.name
	
	var labelPrev = debugOverlay.get_node("LabelPrev")
	labelPrev.text = "KEY 4: Send PrevScreen - "+self.PrevScreen
	if PrevScreen=="":
		labelPrev.modulate=Color.dimgray
		
	var labelNext = debugOverlay.get_node("LabelNext")
	labelNext.text = "KEY 5: Send NextScreen - "+self.NextScreen
	if NextScreen=="":
		labelNext.modulate=Color.dimgray
	
	var scrNameNode = $CanvasLayer/smQuad/LabelScreenName
	if ThisScreenIsAnOverlay:
		scrNameNode.text = "[Overlay] "+self.name
	else:
		scrNameNode.text = self.name
		
	#VisualServer.canvas_item_set_z_index($ErrorDisplay.get_canvas_item(),999)

#func input(event):
#	#set_process_input()
#	pass

#var thisScreenIsCurrentlyHandlingInput:bool=true

func _input(_event):
	#if thisScreenIsCurrentlyHandlingInput==false:
	#	return
	
	if Input.is_action_just_pressed("ui_cancel") and HandlePhysicalBButton:
		$BackSound.play()
		OffCommandPrevScreen()
	elif HandleRightClickAsB and _event is InputEventMouseButton and _event.button_index == BUTTON_RIGHT and _event.pressed:
		$BackSound.play()
		OffCommandPrevScreen()
	elif (Input.is_action_just_pressed("ui_select") or Input.is_action_just_pressed("ui_pause")) and HandlePhysicalAButton:
		OffCommandNextScreen()
		
	var f3_is_held = Input.is_action_pressed("DebugButton3") #and $smScreenInOut.t.is_active()==false
	$CanvasLayer/smQuad.visible=f3_is_held
	if f3_is_held and _event is InputEventKey and _event.pressed:
		#if :
		#	return
		match _event.scancode:
			KEY_2:
				get_tree().reload_current_scene()
			KEY_4:
				OffCommandPrevScreen()
			KEY_5:
				OffCommandNextScreen()

func OverlayScreenExited():
	set_process_input(true)
	print("[SCREENMAN] ["+name+"] The screen on top of this one exited, handling input again.")
	

func AddNewScreenOnTop(scr:String) -> Node:
	var packedScene = load(Globals.SCREENS[scr])
	var inst = packedScene.instance()
	inst.ThisScreenIsAnOverlay=true
	add_child(inst)
	inst.ThisScreenIsAnOverlay=true
	#thisScreenIsCurrentlyHandlingInput=false
	set_process_input(false)
	inst.connect("tree_exited",self,"OverlayScreenExited")
	print("[SCREENMAN] ["+name+"] Pushed screen "+scr+" on top.")
	return inst

func OffCommandNextScreen(ns:String=NextScreen)->bool:
	if ThisScreenIsAnOverlay:
		OffCommandOverlay()
	elif ns != "":
		print("Tweening out, dest is "+ns)
		return fadeOut.OffCommand(ns, self.name)
		#return true
	
	else:
		ReportScriptError("NextScreen for "+self.name+" is not defined.")
		printerr("NextScreen for "+self.name+" is not defined.")
	return false

func OffCommandPrevScreen()->bool:
	if ThisScreenIsAnOverlay:
		OffCommandOverlay()
	elif PrevScreen != "":
		fadeOut.OffCommand(PrevScreen, self.name)
		return true
	else:
		ReportScriptError("PrevScreen for "+self.name+" is not defined.")
		printerr("PrevScreen for "+self.name+" is not defined.")
	return false

func OffCommandOverlay():
	fadeOut.t.interpolate_property(self,"modulate:a",null,0,.5)
	fadeOut.t.start()
	yield(fadeOut.t,"tween_completed")
	#print("[SCREENMAN] ["+name+"] ScreenOff emitted for this overlay, will be disposed of.")
	queue_free()

#If Android back button pressed
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		$BackSound.play()
		OffCommandPrevScreen()

func _on_BackButton_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1):
		$BackSound.play()
		OffCommandPrevScreen()

func ReportScriptError(errorMessage:String):
	var errDisp = $CanvasLayer/ErrorDisplay
	var tw = errDisp.get_node("Tween")
	var q = errDisp.get_node("smQuad")
	var text = errDisp.get_node("RichTextLabel")
	
	text.text = errorMessage
	text.rect_position.y = q.rect_size.y-text.rect_size.y
	
	tw.interpolate_property(errDisp,"rect_position:y",-q.rect_size.y,-q.rect_size.y+text.rect_size.y,.3)
	tw.interpolate_property(errDisp,"rect_position:y",-q.rect_size.y+text.rect_size.y,-q.rect_size.y,.3,Tween.TRANS_LINEAR,Tween.EASE_IN,3)
	tw.start()

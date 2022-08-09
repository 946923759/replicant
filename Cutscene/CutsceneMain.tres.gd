extends Control

"""
This one file is CC-BY-NC-SA 4.0 instead of GPLv3
That means NO COMMERCIAL USE! Contact me for commercial use.
https://creativecommons.org/licenses/by-nc-sa/4.0/
- Amaryllis Works
"""

var time: float = 0.0
var waitForAnim: float = 0.0
#onready var TEXT_SPEED: float = max(50,1)

var parent_node

#const nightShader = preload("res://ParticleEffects/NightShader.tres")
#We assign in _ready() in case something wants to supply its own backgrounds
onready var backgrounds:Control = $Backgrounds
var lastBackground:smSprite
enum BG_TWEEN {
	DEFAULT,
	FADE,
	IMMEDIATE,
	NONE
}

var curPos: int = -1
var isFullscreenMessageBox:bool = false
var shouldTextBoxBeVisible:bool=true

"""var message=[
	[OPCODES.PORTRAITS,"Nyto_7","pic_UMP9"],
	[OPCODES.SPEAKER,"UMP9"],
	[OPCODES.MSG,"This is the first string"]
]"""
export(PoolStringArray) var standalone_message
export(bool) var automatically_advance_text = false
export(bool) var dim_the_background_if_standalone = true
var message: Array

onready var PORTRAITMAN:Control = $Portraits


var lastMusic:AudioStreamPlayer

#Array of 2D arrays
var textHistory:Array=[]
onready var historyActor=$CutsceneHistory


onready var text:RichTextLabel = $CenterContainer/textActor_better
onready var textboxSpr = $CenterContainer/textBackground
onready var speakerActor = $CenterContainer/SpeakerActor

onready var fsContainer:Control = $FSMode_ActorFrame
onready var fsText:RichTextLabel = $FSMode_ActorFrame/TextActor


var choiceResult:int=-1

func push_back_from_idx_one(arr,arr2): #Arrays are passed by reference so there's no need to return them, but whatever
	for i in range(1,arr2.size()):
		arr.push_back(arr2[i])
	return arr

#This function will load backgrounds and music in advance.
#It will also split the delimiter in advance.
func preparse_string_array(arr,delimiter:String="|")->bool:
	var musicToLoad:Array=[]
	var soundsToLoad:Array=[]
	var backgrounds_to_load:Array=[]
	message = []
	#Should return false if delimiter is incorrect
	for s in arr:
		#print("'"+s+"'")
		var splitString = s.split(delimiter,true) #,true,1
		#print(splitString)
		#This changes the command order, so it probably shouldn't be preprocessed right?
		if splitString[0].begins_with('/'): #Chaosoup's idea, since typing two opcodes every time was getting obnoxious
			message.push_back(['speaker',splitString[0].substr(1)])
			message.push_back(push_back_from_idx_one(['msg'],splitString))
			#var a = ['msg']
			#message.push_back([OPCODES.MSG,splitString[1]])
			continue
		match splitString[0]:
			"bg":
				if splitString[1] != "black" and splitString[1] != "none" and !(splitString[1] in backgrounds_to_load):
					backgrounds_to_load.append(splitString[1])
			"music":
				#message.push_back([OPCODES.MUSIC,splitString[1]])
				if !(splitString[1] in musicToLoad):
					musicToLoad.append(splitString[1])
			"se":
				if !(splitString[1] in soundsToLoad):
					soundsToLoad.append(splitString[1])
			"speaker":
				if splitString.size() < 2:
					splitString=['speaker','']
				#print(splitString)
		message.push_back(splitString)
					
	for i in range(len(backgrounds_to_load)):
		var bgToLoad = backgrounds_to_load[i]
		
		#var nightFilter = false
		if "," in bgToLoad:
			#nightFilter = bgToLoad.split(",")[1].to_lower()=="true"
			bgToLoad = bgToLoad.split(",")[0]
		var c = Color(1,1,1,0)
		var s = Def.Sprite({
			modulate=c,
			Texture=bgToLoad,
			cover=true,
			#rect_size=Vector2(1920,1080),
			name=bgToLoad.replace("/","$"),
			mouse_filter=2
		})
		#s.set_rect_size()
		#if nightFilter:
		#	s.material=nightShader
		backgrounds.add_child(s)
		VisualServer.canvas_item_set_z_index(s.get_canvas_item(),-10)
	backgrounds.connect("resized",self,"set_rect_size")
	
	
	for m in musicToLoad:
		#print("m "+m)
		var s = Def.Sound({
			File=m,
			name=m.replace("/","$"),
			bus="Music"
		})
		$Music.add_child(s)
	for m in soundsToLoad:
		#It still returns an smSound... The name is not very good
		#The only difference is that sound effects load from the Sounds folder and don't loop
		var s = Def.SoundEffect({
			File=m,
			name=m.replace("/","$"),
			bus="SFX"
		})
		$SoundEffects.add_child(s)
	return true


var msgColumn:int=1
var lastPortraitTable = {}
var ChoiceTable:PoolStringArray = []
var matchedNames = []
onready var tw = $TextboxTween
func advance_text()->bool:
	curPos+=1
	var tmp_speaker = "NoSpeaker!!"
	var tmp_tn = ""
	while true:
		if curPos >= message.size():
			print("Fix your code, idiot. You already hit the end.")
			print("curPos: "+String(curPos))
			print("message size: "+String(message.size()))
			return false
		var curMessage = message[curPos]
		
		match curMessage[0]:
			'tn':
				if msgColumn < curMessage.size():
					tmp_tn=curMessage[msgColumn]
			'dim':
				PORTRAITMAN.dim_idx(int(curMessage[1]))
			'msg':
				#Do it up here since /setDispChr command might override it.
				text.visible_characters=0
				var tmp_txt:String
				print(curMessage)
				if msgColumn < curMessage.size():
					tmp_txt = curMessage[msgColumn]
				elif curMessage.size() > 1:
					#print("msg ")
					tmp_txt= curMessage[1]
				#else:
					
				while tmp_txt.begins_with("/"):
					if tmp_txt.begins_with("/hl["):
						var cmd_end = tmp_txt.find("]", 4);
						#print("end bracket "+String(cmd_end))
						if cmd_end==-1:
							printerr("Bad hl command!")
							break
						else:
							var val = int(tmp_txt.substr(4,cmd_end-4))
							PORTRAITMAN.hl_idx(val)
							#print("Highlighting at idx "+String(val))
							tmp_txt=tmp_txt.substr(cmd_end+1,len(tmp_txt))
							#print(tmp_txt)
#					elif tmp_txt.begins_with("/dim["):
#						var cmd_end = tmp_txt.find("]", 5);
#						if cmd_end==-1:
#							printerr("Bad dim command!")
#							break
#						else:
#							var val = int(tmp_txt.substr(4,cmd_end-4))
#							PORTRAITMAN.dim_idx(val)
#							#print("Highlighting at idx "+String(val))
#							tmp_txt=tmp_txt.substr(cmd_end+1,len(tmp_txt))
					elif tmp_txt.begins_with("/close"):
						closeTextbox(tw,waitForAnim)
						waitForAnim+=.3
						tmp_txt=tmp_txt.substr(6,len(tmp_txt))
					elif tmp_txt.begins_with("/open"):
						openTextbox(tw,waitForAnim)
						waitForAnim+=.3
						tmp_txt=tmp_txt.substr(5,len(tmp_txt))
					elif tmp_txt.begins_with('/setDispChr['):
						var cmd_end = tmp_txt.find("]", 5);
						if cmd_end!=-1:
							#We have to subtract setDispChr characters
							text.visible_characters=int(tmp_txt.substr(4,cmd_end-4))
							tmp_txt=tmp_txt.substr(cmd_end+1,len(tmp_txt))
							print(tmp_txt.substr(text.visible_characters,len(tmp_txt)))
							#print(val)
						else:
							break
					else:
						printerr("Unknown command used, giving up: "+tmp_txt)
						break
					
				text.bbcode_text = tmp_txt
				
				if curPos < message.size()-1 and message[curPos+1][0]=='choice':
					ChoiceTable = []
					for i in range(curPos+1,curPos+5): #5 choice limit
						var cMsg = message[i]
						if cMsg[0]!='choice':
							break
						if msgColumn < cMsg.size():
							ChoiceTable.push_back(cMsg[msgColumn])
						else:
							print("Current language is "+String(msgColumn)+", but this choice only had "+String(cMsg.size())+" languages to choose from")
							print(cMsg)
							ChoiceTable.push_back(cMsg[0])
					
				break #Stop processing opcodes and wait for user to click
			#Compatibility opcode for Girls' Frontline
			'msgbox_transition':
				closeTextbox(tw)
				openTextbox(tw,.3)
				waitForAnim+=.6
			'msgbox_close':
				if curMessage.size() > 1 and curMessage[1]=="instant":
					print("Removing tw")
					#tw.remove(textboxSpr,"interpolate_property")
					tw.remove_all()
					closeTextbox(tw,0,0)
				else:
					closeTextbox(tw)
					waitForAnim+=.3
			'msgbox_open':
				waitForAnim+=openTextbox(tw,waitForAnim)
				#waitForAnim+=.3
			'set_fs': #Should this close the textbox too?
				if curMessage[1].to_lower()=="true":
					tw.interpolate_property(fsContainer,"modulate:a",null,1,.3,Tween.TRANS_QUAD,Tween.EASE_IN,waitForAnim)
					isFullscreenMessageBox=true
					fsText.text=""
					fsContainer.visible=true
					#shouldTextBoxBeVisible=false
				else:
					tw.interpolate_property(fsContainer,"modulate:a",null,1,.3,Tween.TRANS_QUAD,Tween.EASE_IN,waitForAnim)
					isFullscreenMessageBox=false
					fsContainer.visible=false
					#shouldTextBoxBeVisible=true
				
			'match_names':
				matchedNames=push_back_from_idx_one([],curMessage)
			'speaker': 
				
				# I really didn't think this one through when I made /close and /open
				# a mini command instead of an opcode
				if waitForAnim>0:
					tw.interpolate_callback(self,.3,"shitty_interpolate_label",curMessage[1])
					#tw.interpolate_property($SpeakerActor,"text","null",tmp_speaker,0,Tween.TRANS_LINEAR,Tween.EASE_IN,.3)
				else:
					speakerActor.text=curMessage[1]
				tmp_speaker=curMessage[1] #Store it for text history
				if len(matchedNames) > 0:
					if curMessage[1].strip_edges()=="" and matchedNames[len(matchedNames)-1]=="_DIM_ALL_WHEN_EMPTY":
						for p in PORTRAITMAN.portraits:
							if p.is_active:
								p.dim()
								p.z_index = -1
					else:
						#print(matchedNames)
						for i in range(len(matchedNames)):
							if matchedNames[i]==curMessage[1]:
								print("Matched portrait "+curMessage[1]+" at idx "+String(i))
								for p in PORTRAITMAN.portraits:
									if p.idx==i:
										p.undim()
										p.z_index = 0
									elif p.is_active:
										p.dim()
										p.z_index = -1
								break
						#print("|"+matchedNames[i]+"| != |"+curMessage[1]+"|")
					#if curMessage[1].strip_edges()!="":
					#	print("Couldn't match "+curMessage[1]+ " in "+String(matchedNames))
				#print(speakerActor.text)
			'preload_portraits':
				PORTRAITMAN.preload_portraits(curMessage)
			'bg':
				var transition:String = curMessage[2].to_lower() if curMessage.size() > 2 else ""
				waitForAnim=backgrounds.setNewBG(curMessage[1].replace("/","$"),transition,waitForAnim)
			'bg_fade_out_in':
				var lastBackground = backgrounds.lastBackground
				if is_instance_valid(lastBackground):
					var seq := TweenSequence.new(get_tree())
					seq._tween.pause_mode = Node.PAUSE_MODE_PROCESS
					seq.append(lastBackground,'modulate:a',0,.5)
					seq.append(lastBackground,'modulate:a',1,.5)
					#lastBackground.hideActor(.5)
					#lastBackground.showActor(.5,.5)
					waitForAnim+=1
				else:
					print("lastBackground was null, can't fade a background when there isn't one!")
			'portraits':
				#Badly translated lua code
				#Duplicate curMessage while skipping the 0th element
				#because it is the opcode
				var new_table = [];
				for i in range(1,curMessage.size()):
					new_table.push_back(curMessage[i])
				#Trace(table_print(new_table))
				var relation = lastPortraitTable.duplicate()
				lastPortraitTable={} #Wipe table so there aren't a bunch of indexed 'false' portraits
				
				var numPortraits = 0
				for pos in range(new_table.size()):
					var portrait = new_table[pos].split(',',true)
					var pp:Array=[portrait[0],false,0] #[name,isMasked,offset]
					if portrait.size()>2:
						pp[2]=int(portrait[2])
					if portrait.size()>1:
						pp[1]=(portrait[1].to_lower()=='true')
					numPortraits+=1
					
					"""
					To use for next iteration, self.lastPortraitTable will get copied to relation. Anything that has a new position
					will get the false value in relation overwritten. If any portrait that existed in lastPortraitTable doesn't exist
					in this one, it will still have the value of false.
					"""
					lastPortraitTable[portrait[0]]=false
					relation[portrait[0]]=[pos,pp[1],pp[2]] #[pos,isMasked,offset]
					
				PORTRAITMAN.update_portrait_positions_wip(relation,numPortraits)
			'emote':
				var lastUsed = PORTRAITMAN.get_portrait_from_sprite(curMessage[1])
				if lastUsed != null:
					lastUsed.cur_expression = int(curMessage[2])
					lastUsed.update()
					#print("Set new portrait sprite")
				else:
					print("There is no active portrait named "+curMessage[1])
			#This is a NOP since the msg handler checks if there is a choice right after.
			#"But what if I want a choice without any text?"
			#I don't know, fuck you
			'choice', 'nop','label':
				pass
			#OPCODES.JMP:
			#	curPos+=curMessage[1]
			'jmp','condjmp_c':
				#if curMessage[0] == OPCODES.CONDJMP_CHOICE:
				#	print("Processing CONDJUMP... cRes is "+String(choiceResult)+", jump if "+String(curMessage[2]))
				#else:
				#	print("processing LONGJUMP")
				if curMessage[0] == 'jmp' or int(curMessage[2])==choiceResult:
					#print(curMessage)
					var jumped:bool=false
					for i in range(curPos,message.size()):
						if message[i][0]=='label' and curMessage[1]==message[i][1]:
							curPos=i
							jumped=true
							break
					if !jumped:
						for i in range(0,curPos):
							if message[i][0]=='label' and curMessage[1]==message[i][1]:
								curPos=i
								jumped=true
					if !jumped:
						printerr("The label '"+curMessage[1]+"' was not found!")
				#Reset here?
				choiceResult=-1
			'music':
				var m = $Music.get_node_or_null(curMessage[1].replace("/","$"))
				if is_instance_valid(lastMusic):
					lastMusic.stop()
				if m!=null:
					print("Playing "+m.name)
					print(m.stream)
					m.play()
					lastMusic=m
				else:
					printerr("FIX YOUR MUSIC NAMES!! DON'T USE SPECIAL CHARACTERS! "+curMessage[1])
			'se':
				var se = $SoundEffects.get_node_or_null(curMessage[1].replace("/","$"))
				if se!=null:
					se.play()
			'stopmusic':
				if is_instance_valid(lastMusic):
					lastMusic.fade_music(float(curMessage[1]))
			"shake_camera":
				var howMuch:float = float(curMessage[1]) if len(curMessage) > 1 else 3.0
				backgrounds.shakeCamera(howMuch)
			_:
				printerr("Unknown opcode encountered: "+curMessage[0]+". It will be ignored and skipped.")
		curPos+=1
	
	#WHAT COULD POSSIBLY GO WRONG
	textHistory.push_back([speakerActor.text,text.text])
	$TN_Actor.visible=(tmp_tn!="")
	if tmp_tn!="":
		$TN_Actor/TranslationNote.text=tmp_tn
		#print($TN_Actor/TranslationNote.has_focus())
	var TEXT_SPEED=float(Globals['OPTIONS']['textSpeed']['value'])
	#print(TEXT_SPEED)
	if TEXT_SPEED<100:
		#print(1/TEXT_SPEED*(text.text.length()-text.visible_characters))
		tw.interpolate_property(text,"visible_characters",text.visible_characters,text.text.length(),
			1/TEXT_SPEED*(text.text.length()-text.visible_characters),
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			waitForAnim
		)
	else: #Fake tween that just waits for waitForAnim
		tw.interpolate_property(text,"visible_characters",text.visible_characters,text.text.length(),
			0,
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			waitForAnim
		)
	#This is kind of a hack, the history depends on the text actor but FSbox just appends to the same node,
	text.visible=not isFullscreenMessageBox
	if isFullscreenMessageBox:
		var newText = text.text
		var numNewLines = fsText.text.count("\n")
		var startingLength = fsText.text.length()-numNewLines #WHY????
		var newFSText = fsText.text+"\n"+text.text
		#fsText.text=newFSText
		print("Size of old text was "+String(startingLength)+", tweening to "+String(newFSText.length())+", "+String(text.text.length()+1)+" "+text.text)
		tw.interpolate_property(fsText,"visible_characters",startingLength,newFSText.length(),
			1/TEXT_SPEED*(newFSText.length()-startingLength),
			Tween.TRANS_LINEAR,
			Tween.EASE_IN,
			waitForAnim
		)
		fsText.visible_characters=startingLength
		fsText.text=newFSText
	print("Tweening... waitForAnim is "+String(waitForAnim))
	tw.start()
	waitForAnim=0
	#If there was any processing done at all, this should be true
	return true


func closeTextbox(t:Tween,delay:float=0,animTime:float=.3)->float:
	#t.append(textboxSpr,'scale:y',0,.3).set_trans(Tween.TRANS_QUAD)
	#print("Closing textbox with delay of "+String(delay))
	t.interpolate_property(textboxSpr,"rect_scale:y",1,0,animTime,Tween.TRANS_QUAD,Tween.EASE_IN,delay)
	t.interpolate_property(speakerActor,"rect_scale:y",1,0,animTime,Tween.TRANS_QUAD,Tween.EASE_IN,delay)
	t.interpolate_property(speakerActor,"modulate:a",1,0,animTime,Tween.TRANS_QUAD,Tween.EASE_IN,delay)
	shouldTextBoxBeVisible=false
	return animTime

func openTextbox(t:Tween,delay:float=0)->float:
	#print("Opening textbox with delay of "+String(delay))
	t.interpolate_property(textboxSpr,"rect_scale:y",0,1,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,delay)
	t.interpolate_property(speakerActor,"rect_scale:y",0,1,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,delay)
	t.interpolate_property(speakerActor,"modulate:a",0,1,.3,Tween.TRANS_QUAD,Tween.EASE_OUT,delay)
	shouldTextBoxBeVisible=true
	return .3
	

onready var historyTween = $HistoryTween
#Updated every frame... Might be slow
#onready var screenWidth=Globals.gameResolution.x
func tween_in_history():
	isHistoryBeingShown=true
	historyActor.set_history(textHistory)
	#historyActor.OnCommand()
	#tw.stop_all()
	tw.stop(text,"visible_characters")
	closeTextbox(historyTween)
	historyTween.interpolate_property(historyActor,"rect_position:x",
		get_viewport().get_visible_rect().size.x*-1,0,.3,
		Tween.TRANS_QUAD,Tween.EASE_OUT,.2)
	historyTween.interpolate_property(text,"modulate:a",null,0,.3)
	historyTween.interpolate_property($historyQuad,"color:a",null,.8,.3)
	#$historyQuad.color.a=1.0
	#VisualServer.canvas_item_set_z_index($historyQuad.get_canvas_item(),100)
	#print($dim.visible)
	historyTween.start()
	
func tween_out_history():
	tw.resume(text,"visible_characters")
	openTextbox(historyTween,.2)
	historyTween.interpolate_property(historyActor,"rect_position:x",
		0,get_viewport().get_visible_rect().size.x*-1,.3,
		Tween.TRANS_QUAD,Tween.EASE_IN,0)
	historyTween.interpolate_property(text,"modulate:a",null,1,.3,
	Tween.TRANS_LINEAR,Tween.EASE_OUT,.2)
	historyTween.interpolate_property($historyQuad,"color:a",null,0,.3)
	historyTween.start()

func shitty_interpolate_label(s:String):
	#print("Now I set speaker to"+s+"!!")
	speakerActor.text=s
		
func set_rect_size():
	for child in $Backgrounds.get_children():
		child.set_rect_size()

func _ready():
	$OptionsScreen.visible=false
	$Choices.visible=false
	$FSMode_ActorFrame.visible=false
	VisualServer.canvas_item_set_z_index($bgFadeLayer.get_canvas_item(),-15)
	#$OptionsScreen.connect("options_closed",self,"_on_options_closed")
	#print("Text speed is "+String(TEXT_SPEED))
	set_process(false)
	#text = $textActor_better
	#text.visible_characters=0
	#portraits=[$Portrait1,$Portrait2,$Portrait3,$Portrait4,$Portrait5]

	#for p in portraits:
	#	p.modulate.a=0.0
	
	#TODO: Don't hardcode the dim quad! Make it fit to window size!
	
	#for debugging
#	init_([
#		'speaker speaker name',
#		'portrait pic_MAC10|Nyto_7',
#		"msg test message 1",
#		"msg test message 2"
#	],
#	null,
#	true)
	
	if len(standalone_message)!=0:
		init_(standalone_message,null,dim_the_background_if_standalone)



func init_(message, parent, dim_background = true,delim="|",msgColumn:int=1):
	if parent:
		parent_node = parent
	$dim.color.a=0
	textboxSpr.rect_scale.y=0
	tw.interpolate_property(textboxSpr,'rect_scale:y',null,1,.5,Tween.TRANS_QUAD,Tween.EASE_IN)
#	var t := TweenSequence.new(get_tree())
#	t._tween.pause_mode = Node.PAUSE_MODE_PROCESS
#	t.append(textboxSpr,'rect_scale:y',1,.5).set_trans(Tween.TRANS_QUAD)
#	if dim_background:
## warning-ignore:return_value_discarded
#		t.parallel().append($dim,'color:a',.6,.5).from_current()
	
	self.msgColumn=msgColumn
	preparse_string_array(message,delim)
	
	advance_text()
	set_process(true)

func end_cutscene():
	print("Hit the end. Now I will kill myself!")
	set_process(false)
	for p in PORTRAITMAN.portraits:
		if p.is_active:
			p.stop()
	#https://github.com/godot-extended-libraries/godot-next/pull/50
	var seq := TweenSequence.new(get_tree())
	seq._tween.pause_mode = Node.PAUSE_MODE_PROCESS
# warning-ignore:return_value_discarded
	seq.append(textboxSpr,'rect_scale:y',0,.5).set_trans(Tween.TRANS_QUAD)
	seq.parallel().append(text,'modulate:a',0,.3)
	seq.parallel().append(speakerActor,'modulate:a',0,.3)
	#seq.parallel().append($SpeakerActor,'position:y',600,.3)
	seq.parallel().append($dim,'color:a',0,.5).set_trans(Tween.TRANS_QUAD)
	#seq.parallel().append($PressStartToSkip,'rect_position:x',-$PressStartToSkip.rect_size.x,.5).set_trans(Tween.TRANS_QUAD)
	#seq.parallel().append($PressStartToSkip,'modulate:a',0,.5)
# warning-ignore:return_value_discarded
	seq.connect("finished",self,"end_cutscene_2")
	#seq.tween_callback()
	#.from_current()
	#queue_free()

# Honestly, this is a mess. When it was in lua the input handling and the VN processing
# wasn't coupled together, instead vntext:advance() would be called and if it returned
# false it meant there was no more text.
var manualTriggerForward=false

var isHistoryBeingShown=false
var isOptionsScreenOpen=false
var isWaitingForChoice=false


#limit skip speed
var frameLimiter:float=0.0

func _process(delta):
	
	if isHistoryBeingShown or isOptionsScreenOpen:
		return
	if Input.is_action_just_pressed("ui_pause"):
		end_cutscene()
	elif Input.is_action_just_pressed("ui_cancel"):
		$OptionsScreen.visible=true
		$OptionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		isOptionsScreenOpen=true
	elif Input.is_action_just_pressed("DebugButton1"):
		get_tree().reload_current_scene()
	
	if isWaitingForChoice:
		if Input.is_action_just_pressed("ui_up"):
			$Choices.input_up()
		elif Input.is_action_just_pressed("ui_down"):
			$Choices.input_down()
		elif Input.is_action_just_pressed("ui_select") and $Choices.selection!=-1:
			choiceResult=$Choices.selection+1
			$Choices.visible=false
			ChoiceTable=[]
			text.visible_characters=0
			#advance_text()
			isWaitingForChoice=false
			#$Choices.input
		return
	
	if Input.is_action_pressed("vn_skip") and isWaitingForChoice==false:
		frameLimiter+=delta
		if frameLimiter > .1 and curPos < message.size():
			advance_text()
			tw.stop_all()
			if shouldTextBoxBeVisible:
				textboxSpr.rect_scale.y=1
				speakerActor.rect_scale.y=1
				speakerActor.modulate.a=1
			text.visible_characters = text.text.length()
			frameLimiter=0
	
	var forward = Input.is_action_just_pressed("ui_select") or manualTriggerForward
	if text.visible_characters >= text.text.length():
		if ChoiceTable.size()>0:
			$Choices.setChoices(ChoiceTable)
			$Choices.visible=true
			isWaitingForChoice=true
		elif forward:
			print("advancing")
			if curPos >= message.size() or !advance_text():
				end_cutscene()
	else:
		if forward:
			tw.stop_all()
			if shouldTextBoxBeVisible:
				textboxSpr.rect_scale.y=1
				speakerActor.rect_scale.y=1
				speakerActor.modulate.a=1
			text.visible_characters = text.text.length()

			if isFullscreenMessageBox:
				fsText.visible_characters=fsText.text.length()
		else:
			if Input.is_action_pressed("ui_cancel"):
				tw.playback_speed=2.0
			else:
				tw.playback_speed=1.0
	manualTriggerForward=false
	
#Fucking piece of shit game engine
#Refer to https://docs.godotengine.org/en/stable/tutorials/scripting/overridable_functions.html?highlight=_unhandled_input#overridable-functions
#or https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-unhandled-input
func _unhandled_input(event):
	if isWaitingForChoice:
		return
			
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_1:
		if isHistoryBeingShown:
			print("Hiding history!")
			tween_out_history()
			isHistoryBeingShown=false
		elif isFullscreenMessageBox==false: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			print("Displaying history!!!")
			tween_in_history()
			#historyActor.set_history(textHistory)
		#isHistoryBeingShown=!isHistoryBeingShown
		
func _input(event):
	if isOptionsScreenOpen:
		return
	if (event is InputEventMouseButton and event.is_pressed()) and event.button_index==BUTTON_WHEEL_UP and isHistoryBeingShown==false:
		if isFullscreenMessageBox==false: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			tween_in_history()
			get_tree().set_input_as_handled()
		#elif event.button_index==BUTTON_WHEEL_UP:
		#		tween_out_history()
		#		isHistoryBeingShown=false
	elif (event is InputEventMouseButton and event.is_pressed() and event.button_index==2) or (event is InputEventScreenTouch and event.index==1):
		if isHistoryBeingShown:
			tween_out_history()
			isHistoryBeingShown=false
			get_tree().set_input_as_handled()
		else:
			$OptionsScreen.visible=true
			$OptionsScreen.OnCommand()
			#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
			isOptionsScreenOpen=true
			get_tree().set_input_as_handled()
			
		#else:
		#	print("Unknown mouse button pressed or don't know how to handle")

#If Android back button pressed
#TODO: Ignore if cutscene playing
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST and isOptionsScreenOpen==false:
		$OptionsScreen.visible=true
		$OptionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		isOptionsScreenOpen=true

signal cutscene_finished()
func end_cutscene_2():
	if parent_node:
		get_tree().paused = false
	else:
		print("No parent node...")
	emit_signal("cutscene_finished")
	queue_free()

func _on_SkipButton_pressed():
	end_cutscene()

func _on_dim_gui_input(event):
	if isWaitingForChoice:
		if event is InputEventMouseMotion:
			$Choices.input_cursor(event.position)
		elif (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) or (
			event is InputEventScreenTouch and event.is_pressed()
		):
			if $Choices.input_cursor(event.position,true):
				choiceResult=$Choices.selection+1
				$Choices.visible=false
				ChoiceTable=[]
				advance_text()
				isWaitingForChoice=false
	
	if (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) or (
		event is InputEventScreenTouch and event.is_pressed()
	):
		print("clicked")
		manualTriggerForward=true


#func _on_Choices_mouse_selected_choice(selection):
#	choiceResult=selection
#	$Choices.visible=false
#	ChoiceTable=[]
#	advance_text()
#	isWaitingForChoice=false


func _on_OptionsScreen_options_closed():
	#print("User closed options")
	isOptionsScreenOpen=false
	$OptionsScreen.visible=false

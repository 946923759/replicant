extends Control

"""
This one file is CC-BY-NC-SA 4.0 instead of GPLv3
That means NO COMMERCIAL USE! Contact me for commercial use.
https://creativecommons.org/licenses/by-nc-sa/4.0/
- Amaryllis Works
"""
var PrevScreen = "ScreenSelectChapter"


var time: float = 0.0
var waitForAnim: float = 0.0
#onready var TEXT_SPEED: float = max(50,1)

var parent_node

#const nightShader = preload("res://ParticleEffects/NightShader.tres")
#We assign in _ready() in case something wants to supply its own backgrounds
onready var backgrounds:Control = $Backgrounds
#var lastBackground:smSprite
enum BG_TWEEN {
	DEFAULT,
	FADE,
	IMMEDIATE,
	NONE
}

var curPos: int = -1

enum MSGBOX_DISP_MODE {
	NORMAL,
	POP_UP,
	FULLSCREEN
}
var messageBoxMode=MSGBOX_DISP_MODE.NORMAL

var shouldTextBoxBeVisible:bool=true
var choiceResult:int=-1

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

onready var tw:Tween = $TextboxTween
onready var txtTw:SceneTreeTween


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
	var videos_to_load:Array=[]
	message = []
	
	var prevIndentLevel = 0
	#Should return false if delimiter is incorrect
	for ii in range(len(arr)):
		
		#print("'"+s+"'")
		var splitString = arr[ii].split(delimiter,true) #,true,1
		
		var indentLevel = 0
		for i in range(len(splitString[0])):
			if splitString[0][i]==" ":
				pass
			else:
				splitString[0]=splitString[0].substr(i)
				indentLevel=i
				#print(indentLevel)
				break
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
			"bg_video":
				if !(splitString[1] in videos_to_load):
					videos_to_load.append(splitString[1])
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
			"extend":
				var msg_to_append:Array = []
				for i in range(len(message)-1,0,-1):
					#print(message[i])
					if message[i][0]=="msg":
						msg_to_append=message[i]
						break
				if len(msg_to_append) > 0:
					#if splitString.size() < msg_to_append.size():
						
					
					for mi in range(1, splitString.size()):
						if mi < msg_to_append.size() and !msg_to_append.empty():
							var setDispChr = msg_to_append[mi].find('/setDispChr[')
							if setDispChr == 0:
								var cmd_end = msg_to_append[mi].find("]", 12); #skip scanning in "/setDispChr" section
								if cmd_end!=-1:
									print(cmd_end)
									splitString[mi] = "/setDispChr["+String(len(msg_to_append[mi])-cmd_end) \
									+ "]" \
									+ msg_to_append[mi].substr(cmd_end+1,len(msg_to_append[mi])) \
									+ splitString[mi]
#								else:
#									printerr("No cmd_end!")
							else:
								splitString[mi] = "/setDispChr["+String(len(msg_to_append[mi]))+"]"+msg_to_append[mi]+splitString[mi]
						else:
							printerr("extend was bigger than message size! "+String(splitString.size())+" > "+String(msg_to_append.size()))
							#splitString[mi] = + splitString[mi]
					splitString = push_back_from_idx_one(['msg'],splitString)
				else:
					splitString = push_back_from_idx_one(['msg'],splitString)
				#Skip adding the original command.
				#continue
				#print(splitString
			"condjmp_c":
				splitString=["condjmp",splitString[1],"__choice__",splitString[2]]
			"if":
				splitString=["condjmp_neg","__fi__",splitString[1],splitString[2]]
			"else","else:":
				for i in range(len(message)-1,0,-1):
					#print(message[i])
					if message[i][0]=="condjmp_neg":
						message[i][1]="__else__"
						break
				message.push_back(["jmp","__fi__"])
				splitString=["label","__else__"]
		
		if indentLevel < prevIndentLevel and splitString[1] != "__else__":
			message.push_back(["label","__fi__"])
		prevIndentLevel=indentLevel
		message.push_back(splitString)
	
	
	var c = Color(1,1,1,0)
	for i in range(len(backgrounds_to_load)):
		var bgToLoad = backgrounds_to_load[i]
		
		#var nightFilter = false
		if "," in bgToLoad:
			#nightFilter = bgToLoad.split(",")[1].to_lower()=="true"
			bgToLoad = bgToLoad.split(",")[0]
		var s = Def.Sprite({
			modulate=c,
			Texture=bgToLoad,
			cover=true,
			#rect_size=Vector2(1920,1080),
			name=bgToLoad.replace("/","$"),
			mouse_filter=2 # mouse_filter: Ignore
		})
		s.set_meta("file_name",bgToLoad)
		#s.set_rect_size()
		#if nightFilter:
		#	s.material=nightShader
		backgrounds.add_child(s)
		s.set_rect_size()
		VisualServer.canvas_item_set_z_index(s.get_canvas_item(),-10)
	for i in range(len(videos_to_load)):
		var bgToLoad = videos_to_load[i]
		var s = Def.Video({
			modulate=c,
			Texture=bgToLoad,
			cover=true,
			name=bgToLoad.replace("/","$"),
			mouse_filter=2 # mouse_filter: Ignore
		})
		s.set_meta("file_name",bgToLoad)
		backgrounds.add_child(s)
		#s.set_rect_size()
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
var cutsceneVars:Dictionary = {}

var matchedNames = []
func advance_text()->bool:
	curPos+=1
	var tmp_speaker = "NoSpeaker!!"
	var tmp_tn = ""

	#If we don't remove, the previous text tween can start overwriting the current one
	txtTw = get_tree().create_tween()

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
						closeTextbox(txtTw)
						tmp_txt=tmp_txt.substr(6,len(tmp_txt))
					elif tmp_txt.begins_with("/open"):
						openTextbox(txtTw)
						tmp_txt=tmp_txt.substr(5,len(tmp_txt))
					elif tmp_txt.begins_with('/setDispChr['):
						var cmd_end = tmp_txt.find("]", 5);
						if cmd_end!=-1:
							#We have to subtract setDispChr characters
							#Well, actually we don't since int() ignores non integer values
							text.visible_characters=int(tmp_txt.substr(12,cmd_end-1))
							tmp_txt=tmp_txt.substr(cmd_end+1,len(tmp_txt))
							print(tmp_txt.substr(text.visible_characters,len(tmp_txt)))
							#print(val)
						else:
							break
					else:
						printerr("Unknown command used, giving up: "+tmp_txt)
						break
				
				#Failsafe. Maybe not needed?
				if text.visible_characters<0:
					text.visible_characters=tmp_txt.length()
				text.bbcode_text = tmp_txt
				

					
				break #Stop processing opcodes and wait for user to click
			#'setvar':
				
			#Compatibility opcode for Girls' Frontline
			'msgbox_transition':
				closeTextbox(txtTw)
				openTextbox(txtTw)
			'msgbox_close':
				if curMessage.size() > 1 and curMessage[1]=="instant":
					print("Removing tw")
					#tw.remove(textboxSpr,"interpolate_property")
					tw.remove_all()
					closeTextbox(txtTw,0)
				else:
					closeTextbox(txtTw)
			'msgbox_open':
				openTextbox(txtTw)
			'popup':
				var popup = $PopupContainer
				if curMessage[1].to_lower()=="off" or curMessage[1].to_lower()=="false":
					messageBoxMode=MSGBOX_DISP_MODE.NORMAL
					openTextbox(txtTw)
					
					txtTw.parallel().tween_property(popup,"rect_scale:y",0.0,.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					txtTw.parallel().tween_property(popup,"modulate:a",0.0,.2)

					
				elif curMessage.size() > 2:
					#Should x position be scaled to device screen width?
					
					var pos = Vector2(float(curMessage[1]),float(curMessage[2]))
					if pos.x <0:
						pos.x = randi()%int(Globals.SCREEN_CENTER_X)+Globals.SCREEN_CENTER_X/2-popup.rect_size.x/2
					if pos.y<0:
						pos.y = randi()%int(Globals.SCREEN_CENTER_Y)+Globals.SCREEN_CENTER_Y/2
					#print(pos)
					
					if messageBoxMode!=MSGBOX_DISP_MODE.POP_UP:
						if shouldTextBoxBeVisible:
							closeTextbox(txtTw,.2)
						else:
							print("Textbox already seems to be closed, not closing for popup.")
					popup.rect_scale=Vector2(1.5,0.0)
					#This seems correct at first, but the textbox has to be centered.
					#And we can't center it until after we know the text and the size of the text.
					#I guess it doesn't matter for now since only random positions are used.
					popup.rect_position=pos
					popup.visible=true
					#var seq := get_tree().create_tween()
					txtTw.parallel().tween_property(popup,"rect_scale",Vector2(1.0,1.0),.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					txtTw.parallel().tween_property(popup,"modulate:a",1.0,.2)
					messageBoxMode=MSGBOX_DISP_MODE.POP_UP
					shouldTextBoxBeVisible=false
					
			'set_fs': #Should this close the textbox too?
				if curMessage[1].to_lower()=="true":
					tw.interpolate_property(fsContainer,"modulate:a",null,1,.3,Tween.TRANS_QUAD,Tween.EASE_IN,waitForAnim)
					messageBoxMode=MSGBOX_DISP_MODE.FULLSCREEN
					fsText.text=""
					fsContainer.visible=true
					#shouldTextBoxBeVisible=false
				else:
					tw.interpolate_property(fsContainer,"modulate:a",null,1,.3,Tween.TRANS_QUAD,Tween.EASE_IN,waitForAnim)
					messageBoxMode=MSGBOX_DISP_MODE.NORMAL
					fsContainer.visible=false
					#shouldTextBoxBeVisible=true
			#It was totally necessary to add an opcode that will only be used one time
			'set_outline':
				if curMessage[1].to_lower()=="true":
					text.set("custom_colors/font_color_shadow",Color.black)
				else:
					text.set("custom_colors/font_color_shadow",Color.transparent)
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
			'bg','bg_video':
				var transition:String = curMessage[2].to_lower() if curMessage.size() > 2 else ""
				waitForAnim=backgrounds.setNewBG(curMessage[1].replace("/","$"),transition,waitForAnim)
			'bg_fade_out_in':
				var lastBackground = backgrounds.lastBackground
				if is_instance_valid(lastBackground):
					var seq := get_tree().create_tween()
					seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
					seq.tween_property(lastBackground,'modulate:a',0,.5)
					seq.tween_property(lastBackground,'modulate:a',1,.5)
					#lastBackground.hideActor(.5)
					#lastBackground.showActor(.5,.5)
					waitForAnim+=1
				else:
					print("lastBackground was null, can't fade a background when there isn't one!")
#			'fg_fade':
#					$FadeToBlack.modulate.a=0
#					$FadeToBlack.visible=true
#					var seq := get_tree().create_tween()
#					seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#					seq.tween_property($FadeToBlack,'modulate:a',1,.5)
#					seq.tween_property($FadeToBlack,'modulate:a',0,.5)
#					waitForAnim=max(waitForAnim,1)
			'flash':
				$FadeToBlack.color=Color.white
				$FadeToBlack.visible=true
				#print("A")
				tw.interpolate_property($FadeToBlack,"color:a",null,0,.02,Tween.TRANS_LINEAR,Tween.EASE_IN,.02)
				tw.interpolate_property($FadeToBlack,"color",null,Color(0,0,0,0),.02,Tween.TRANS_BACK,Tween.EASE_IN,.04)
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
			'choice':
				if msgColumn < curMessage.size():
					ChoiceTable.push_back(curMessage[msgColumn])
				else:
					print("Current language is "+String(msgColumn)+", but this choice only had "+String(curMessage.size())+" languages to choose from")
					print(curMessage)
					ChoiceTable.push_back(curMessage[0])
			
			'nop','label':
				pass
			'var':
				var varName = curMessage[1]
				#var varToSet = 0
				var varToCheck = curMessage[2].to_lower()
				if varToCheck=="true":
					cutsceneVars[varName]=1
				elif varToCheck=="false":
					cutsceneVars[varName]=0
				else:
					match varToCheck[0]:
						
						'"':
							var cmd_end = varToCheck.rfind("\"");
							if cmd_end>0:
								cutsceneVars[varName] = varToCheck.substr(1,cmd_end)
							else:
								printerr("String is malformed in var command, missing end")
						'&':
							var bitflag = int(varToCheck.substr(1))
							if !(varName in cutsceneVars):
								cutsceneVars[varName] = (1<<bitflag)
							elif typeof(cutsceneVars[varName])==TYPE_INT:
								cutsceneVars[varName] = cutsceneVars[varName] | (1<<bitflag)
							else:
								printerr("Tried to set a bitflag, but variable is not an integer.")
						'~':
							var bitflag = int(varToCheck.substr(1))
							if !(varName in cutsceneVars):
								cutsceneVars[varName] = 0 #If the variable doesn't exist, it's zero...
							elif typeof(cutsceneVars[varName])==TYPE_INT:
								cutsceneVars[varName] = cutsceneVars[varName] & ~(1<<bitflag)
							else:
								printerr("Tried to set a bitflag, but variable is not an integer.")
						_:
							if varToCheck.is_valid_integer():
								cutsceneVars[varName]=int(varToCheck)
							else:
								printerr("Failed to deduce type for variable "+varToCheck)
#			'jmp_short':
#				curPos+=int(curMessage[1])
			'condjmp','condjmp_neg','jmp':
				var labelToJump = curMessage[1]
				
				var varName="____"
				if curMessage[0]!="jmp":
					varName = curMessage[2]
				var SHOULD_JUMP:bool=false
				
				if varName=="____":
					SHOULD_JUMP=true
				elif varName=="__choice__":
					print("PROCESSING CONDJUMP... DEST IS "+labelToJump+", TEST "+curMessage[3]+" == "+String(choiceResult))
					SHOULD_JUMP=(choiceResult==int(curMessage[3]))
					print("Should jump? "+String(SHOULD_JUMP))
				elif (varName in cutsceneVars):
					var varToCheck = curMessage[3].to_lower()
					if varToCheck=="true":
						SHOULD_JUMP=cutsceneVars[varName]==1
					elif varToCheck=="false":
						SHOULD_JUMP=cutsceneVars[varName]==0
					else:
						if varToCheck[0]=='"':
							
							var cmd_end = varToCheck.rfind("\"");
							if cmd_end>0:
								if typeof(cutsceneVars[varName])==TYPE_STRING:
									SHOULD_JUMP = cutsceneVars[varName] == varToCheck.substr(1,cmd_end)
							else:
								printerr("String is malformed in var command, missing end")
						elif typeof(cutsceneVars[varName])==TYPE_INT:
							match varToCheck[0]:
								'&':
									var bitflag = int(varToCheck.substr(1))
									SHOULD_JUMP = cutsceneVars[varName] & (1<<bitflag)
								'~':
									var bitflag = int(varToCheck.substr(1))
									SHOULD_JUMP= ~cutsceneVars[varName] & (1<<bitflag)
								'>':
									SHOULD_JUMP = cutsceneVars[varName] > int(varToCheck)
								'<':
									SHOULD_JUMP = cutsceneVars[varName] < int(varToCheck)
								'!':
									SHOULD_JUMP = cutsceneVars[varName] != int(varToCheck)
								_:
									if varToCheck.is_valid_integer():
										SHOULD_JUMP = cutsceneVars[varName]==int(varToCheck)
									else:
										printerr("Failed to deduce type for variable "+varToCheck)
						else:
							print("Tried to compare an integer with a string. Good job, genius.")
				else:
					printerr("Hey moron, the variable you're checking hasn't been set.")
				
				if curMessage[0]=="condjmp_neg":
					SHOULD_JUMP=!SHOULD_JUMP
					print("negative Should jump? "+String(SHOULD_JUMP))
				
				if SHOULD_JUMP:
					var jumped:bool=false
					for i in range(curPos,message.size()):
						if message[i][0]=='label' and labelToJump==message[i][1]:
							curPos=i
							jumped=true
							break
					if !jumped:
						for i in range(0,curPos):
							if message[i][0]=='label' and labelToJump==message[i][1]:
								curPos=i
								jumped=true
					if !jumped:
						printerr("The label '"+labelToJump+"' was not found!")
					else:
						print("Jumped to message: "+String(message[curPos]))

#			'jmp':
##				if curMessage[0] == "condjmp_c":
##					print("PROCESSING CONDJUMP... DEST IS "+curMessage[1]+", TEST "+curMessage[2]+" == "+String(choiceResult))
#				if true:
#					#print(curMessage)
#					var jumped:bool=false
#					for i in range(curPos,message.size()):
#						if message[i][0]=='label' and curMessage[1]==message[i][1]:
#							curPos=i
#							jumped=true
#							break
#					if !jumped:
#						for i in range(0,curPos):
#							if message[i][0]=='label' and curMessage[1]==message[i][1]:
#								curPos=i
#								jumped=true
#					if !jumped:
#						printerr("The label '"+curMessage[1]+"' was not found!")
			'music':
				var m = $Music.get_node_or_null(curMessage[1].replace("/","$"))
				if is_instance_valid(lastMusic):
					lastMusic.stop()
				if m!=null:
					print("Playing "+m.name)
					#print(m.stream)
					m.volume_db=0
					m.play()
					lastMusic=m
				else:
					printerr("FIX YOUR MUSIC NAMES!! DON'T USE SPECIAL CHARACTERS! "+curMessage[1])
			'se':
				var se = $SoundEffects.get_node_or_null(curMessage[1].replace("/","$"))
				if se!=null:
					se.play()
			'stopmusic', 'stop_music':
				if is_instance_valid(lastMusic):
					if len(curMessage) > 1:
						lastMusic.fade_music(float(curMessage[1]))
					else:
						lastMusic.stop_music()
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
		$TN_Actor.set_text(tmp_tn)
	var TEXT_SPEED=float(Globals['OPTIONS']['textSpeed']['value'])
	#print(TEXT_SPEED)
	if TEXT_SPEED<100:
		
		#print(1/TEXT_SPEED*(text.text.length()-text.visible_characters))
		txtTw.tween_property(text,"visible_characters",text.text.length(),
			1/TEXT_SPEED*(text.text.length()-text.visible_characters)
		).set_delay(waitForAnim)
		#txtTw.interpolate_property(text,"visible_characters",text.visible_characters,text.text.length(),
		#	1/TEXT_SPEED*(text.text.length()-text.visible_characters),
		#	Tween.TRANS_LINEAR,
		#	Tween.EASE_IN,
		#	waitForAnim
		#)
	else: #Fake tween that just waits for waitForAnim
		txtTw.tween_property(text,"visible_characters",text.text.length(),0).set_delay(waitForAnim)
		#txtTw.interpolate_property(text,"visible_characters",text.visible_characters,text.text.length(),
		#	0,
		#	Tween.TRANS_LINEAR,
		#	Tween.EASE_IN,
		#	waitForAnim
		#)
	#This is kind of a hack, the history depends on the text actor but FSbox just appends to the same node,
	text.visible=(messageBoxMode==MSGBOX_DISP_MODE.NORMAL)
	if messageBoxMode==MSGBOX_DISP_MODE.FULLSCREEN:
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
	elif messageBoxMode==MSGBOX_DISP_MODE.POP_UP:
		var popupText = $PopupContainer/RichTextLabel
		popupText.bbcode_text = "[center]"+text.bbcode_text+"[/center]"
		popupText.visible_characters=text.visible_characters
		$PopupContainer.rect_size.y = popupText.get_content_height()+7
		if TEXT_SPEED<100:
			txtTw.parallel().tween_property(popupText,"visible_characters",popupText.text.length(),
				1/TEXT_SPEED*(popupText.text.length()-popupText.visible_characters)
			)
		else: #Fake tween that just waits for waitForAnim
			txtTw.parallel().tween_property(popupText,"visible_characters",popupText.text.length(),0).set_delay(waitForAnim)

	print("Tweening... waitForAnim is "+String(waitForAnim))
	tw.start()
	waitForAnim=0
	#If there was any processing done at all, this should be true
	return true


func closeTextbox(t:SceneTreeTween,animTime:float=.3,_rect_scale:float=0.0)->float:
	#t.append(textboxSpr,'scale:y',0,.3).set_trans(Tween.TRANS_QUAD)
	#print("Closing textbox with delay of "+String(delay))
	if animTime<=0:
		textboxSpr.rect_scale.y=_rect_scale
		speakerActor.rect_scale.y=_rect_scale
		speakerActor.modulate.a=_rect_scale
	else:
		t.tween_property(textboxSpr,"rect_scale:y",_rect_scale,animTime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(speakerActor,"rect_scale:y",_rect_scale,animTime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(speakerActor,"modulate:a",_rect_scale,animTime)
	shouldTextBoxBeVisible=false
	return animTime

func openTextbox(t:SceneTreeTween,animTime:float=.3)->float:
	closeTextbox(t,animTime,1.0)
	shouldTextBoxBeVisible=true
	return animTime


#onready var historyTween = $HistoryTween
#Updated every frame... Might be slow
#onready var screenWidth=Globals.gameResolution.x
func tween_in_history():
	isHistoryBeingShown=true
	historyActor.set_history(textHistory)
	#historyActor.OnCommand()
	#tw.stop_all()
	#tw.stop(text,"visible_characters")
	var historyTween = get_tree().create_tween()
	closeTextbox(historyTween)
	#get_viewport().get_visible_rect().size.x*-1
	historyTween.parallel().tween_property(historyActor,"rect_position:x",
		0,.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.2)
	historyTween.parallel().tween_property(text,"modulate:a",0,.3)
	historyTween.parallel().tween_property($historyQuad,"color:a",.8,.3)
	#$historyQuad.color.a=1.0
	#VisualServer.canvas_item_set_z_index($historyQuad.get_canvas_item(),100)
	#print($dim.visible)
	
func tween_out_history():
	#tw.resume(text,"visible_characters")
	var historyTween = get_tree().create_tween()
	openTextbox(historyTween,.2)
	historyTween.parallel().tween_property(historyActor,"rect_position:x",
		get_viewport().get_visible_rect().size.x*-1,.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	historyTween.parallel().tween_property(text,"modulate:a",1,.3)
	historyTween.parallel().tween_property($historyQuad,"color:a",0,.3)
	

func shitty_interpolate_label(s:String):
	#print("Now I set speaker to"+s+"!!")
	speakerActor.text=s
		
func set_rect_size():
	print(backgrounds.get_child_count())
	for child in backgrounds.get_children():
		child.set_rect_size()

func _ready():
	$FadeToBlack.visible=true
	
	$OptionsScreen.visible=false
	$Choices.visible=false
	$FSMode_ActorFrame.visible=false
	$AutoModeIndicator.visible=false
	VisualServer.canvas_item_set_z_index($bgFadeLayer.get_canvas_item(),-15)
	$OptionsScreen.connect("options_closed",self,"_on_OptionsScreen_options_closed")
	#print("Text speed is "+String(TEXT_SPEED))
	
	$CenterContainer/textBackground.color.a = Globals.OPTIONS['bgOpacity']['value']/100.0
	
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
	#set_rect_size()
	#tw.interpolate_property($FadeToBlack,"modulate:a",null,0,.5)
	#tw.start()
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	seq.tween_property($FadeToBlack,"color:a",0,.5)


func init_(message_, parent, dim_background = true,delim="|",msgColumn:int=1):
	if parent:
		parent_node = parent
	$dim.color.a=0
	textboxSpr.rect_scale.y=0
	tw.interpolate_property(textboxSpr,'rect_scale:y',null,1,.5,Tween.TRANS_QUAD,Tween.EASE_IN)
#	var t := get_tree().create_tween()
#	t.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	t.append(textboxSpr,'rect_scale:y',1,.5).set_trans(Tween.TRANS_QUAD)
#	if dim_background:
## warning-ignore:return_value_discarded
#		t.parallel().append($dim,'color:a',.6,.5).from_current()
	
	self.msgColumn=msgColumn
	preparse_string_array(message_,delim)
	$CutsceneDebug.set_text(message)
	$CutsceneDebug.visible=false
	
	advance_text()
	set_process(true)

func end_cutscene():
	print("Hit the end. Now I will kill myself!")
	set_process(false)
	for p in PORTRAITMAN.portraits:
		if p.is_active:
			p.stop()
	
	#https://github.com/godot-extended-libraries/godot-next/pull/50
	var seq := get_tree().create_tween()
	seq.set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
# warning-ignore:return_value_discarded
	seq.tween_property(textboxSpr,'rect_scale:y',0,.5).set_trans(Tween.TRANS_QUAD)
	seq.parallel().tween_property(text,'modulate:a',0,.3)
	seq.parallel().tween_property(speakerActor,'modulate:a',0,.3)
	#seq.parallel().append($SpeakerActor,'position:y',600,.3)
	seq.parallel().tween_property($FadeToBlack,'color:a',1,.5).set_trans(Tween.TRANS_QUAD)
	#seq.parallel().append($PressStartToSkip,'rect_position:x',-$PressStartToSkip.rect_size.x,.5).set_trans(Tween.TRANS_QUAD)
	#seq.parallel().append($PressStartToSkip,'modulate:a',0,.5)
# warning-ignore:return_value_discarded
	seq.tween_callback(self,"end_cutscene_2")
	#seq.tween_callback()
	#.from_current()
	#queue_free()
	
signal cutscene_finished()
func end_cutscene_2():
	var needToSave:bool=false
	for c in backgrounds.get_children():
		var f = c.get_meta("file_name")
		if !(f in Globals.playerData['CGunlock']):
			print_debug("Unlocked CG "+f)
			Globals.playerData['CGunlock'].append(f)
			needToSave=true
	if needToSave:
		Globals.save_system_data()
	
	if parent_node:
		get_tree().paused = false
	else:
		print("No parent node...")
	emit_signal("cutscene_finished")
	queue_free()


# Honestly, this is a mess. When it was in lua the input handling and the VN processing
# wasn't coupled together, instead vntext:advance() would be called and if it returned
# false it meant there was no more text.
var manualTriggerForward=false
var autoModeActive:bool=false

var isHistoryBeingShown=false
var isOptionsScreenOpen=false
var isWaitingForChoice=false


#limit skip speed
var frameLimiter:float=0.0

func disableAutoMode():
	autoModeActive=false
	$AutoModeIndicator.stop()

func _process(delta):
	
	if isHistoryBeingShown:
		historyActor.process(delta)
		return
	elif isOptionsScreenOpen:
		$CenterContainer/textBackground.color.a = Globals.OPTIONS['bgOpacity']['value']/100.0
		#if Input.is_action_just_pressed("ui_select"):
		#	print("CutsceneMain: ui_select!")
		return
		
	if Input.is_action_just_pressed("ui_pause") or Input.is_action_just_pressed("ui_cancel"):
		disableAutoMode()
		$OptionsScreen.visible=true
		$OptionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		isOptionsScreenOpen=true
	elif Input.is_action_just_pressed("DebugButton1"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("DebugButton2"):
		$CutsceneDebug.visible=!$CutsceneDebug.visible
	
	if isWaitingForChoice:
		return
	
	if Input.is_action_pressed("vn_skip") and isWaitingForChoice==false:
		frameLimiter+=delta
		if frameLimiter > .1 and curPos < message.size():
			txtTw.kill()
			advance_text()
			tw.remove_all()
			if shouldTextBoxBeVisible:
				textboxSpr.rect_scale.y=1
				speakerActor.rect_scale.y=1
				speakerActor.modulate.a=1
			text.visible_characters = text.text.length()
			frameLimiter=0
			for p in PORTRAITMAN.portraits:
				if p.is_active:
					p.modulate.a=1
				else:
					p.modulate.a=0
	
	var forward = manualTriggerForward
#	if forward:
#		print("ManualTriggerForward")
	if text.visible_characters >= text.text.length(): #If finished displaying characters
		if ChoiceTable.size()>0:
			frameLimiter=0
			manualTriggerForward=false
			print("Set choices: "+String(ChoiceTable))
			$Choices.setChoices(ChoiceTable)
			$Choices.OnCommand()
			isWaitingForChoice=true
		elif forward:
			manualTriggerForward=false
			print("advancing")
			if curPos >= message.size() or !advance_text():
				end_cutscene()
		elif autoModeActive:
			frameLimiter+=delta
			if frameLimiter>2:
				manualTriggerForward=true
				frameLimiter=0
			elif OS.is_debug_build():
				$AutoModeIndicator/Label.text = String(frameLimiter)
	else: #Skip to finish
		if forward:
			tw.remove_all() #Why doesn't godot have finishtweening() wtf
			
			txtTw.kill()
			if shouldTextBoxBeVisible:
				openTextbox(txtTw,0)
			else:
				closeTextbox(txtTw,0)
			text.visible_characters = text.text.length()

			if messageBoxMode==MSGBOX_DISP_MODE.FULLSCREEN:
				fsText.visible_characters=fsText.text.length()
			elif messageBoxMode==MSGBOX_DISP_MODE.POP_UP: #Why was this using text.length in the first place?
				$PopupContainer/RichTextLabel.visible_characters=-1
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
			
	#if event is InputEventKey and event.is_pressed() and event.scancode == KEY_1:
	if Input.is_action_just_pressed("ui_select"):
		if autoModeActive:
			disableAutoMode()
		else:
			manualTriggerForward=true
		get_tree().set_input_as_handled()
	elif Input.is_action_just_pressed("vn_history"):
		disableAutoMode()
		if isHistoryBeingShown:
			print("Hiding history!")
			tween_out_history()
			isHistoryBeingShown=false
		elif messageBoxMode!=MSGBOX_DISP_MODE.FULLSCREEN and isOptionsScreenOpen==false: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			print("Displaying history!!!")
			tween_in_history()
			#historyActor.set_history(textHistory)
		#isHistoryBeingShown=!isHistoryBeingShown
		
func _input(event):
	if (event is InputEventMouseMotion):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if isOptionsScreenOpen:
		return
	#if (event is InputEventMouseButton and event.is_pressed()) and event.button_index==BUTTON_WHEEL_UP and isHistoryBeingShown==false:
	if Input.is_action_just_pressed("vn_history") and isHistoryBeingShown==false:
		if messageBoxMode!=MSGBOX_DISP_MODE.FULLSCREEN: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
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
			print("user right clicked to open options screen")
			$OptionsScreen.visible=true
			$OptionsScreen.OnCommand()
			#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
			isOptionsScreenOpen=true
			get_tree().set_input_as_handled()
	elif Input.is_action_just_pressed("vn_auto"):
		if autoModeActive:
			disableAutoMode()
		else:
			autoModeActive=true
			$AutoModeIndicator.play()
	#elif isHistoryBeingShown:
	#	historyActor.input(event)
		#else:
		#	print("Unknown mouse button pressed or don't know how to handle")

#If Android back button pressed
#TODO: Ignore if cutscene playing
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST and isOptionsScreenOpen==false:
		disableAutoMode()
		$OptionsScreen.visible=true
		$OptionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		isOptionsScreenOpen=true


func _on_SkipButton_pressed():
	end_cutscene()

func _on_dim_gui_input(event):
	if isWaitingForChoice:
		return
	
	if (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) or (
		event is InputEventScreenTouch and event.is_pressed()
	):
		print("clicked")
		if autoModeActive:
			disableAutoMode()
		else:
			manualTriggerForward=true

func _on_Choices_selected_choice(selection):
	choiceResult=$Choices.selection+1
	print("Choice result obtained, result was "+String(choiceResult))
	$Choices.OffCommand()
	ChoiceTable=[]
	advance_text()
	isWaitingForChoice=false


func _on_OptionsScreen_options_closed():
	print("User closed options")
	isOptionsScreenOpen=false
	$OptionsScreen.visible=false
	#print("New opacity is "+String(Globals.OPTIONS['bgOpacity']['value']/100.0))
	#$CenterContainer/textBackground.color.a = Globals.OPTIONS['bgOpacity']['value']/100.0

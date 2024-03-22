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
onready var optionsScreen = $OptionsScreen
const varDebugger = preload("res://Screens/CutsceneVarDebug/CutsceneVarDebug.tscn")
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
	var backgrounds_to_load:Dictionary={}
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
					backgrounds_to_load[splitString[1]] = true
			"bg_custom":
				#Strip {} from string
				#var loadStr = splitString[1].substr(1,len(splitString[1])-2)
				var loadStr = splitString[1]
				print("[BGLoader] loadStr: "+loadStr)

				var custom_bg_dict = {
					modulate=Color(1,1,1,0),
					mouse_filter=2 # mouse_filter: Ignore
				}
				for kvPair in loadStr.split(";"):
					var kvSplit = kvPair.split("=")
					var k = kvSplit[0].strip_edges()
					if not k:
						continue
					var v = kvSplit[1].strip_edges()
					
					var expression = Expression.new()
					expression.parse(v,["SCREEN_CENTER_X, SCREEN_CENTER_Y"])
					v = expression.execute([Globals.gameResolution.x/2.0, Globals.gameResolution.y/2.0])
#					if v.begins_with("Vector2"):
#						pass
#					elif v.begins_with("\""):
#						v = v.substr(1,len(v)-2)
#					elif v.is_valid_integer():
#						v = int(v)
#					elif v.is_valid_float():
#						v = float(v)
					
					custom_bg_dict[k] = v
				if !("name" in custom_bg_dict):
					custom_bg_dict['name']=custom_bg_dict['Texture'].replace("/","$")
				print("Generated "+String(custom_bg_dict))
				backgrounds_to_load[custom_bg_dict['name']] = custom_bg_dict
				
				#Substitute in a normal 'bg' command so it will show at runtime
				splitString = ['bg',custom_bg_dict['name']]
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
				splitString=["condjmp_neg","__fi__",splitString[1],splitString[2].rstrip(":")]
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
	for bgToLoad in backgrounds_to_load:
		#var bgToLoad = backgrounds_to_load[i]
		
		
		#var nightFilter = false
		if "," in bgToLoad:
			#nightFilter = bgToLoad.split(",")[1].to_lower()=="true"
			bgToLoad = bgToLoad.split(",")[0]
			
		var s:TextureRect
		if typeof(backgrounds_to_load[bgToLoad]) == TYPE_DICTIONARY:
			s = Def.Sprite(backgrounds_to_load[bgToLoad])
			s.set_meta("unlock_cg",false)
		else:
			s = Def.Sprite({
				modulate=c,
				Texture=bgToLoad,
				cover=true,
				#rect_size=Vector2(1920,1080),
				name=bgToLoad.replace("/","$"),
				mouse_filter=2 # mouse_filter: Ignore
			})
			s.set_meta("unlock_cg",true)
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
		print("Loaded "+m+" as "+s.name)
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

# I think at some point there can be something that
# re-executes everything based on previously made
# choices, because dumping and loading the state
# seems kind of pointless
# Also the portrait sprites aren't preloaded
# because of this...
func dump_state() -> Dictionary:
	if curPos<=0:
		return {}
	var state = {
		# This probably won't break since variables are cached.
		'position':curPos-1,
		'portraits':PORTRAITMAN.get_all_portrait_idx(),
		'expressions':{},
		'background':backgrounds.lastBackgroundName,
		'variables':cutsceneVars,
		'speaker':speakerActor.text,
		'match_names':matchedNames,
		#'music':
	}
	if lastMusic and lastMusic.playing:
		state['music'] = lastMusic.name
	#Maybe deep copy not needed
	return Globals.deep_copy(state)

func load_state(d: Dictionary):
	curPos = d['position']
	PORTRAITMAN.update_portrait_positions_wip(d['portraits'])
	if d['background'] != "":
		backgrounds.setNewBG(d['background'],'immediate')
	cutsceneVars = d['variables']
	speakerActor.text = d['speaker']
	matchedNames = d['match_names']
	if d.has("music"):
		lastMusic = $Music.get_node_or_null(d['music'])
		if lastMusic:
			lastMusic.play()
		else:
			printerr("Couldn't find music node "+d['music'])

func process_jumps(messages:Array, curMessage:Array, cur_pos:int,speculative:bool=false)-> int:
	var labelToJump = curMessage[1]
	
	var varName="____"
	if curMessage[0] != "jmp":
		varName = curMessage[2]
		
	var SHOULD_JUMP:bool=false
	
	
	if varName=="____":
		SHOULD_JUMP=true
	elif varName=="__choice__":
		print("PROCESSING CONDJUMP... DEST IS "+labelToJump+", TEST "+curMessage[3]+" == "+String(choiceResult))
		SHOULD_JUMP=(choiceResult==int(curMessage[3]))
		print("Should jump? "+String(SHOULD_JUMP))
	elif curMessage[3].to_lower()=="null":
		#print("Checking NULL... ",varName," is null? ",!(varName in cutsceneVars))
		SHOULD_JUMP = !(varName in cutsceneVars)
	elif (varName in cutsceneVars):
		var varToCheck = curMessage[3].to_lower()
		if varToCheck=="true":
			SHOULD_JUMP=cutsceneVars[varName] >= 0 # Because it SHOULD be possible to check > 0 the wacky C way
		elif varToCheck=="false":
			SHOULD_JUMP=cutsceneVars[varName] == 0
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
	# Don't print if this is speculative execution 
	# because it's possible the variable hasn't been set yet
	elif speculative==false:
		printerr("Hey moron, the variable you're checking hasn't been set: "+varName)
	
	if curMessage[0]=="condjmp_neg":
		SHOULD_JUMP=!SHOULD_JUMP
		print("negative Should jump? "+String(SHOULD_JUMP))
	
	if SHOULD_JUMP:
		#var jumped:bool=false
		for i in range(curPos,messages.size()):
			if messages[i][0]=='label' and labelToJump==message[i][1]:
				return i
		for i in range(0,curPos):
			if messages[i][0]=='label' and labelToJump==message[i][1]:
				return i
		printerr("The label '"+labelToJump+"' was not found!")
	return cur_pos
	
"""
It would be impossible to determine when to display choices
without executing ahead until it finds another message.
Because otherwise you could have something like a jump that
jumps to a table of choices OR another message.
"""
func runahead_process_choices(tmp_msgs:Array, cur_pos:int=1):
	"""
	TODO: This doesn't work because then you can't have a choice, a message,
	and then a jump.
	...Or I guess you can just repeat the message in each label.
	"""
	choiceResult = -1
	#var starting_pos = cur_pos
	
	var choice_table = []
	while true:
		if cur_pos >= tmp_msgs.size():
			break
		#elif cur_pos < starting_pos:
		#	printerr("choice runahead went backwards. This might cause an infinite loop, so giving up.")
		#	break
		var curMessage = tmp_msgs[cur_pos]
		#print(cur_pos)
		match curMessage[0]:
			'msg':
				break
			'choice':
				if msgColumn < curMessage.size():
					choice_table.push_back(curMessage[msgColumn])
				else:
					print("Current language is "+String(msgColumn)+", but this choice only had "+String(curMessage.size())+" languages to choose from")
					print(curMessage)
					choice_table.push_back(curMessage[0])
			'condjmp','condjmp_neg','jmp':
				var tmp_pos = process_jumps(tmp_msgs,curMessage,cur_pos,true)
				if tmp_pos < cur_pos:
					printerr("It should not be possible for the choice runahead to go backwards. Giving up.")
					printerr("Errored out at position "+String(cur_pos)+", attempted to jump to "+String(tmp_pos))
					break
				else:
					cur_pos = tmp_pos
		cur_pos+=1
	#print("Break execution at "+String(cur_pos))
	#print(choice_table)
	return choice_table

class TextDelay:
	var delayBeforeTween:float=0.0
	var numChars:int=0
	
	func _to_string() -> String:
		return "[TextDelay] Delay: "+String(delayBeforeTween)+", length: "+String(numChars)

var msgColumn:int=1
var lastPortraitTable = {}

var ChoiceTable:PoolStringArray = []
var cutsceneVars:Dictionary = {}

var matchedNames = []
func advance_text()->bool:
	curPos+=1
	
	#Why does godot say it's unused when it's not???
# warning-ignore:unused_variable
	var tmp_speaker = "NoSpeaker!!"
	var tmp_tn = ""

	#If we don't remove, the previous text tween can start overwriting the current one
	txtTw = get_tree().create_tween()
	
	#This is a 2D array for custom text pauses, ex. Hello {w=1}World
	#delay before executing, tween towards num chars
	var textPauses = []

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
				
				var hasVar = tmp_txt.find("%")
				if hasVar != -1:
					var endTagPos:int = -1
					for jjjj in range(hasVar+1,tmp_txt.length()):
						if tmp_txt[jjjj]==" ": #This also means no %% necessary like renpy
							break
						elif tmp_txt[jjjj]=="%":
							endTagPos = jjjj
							break
					if endTagPos != -1:
						#print(endTag-hasVar)
						var varName = tmp_txt.substr(hasVar+1,endTagPos-hasVar-1)
						print("Got story var "+varName)
						if cutsceneVars.has(varName):
							tmp_txt = tmp_txt.substr(0,hasVar) + String(cutsceneVars[varName]) + tmp_txt.substr(endTagPos+1)
							pass
						else:
							printerr("Variable "+varName+" used in script, but not declared yet. Ignoring.")
				
				#OH BOY HERE WE GO
				#So first we have to find where there is a pause
				#Then we push numChars into the previous array... But this is very tricky
				#because bbcode needs to be stripped out first in order to calculate the
				#correct time
				# Actually, I can just re-use waitForAnim... It's not like there's anything
				# else to use it at this point
				var prevDelay:float = waitForAnim
				while true:
					var bbcode_stripped_txt:String = Globals.strip_bbcode(tmp_txt)
					
					var twStruct = TextDelay.new()
					
					var pauseAt = bbcode_stripped_txt.find("{w=")
					if pauseAt != -1:
						#Push pauseAt to an array
						twStruct.numChars = pauseAt
						
						var endStr = bbcode_stripped_txt.find("}",pauseAt+3)
						#print("Parsed "+bbcode_stripped_txt.substr(pauseAt+3,endStr-pauseAt-3))
						
						var parsedPause = float(bbcode_stripped_txt.substr(pauseAt+3,endStr-pauseAt-3))
						twStruct.delayBeforeTween = prevDelay
						prevDelay=parsedPause
						
						textPauses.append(twStruct)
						
						#We need to replace the pauses in the original text,
						#which means more parsing work...
						var bb_beginStr = tmp_txt.find("{w=")
						var bb_endStr = tmp_txt.find("}",bb_beginStr+4)+1
						#print("Replacing string to "+tmp_txt.substr(0,bb_beginStr)+tmp_txt.substr(bb_endStr))
						tmp_txt = tmp_txt.substr(0,bb_beginStr)+tmp_txt.substr(bb_endStr)
						#tmp_txt.replace()
					else:
						#pauseAt should be equal to text length
						twStruct.numChars = bbcode_stripped_txt.length()
						twStruct.delayBeforeTween = prevDelay
						textPauses.append(twStruct)
						break
				for s in textPauses:
					print(s._to_string())
				
				#Failsafe. Maybe not needed?
				if text.visible_characters<0:
					text.visible_characters=tmp_txt.length()
				text.bbcode_text = tmp_txt
				
				#print("tmp_txt: "+tmp_txt)
				#print("bbcode: "+text.bbcode_text)
				ChoiceTable = runahead_process_choices(message,curPos+1)
				
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
				if transition=="tween":
					#This is += because it doesn't wait for previous tween... Probably could be better written
					if len(curMessage) > 5:
						waitForAnim+=backgrounds.setNewBG_tween(curMessage[1].replace("/","$"),curMessage[3],curMessage[4],curMessage[5])
					else:
						waitForAnim+=backgrounds.setNewBG_tween(curMessage[1].replace("/","$"),curMessage[3],curMessage[4])
				else:
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
				var portrait = PORTRAITMAN.get_portrait_from_sprite(curMessage[1])
				if portrait != null:
					portrait.cur_expression = curMessage[2]
					#print("Set new portrait sprite")
				else:
					print("There is no active portrait named "+curMessage[1])
			'tween':
				var portraitOrBackground = PORTRAITMAN.get_portrait_from_sprite(curMessage[2])
				if portraitOrBackground == null:
					portraitOrBackground = backgrounds.get_node_or_null(curMessage[2].replace("/","$"))
				if portraitOrBackground == null: #Attempt a second time using raw path in case this is a godot path and not a file path
					portraitOrBackground = backgrounds.get_node_or_null(curMessage[2])

				if portraitOrBackground != null:
					var tweenTime = portraitOrBackground.apply_sm_tween(curMessage[3])
					match curMessage[1]:
						"current","during":
							pass
						"before":
							waitForAnim+=tweenTime
						"after":
							# not implemented yet.
							pass
				else:
					printerr("[Cutscene] Tried to apply a tween on a portrait that doesn't exist: "+curMessage[2])
			#This is a NOP since the msg handler checks if there is a choice right after.
			#"But what if I want a choice without any text?"
			#I don't know, fuck you
			'choice','nop','label':
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
								cutsceneVars[varName] = varToCheck.substr(1,len(varToCheck)-2)
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
				var new_pos = process_jumps(message,curMessage,curPos)
				if new_pos != curPos:
					print("jumped to "+String(new_pos))
					curPos = new_pos
			'music':
				var m = $Music.get_node_or_null(curMessage[1].replace("/","$"))
				if is_instance_valid(lastMusic):
					lastMusic.stop()
				if m!=null:
					print("Playing "+m.name+" from path "+curMessage[1])
					#print(m.stream)
					m.volume_db=0
					m.play()
					lastMusic=m
				else:
					printerr("FIX YOUR MUSIC NAMES!! DON'T USE SPECIAL CHARACTERS! File "+curMessage[1]+" not found!")
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
				var magnitude:float = float(curMessage[1]) if len(curMessage) > 1 else 3.0
				backgrounds.shakeCamera(magnitude)
				if Input.get_connected_joypads().size() > 0:
					Input.start_joy_vibration(0,magnitude/5.0,magnitude/5.0,.4)
				#Pointless on mobile since you can't control the magnitude
				#elif OS.has_feature("mobile"):
				#	#Why is this in ms and the controller one in seconds?
				#	Input.vibrate_handheld(150)
			"vibrate":
				var duration:float = float(curMessage[1]) if len(curMessage) > 1 else 0.5
				if Input.get_connected_joypads().size() > 0:
					#print("Vibrate controller 0 for "+String(duration))
					Input.start_joy_vibration(0,.4,.4,duration)
				elif OS.has_feature("mobile"):
					#Why is this in ms and the controller one in seconds?
# warning-ignore:narrowing_conversion
					Input.vibrate_handheld(duration * 1000)
					#print("Vibrate mobile device for "+String(duration))
				#else:
				#	print("No controllers are connected, not vibrating")
			_:
				printerr("Unknown opcode encountered: "+curMessage[0]+". It will be ignored and skipped.")
		curPos+=1
	
	#WHAT COULD POSSIBLY GO WRONG
	textHistory.push_back([speakerActor.text,text.bbcode_text])
	$TN_Actor.visible=(tmp_tn!="")
	if tmp_tn!="":
		$TN_Actor.set_text(tmp_tn)
	var TEXT_SPEED=float(Globals['OPTIONS']['textSpeed']['value'])
	#print(TEXT_SPEED)
	if TEXT_SPEED<100:
		
		
#		txtTw.tween_property(text,"visible_characters",text.text.length(),
#			1/TEXT_SPEED*(text.text.length()-text.visible_characters)
#		).set_delay(waitForAnim)
		
		for di in len(textPauses):
			var delayStruct:TextDelay = textPauses[di]
			var time:float = 0.0
			if di==0:
				time = 1/TEXT_SPEED*(delayStruct.numChars-text.visible_characters)
			else:
				time = 1/TEXT_SPEED*(delayStruct.numChars-textPauses[di-1].numChars)
			
			
			txtTw.tween_property(text,"visible_characters",delayStruct.numChars,
				time
			).set_delay(delayStruct.delayBeforeTween)
		
		
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

func setTextboxStyle():
	var classic = $CenterContainer/textBackground
	var modern = $CenterContainer/textBackground_modern
	var modern2 = $CenterContainer/textBackground_modern2
	var frontline = $CenterContainer/textBackground_Frontline
	
	var l1 = [classic,modern,modern2,frontline]
	var l2 = ["Classic","Modern 1","Modern 2","Frontline"]
	var match_ = l2.find(Globals.OPTIONS['textboxStyle']['value'])
	for i in range(len(l1)):
		l1[i].visible=(match_==i)
		if i==match_:
			textboxSpr=l1[i]
	textboxSpr.modulate.a = Globals.OPTIONS['bgOpacity']['value']/100.0
	

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
	historyActor.isHandlingInput=true
	historyActor.set_history(textHistory)
	
	$UI_Top_Frontline/HBoxContainer/TextureButtonAuto.visible=false
	#$UI_Top_Frontline/HBoxContainer/TextureButtonHide.visible=false
	$UI_Top_Frontline/TextureButtonSkip.visible=false
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
	
	$UI_Top_Frontline/HBoxContainer/TextureButtonAuto.visible=true
	#$UI_Top_Frontline/HBoxContainer/TextureButtonHide.visible=true
	$UI_Top_Frontline/TextureButtonSkip.visible=true
	
	#tw.resume(text,"visible_characters")
	var historyTween = get_tree().create_tween()
	openTextbox(historyTween,.2)
	historyTween.parallel().tween_property(historyActor,"rect_position:x",
		get_viewport().get_visible_rect().size.x*-1,.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	historyTween.parallel().tween_property(text,"modulate:a",1,.3)
	historyTween.parallel().tween_property($historyQuad,"color:a",0,.3)
	isOtherScreenHandlingInput=false
	isHistoryBeingShown=false
	

func shitty_interpolate_label(s:String):
	#print("Now I set speaker to"+s+"!!")
	speakerActor.text=s
		
func set_rect_size():
	print(backgrounds.get_child_count())
	for child in backgrounds.get_children():
		child.set_rect_size()

func _ready():
	$FadeToBlack.visible=true
	
	optionsScreen.visible=false
	$Choices.visible=false
	$FSMode_ActorFrame.visible=false
	$AutoModeIndicator.visible=false
	VisualServer.canvas_item_set_z_index($bgFadeLayer.get_canvas_item(),-15)
	optionsScreen.connect("options_closed",self,"_on_OptionsScreen_options_closed")
	#print("Text speed is "+String(TEXT_SPEED))
	
	
	setTextboxStyle()
	
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
	
	$CutsceneDebug.visible=false
	#This is fine, auto mode doesn't work until process(true)
	toggleAutoMode(Globals.wasUsingAutoMode)
	$UI_Top_Frontline/HBoxContainer/TextureButtonAuto.pressed=Globals.wasUsingAutoMode


func init_(message_, parent, dim_background = true,delim="|",msgColumn:int=1):
	if parent:
		parent_node = parent
	#$dim.color.a=0
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
	
	advance_text()
	set_process(true)

func init_resume_(message_, parent, state, delim="\t", msgColumn:int=1):
	if parent:
		parent_node = parent
	#$dim.color.a=0
	textboxSpr.rect_scale.y=0
	tw.interpolate_property(textboxSpr,'rect_scale:y',null,1,.5,Tween.TRANS_QUAD,Tween.EASE_IN)

	self.msgColumn=msgColumn
	preparse_string_array(message_,delim)
	
	load_state(state)
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
	

# Called immediately after end_cutscene (look above)
signal cutscene_finished()
func end_cutscene_2():
	Globals.wasUsingAutoMode = automatically_advance_text
	
	var needToSave:bool=false
	for c in backgrounds.get_children():
		var f = c.get_meta("file_name")
		if !(f in Globals.playerData['CGunlock']):
			print_debug("Unlocked CG "+f)
			Globals.playerData['CGunlock'].append(f)
			needToSave=true
	
	
	var save_idx = Globals.get_episode_index(Globals.currentEpisodeData)
	var ch_idx = save_idx[0]
	var ep_idx = save_idx[1]
	if ch_idx >= 0 and ep_idx >= 0:
		var bit = Globals.playerData['completedChapters'][ch_idx]
		if (bit & 1<<ep_idx) == 0:
			needToSave=true
		Globals.playerData['completedChapters'][ch_idx] |= 1<<ep_idx
		
	
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

var isHistoryBeingShown=false

var isOtherScreenHandlingInput:bool=false
#var isWaitingForChoice=false

var tracebackPos:int = -1
#limit skip speed
var frameLimiter:float=0.0

func toggleAutoMode(b:bool=false):
	automatically_advance_text=b
	if b:
		$AutoModeIndicator.play()
	else:
		$AutoModeIndicator.stop()

func _process(delta):
	
	if isHistoryBeingShown:
		historyActor.process(delta)
		return
	elif $CutsceneDebug.visible and Input.is_action_just_pressed("DebugButton2"):
		isOtherScreenHandlingInput=false
		$CutsceneDebug.visible=false
	elif isOtherScreenHandlingInput:
		setTextboxStyle()
		return
		
	if Input.is_action_just_pressed("ui_pause") or Input.is_action_just_pressed("ui_cancel"):
		toggleAutoMode(false)
		optionsScreen.visible=true
		optionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		
		isOtherScreenHandlingInput=true
	elif Input.is_action_just_pressed("DebugButton1"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("DebugButton2"):
		isOtherScreenHandlingInput=true
		$CutsceneDebug.visible=true
	elif Input.is_action_just_pressed("DebugButton4"):
		var varDebugerInst = varDebugger.instance()
		add_child(varDebugerInst)
		varDebugerInst.init_(cutsceneVars)
	
	if Input.is_action_pressed("vn_skip"):
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
	
		tracebackPos=-1
		text.modulate=Color.white
		
	var forward = manualTriggerForward
#	if forward:
#		print("ManualTriggerForward")

	if tracebackPos < -1:
		if forward:
			manualTriggerForward=false
			tracebackPos+=1
			print("tracing forward... ", tracebackPos)
			text.visible_characters=999
			speakerActor.text = textHistory[tracebackPos][0]
			text.bbcode_text = textHistory[tracebackPos][1]
			
			if tracebackPos>=-1:
				text.modulate=Color.white
	elif text.visible_characters >= text.text.length(): #If finished displaying characters
		if ChoiceTable.size()>0:
			frameLimiter=0
			manualTriggerForward=false
			print("Set choices: "+String(ChoiceTable))
			$Choices.setChoices(ChoiceTable)
			$Choices.OnCommand()
			isOtherScreenHandlingInput=true
		elif forward:
			manualTriggerForward=false
			print("advancing")
			if curPos >= message.size() or !advance_text():
				end_cutscene()
		elif automatically_advance_text:
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
	if isOtherScreenHandlingInput:
		return
			
	#if event is InputEventKey and event.is_pressed() and event.scancode == KEY_1:
	if Input.is_action_just_pressed("ui_select"):
		if automatically_advance_text:
			toggleAutoMode(false)
		else:
			manualTriggerForward=true
		get_tree().set_input_as_handled()
	elif Input.is_action_just_pressed("vn_history"):
		toggleAutoMode(false)
		if messageBoxMode!=MSGBOX_DISP_MODE.FULLSCREEN: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			print("Displaying history!!!")
			tween_in_history()
			#historyActor.set_history(textHistory)
		#isHistoryBeingShown=!isHistoryBeingShown

func _input(event):
	if (event is InputEventMouseMotion):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if isOtherScreenHandlingInput:
		return
	#if (event is InputEventMouseButton and event.is_pressed()) and event.button_index==BUTTON_WHEEL_UP and isHistoryBeingShown==false:
	if Input.is_action_just_pressed("vn_history") and isHistoryBeingShown==false:
		if messageBoxMode!=MSGBOX_DISP_MODE.FULLSCREEN: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			tween_in_history()
			get_tree().set_input_as_handled()
			isOtherScreenHandlingInput=true
		#elif event.button_index==BUTTON_WHEEL_UP:
		#		tween_out_history()
		#		isHistoryBeingShown=false
	elif Input.is_action_just_pressed("vn_traceback"):
		"""
		A VN traceback mode can't go back in time for real, or else
		it would show the choice dialogues again and set variables again.
		Which isn't really what we want.
		
		What a traceback would do is just pull from the VN history.
		"""
		
		
		if txtTw.is_valid() and text.visible_characters < text.text.length():
			txtTw.kill()
			text.visible_characters=999
		
		if tracebackPos*-1 >= len(textHistory):
			return
		tracebackPos-=1
		print("Attempting to traceback... ",tracebackPos)
		print(textHistory[tracebackPos])
		speakerActor.text = textHistory[tracebackPos][0]
		text.bbcode_text = textHistory[tracebackPos][1]
		text.modulate=Color.gray
		
		pass
	elif (event is InputEventMouseButton and event.is_pressed() and event.button_index==2) or (event is InputEventScreenTouch and event.index==1):
		print("user right clicked to open options screen")
		optionsScreen.visible=true
		optionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		
		isOtherScreenHandlingInput=true
		get_tree().set_input_as_handled()
	elif Input.is_action_just_pressed("vn_auto"):
		toggleAutoMode(!automatically_advance_text)
	#elif isHistoryBeingShown:
	#	historyActor.input(event)
		#else:
		#	print("Unknown mouse button pressed or don't know how to handle")

#If Android back button pressed
#TODO: Ignore if cutscene playing
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST and isOtherScreenHandlingInput==false:
		toggleAutoMode(false)
		optionsScreen.visible=true
		optionsScreen.OnCommand()
		#historyTween.interpolate_property($ColorRect2,"modulate:a",null,0.85,.5)
		
		isOtherScreenHandlingInput=true


func _on_SkipButton_pressed():
	end_cutscene()

func _on_dim_gui_input(event):
	if isOtherScreenHandlingInput:
		return
	
	if (event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT) or (
		event is InputEventScreenTouch and event.is_pressed()
	):
		print("clicked")
		if automatically_advance_text:
			toggleAutoMode(false)
		else:
			manualTriggerForward=true

func _on_Choices_selected_choice(selection):
	choiceResult=$Choices.selection+1
	print("Choice result obtained, result was "+String(choiceResult))
	$Choices.OffCommand()
	ChoiceTable=[]
	advance_text()
	if isOtherScreenHandlingInput==false:
		printerr("Somehow input was handed to this screen from the choice one, but choice screen shouldn't have input")
	isOtherScreenHandlingInput=false


func _on_OptionsScreen_options_closed():
	print("User closed options")
	optionsScreen.visible=false
	isOtherScreenHandlingInput=false
	#print("New opacity is "+String(Globals.OPTIONS['bgOpacity']['value']/100.0))
	#$CenterContainer/textBackground.color.a = Globals.OPTIONS['bgOpacity']['value']/100.0


func _on_TextureButtonLog_pressed():
	if isHistoryBeingShown:
		tween_out_history()
	else:
		if messageBoxMode!=MSGBOX_DISP_MODE.FULLSCREEN: #NO HISTORY IN FULL SCREEN IT BREAKS THE GAME!!!!!
			tween_in_history()
			get_tree().set_input_as_handled()
			isOtherScreenHandlingInput=true
	

func _on_TextureButtonAuto_toggled(button_pressed):
	toggleAutoMode(button_pressed)

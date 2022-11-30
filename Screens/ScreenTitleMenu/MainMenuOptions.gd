extends "res://Cutscene/CutsceneOptions.gd"
func init():
	print("Execute override init!")
	#Globals.currentEpisodeData=null
	options = {
		"textSpeed":Globals.OPTIONS['textSpeed'],
		"skipMode":Globals.OPTIONS['skipMode'],
		#"testOption":Globals.OPTIONS['testOption'],
		#"language":Globals.OPTIONS['language'],
		#"systemOptions":{
		#	type="submenu",
		#	submenu="systemOptionsSubmenu"
		#}
	}
	for opt in ["AudioVolume","SFXVolume","language"]:
		options[opt]=Globals.OPTIONS[opt]
	if OS.has_feature("pc"):
		options['isFullscreen']=Globals.OPTIONS['isFullscreen']
	else:
		#Not in global options dict so can't use a func
		options["continue"]={
			type="none",
			hasFunc=true
		}
	.init()
	
func _ready():
	$EpisodeDisplay.visible=false

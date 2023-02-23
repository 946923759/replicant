extends Control

onready var vnPlayerDest = $Label

#class Episode:
#	#There is no easy way to get the parent without iterating through the
#	#whole dict so put it here too
#	var parentChapter:String
#	var title:String
#	var desc:String
#	var parts:Array
#	var isSub:bool=false

func _on_Button_pressed():
	Globals.nextCutscene=vnPlayerDest.text+".txt"
	#Globals.currentEpisodeData=episodeDest
	
	
	pass # Replace with function body.

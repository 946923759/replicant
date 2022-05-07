extends Control

var options = {
	"continue":{
		optionType="none"
	},
	"skip":{
		optionType="none"
	},
	"textSpeed":{
		optionType="int",
		hasFunc=true,
		#afterUpdateFunc=true
	},
	"autoRead":{
		
	},
	"musicVolume":{
		optionType="int",
		hasFunc=true
	},
	"sfxVolume":{
		optionType="int",
		hasFunc=true
	},
	"chapterSelect":{
		optionType="none"
	}
}



func OnCommand():
	pass
	#updateFocus()
	

#func updateFocus():
	

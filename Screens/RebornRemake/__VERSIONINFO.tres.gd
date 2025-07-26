extends Node

var date = "2025062400"
onready var version = get_version()

func get_version() -> String:
	var version_string:String = "RRE:"
	
	# Returns the name of the host OS. 
	# Possible values are: 
	# "Android", "iOS", "HTML5", "OSX", "Server", "Windows", "UWP", "X11".
	version_string+=OS.get_name().left(1).to_upper()+":"
	if OS.is_debug_build():
		version_string+="B:"
	else:
		version_string+="R:"

	return version_string+date

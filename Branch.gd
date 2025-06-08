extends Node

# For some insane reason you can't call an inner class from a class
# So Globals.Branch.call("func") wouldn't work
# Therefore this wrapper will handle it
func FireMothOpeningOrTitle() -> String:
	if Globals.OPTIONS['showFMOpening']['value']:
		return "ScreenOpening"
	else:
		return "ScreenTitleMenu"

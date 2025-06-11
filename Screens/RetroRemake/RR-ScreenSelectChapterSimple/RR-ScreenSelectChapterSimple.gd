extends "res://Screens/ScreenWithMenuElements.gd"

func _ready():
	if Globals.chapterDatabase_RR.empty():
		Globals.chapterDatabase_RR=Globals.load_database("Screens/RetroRemake/rr_db.tsv")
	elif Globals.currentEpisodeData:
		print("[RR-ScreenSelectChapter] Player had previously read an episode")
		print(Globals.currentEpisodeData._to_string())

	var chapter_scroller = $ScrollContainer/MarginContainer/HBoxContainer
	#var num_objects = chapter_scroller.get_child_count()
	var chapters = Globals.chapterDatabase_RR.keys()
	
	for i in range(chapter_scroller.get_child_count()):
		if i > len(chapters):
			break
		var c:Control = chapter_scroller.get_child(i)
		c.set_chapter(chapters[i], Globals.chapterDatabase_RR[chapters[i]])
	#for chapter_name in Globals.chapterDatabase_RR:
	#	if len(chapter_name)==0:
	#		continue
		

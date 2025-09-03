extends "res://Screens/ScreenWithMenuElements.gd"

export(Globals.DLC_PACK) var pack = Globals.DLC_PACK.RETRO_REMAKE

func get_database_path(pack):
	if pack == Globals.DLC_PACK.RETRO_REMAKE:
		return "Screens/RetroRemake/rr_db.tsv"
	else:
		return "Screens/RebornRemake/re_db.tsv"

func _ready():
	var load_path:String = get_database_path(pack)
	var database_ref:Dictionary

	if pack==Globals.DLC_PACK.RETRO_REMAKE:
		database_ref = Globals.chapterDatabase_RR
	else:
		database_ref = Globals.chapterDatabase_RE
	
	
			
	if database_ref.empty():
		database_ref = Globals.load_database(load_path)
		if database_ref.has('__starting_episode__'):
			Globals.currentEpisodeData=database_ref['__starting_episode__'][0]
			Globals.nextCutscene=Globals.currentEpisodeData.parts[0]+".txt"
			database_ref.erase('__starting_episode__')

		if name.begins_with("RR"):
			Globals.chapterDatabase_RR = database_ref
		else:
			Globals.chapterDatabase_RE = database_ref

	var chapter_scroller = $ScrollContainer/MarginContainer/HBoxContainer
	#var num_objects = chapter_scroller.get_child_count()
	var chapters = database_ref.keys()
	
	for i in range(chapter_scroller.get_child_count()):
		var c:Control = chapter_scroller.get_child(i)
		if i >= len(chapters):
			c.queue_free()
		else:
			c.set_chapter(chapters[i], database_ref[chapters[i]])
	
	if Globals.currentEpisodeData:
		print("["+name+"] Player had previously read an episode")
		print(Globals.currentEpisodeData._to_string())
		$ScrollContainer.call_deferred("set_selection",chapters.find(Globals.currentEpisodeData.parentChapter), false)
		#$ScrollContainer.set_selection(chapters.find(Globals.currentEpisodeData.parentChapter), false)
		
	else:
		$ScrollContainer.call_deferred("set_selection",1,false)
		#$ScrollContainer.call_deferred("reposition_actors")
		#$ScrollContainer.call_deferred("reposition_actors")
		#$ScrollContainer.call_deferred("reposition_actors")
	#for chapter_name in Globals.chapterDatabase_RR:
	#	if len(chapter_name)==0:
	#		continue
		

func _input(event):
	if event.is_action_pressed("DebugButton1"):
		if OS.get_name() == "X11":
			OS.execute("xdg-open",[get_database_path(pack)], false)


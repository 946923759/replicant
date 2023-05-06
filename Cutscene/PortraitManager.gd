extends Control

const POOL_SIZE = 8
var SCREEN_CENTER: Vector2
var spacing = 400	# 200 px
var tween: Tween

#TODO: Shouldn't be necessary when cache is implemented, cache.size() will return
#the size of active portraits
var numPortraits:int=0
#TODO: The cache isn't implemented
var cache: Array = []	# Holds dictionaries (see below for details)
"""
		{
			"name": SpriteName,
			"radioMask": bool,		# this could change into a tag list for different types of masks
			"y_offset": float		# in case you want to make characters shorter
		}
"""

#No need to run get_children(), we can just store the pointers to the portrait nodes
#here. And we don't want that one tween anyways.
var portraits:Array

func get_portrait_from_sprite(spr):
	for p in portraits:
		if p.lastLoaded==spr:
			return p
	#printerr("Tried getting a portrait "+spr+" that doesn't exist")
	return null
	
func get_portrait_at_idx(idx):
	for p in portraits:
		if p.idx==idx:
			return p
	return null

func get_all_portrait_idx() -> Dictionary:
	var tmp = {}
	for p in portraits:
		if p.is_active:
			tmp[p.lastLoaded]=[p.idx,false,p.offset,p.cur_expression]
	return tmp

#Load texture but don't display
func preload_portraits(arr:Array):
	#TODO: Change to a portrait pooling class
	#TODO: Do not preload until no portraits are shown
	for i in range(get_child_count()):
		if i < arr.size()-1:
			#idx=i+1 since first element in the array is the command name
			get_child(i).set_texture_wrapper(arr[i+1])
			print("Preloaded "+arr[i+1])

func set_portrait(name: String, y_offset: float = 0, radioMask: bool = false)->Node2D:
	# checks if exist
	# Unnecessary? CutsceneMain already checks if there's a spare portrait
	#var lastUsed = get_portrait_from_sprite(name)
	#if lastUsed:
	#	#print("Already loaded, skipping...")
	#	return lastUsed

	var lastUsed
	for p in portraits:
		if p.is_active==false:
			lastUsed = p
			print(name)
			p.set_texture_wrapper(name)
			break
#	# update positions
#	update_positions()
#	tween.interpolate_property(lastUsed,
#		'modulate',
#		null,
#		Color(1,1,1,1),
#		.3
#	);
#	tween.interpolate_property(lastUsed,
#		'position:x',
#		null,
#		lastUsed.position.x + 60,
#		.5, Tween.TRANS_QUAD, Tween.EASE_OUT
#	);
#	tween.start();
	return lastUsed



func update_portrait_positions_wip(relation:Dictionary,numPortraits:int=-1):
	#Structure of relation is like
	# {
	#   "sprName": [pos,isMasked,offset,cur_expression=0],
	#   "sprName2": [pos,isMasked,offset,cur_expression=0],
	#   "spr3" : null #if null, this portrait should be removed
	# }
	#Optional argument since it gets calculated in advance in CutsceneMain
	#and doesn't need to be calculated again.
	if numPortraits < 0:
		numPortraits=0
		for name in relation:
			if typeof(relation[name])==TYPE_ARRAY:
				numPortraits+=1
	self.numPortraits=numPortraits
	
	for name in relation:
		var pStruct = relation[name]
		#assert(self.portraits[name],"A portrait by the name of "..name.." does not exist, either you made a typo or you forgot to put it in LoadImages.");
		if typeof(pStruct)==TYPE_ARRAY: #if found portrait
			#Pos,isMasked,offset
			#This is basically just a really stupid way of pooling
			#If the sprite is already loaded just reuse it, otherwise
			#Find an unused one and use that one
			var lastUsed = get_portrait_from_sprite(name)
			if lastUsed == null:
				lastUsed=set_portrait(name,pStruct[1],pStruct[2])
			#PORTRAITMAN.update_positions()
			#print(lastUsed.lastLoaded)
			#print(pStruct)
			lastUsed.position_portrait(pStruct[0],pStruct[1],pStruct[2],numPortraits)
			print("Set portrait "+name)
			if pStruct.size() > 3:
				lastUsed.cur_expression = pStruct[3]
		else: #If null, portrait is not present anymore and should be hidden
			#self.portraits[name].actor:playcommand("Stop")
			var lastUsed = get_portrait_from_sprite(name)
			if lastUsed != null:
				print("Stopping sprite"+name)
				lastUsed.stop()

func update_positions():
	#TODO: This is not good and handling should be done by PORTRAITMAN but it's WIP
	#VNPortrait doesn't need to know the position but it needs to know its own idx
	#And PORTRAITMAN also needs to know how many active portraits there are,
	#VNPortrait shouldn't need to know
	for p in portraits:
		if p.is_active:
			p.update_portrait_positions(get_viewport().get_visible_rect().size.x/2)
		
	
#	SCREEN_CENTER.x = get_viewport().get_visible_rect().size.x/2
#	#var newPos: Array = []	# [Vector2]
#	# calculations for each position loaded into array
#	for i in range(get_child_count()):
#		var p = get_child(i)
#		if p.is_active:
#			var x_pos = (p.idx * spacing) - ( p.numPortraits/2 * spacing ) + SCREEN_CENTER.x	# equation to seperate portraits based on position in array
#			#var x_pos = spacing * ( (size()/2) + ( i if size() % 2 != 0 else 0 ) - i) * (-1 if i > size()/2 else 1)
#			tween.interpolate_property(
#				p,
#				'position',
#				null,
#				Vector2( x_pos, SCREEN_CENTER.y + cache[i].y_offset),
#				.5, Tween.TRANS_QUAD, Tween.EASE_OUT
#			);
#	# move to positions
#	tween.start();
#
#

#Not really possible since focus_speaker depends on the portrait idx
#and not the portrait name..
func focus_speaker(speaker: String):
	pass
	
	
#Brought to you by terrible stepmania naming conventions
#Because everyone knows what diffuse means right
func diffuse(p: Sprite, color: Color = Color(Color(.5,.5,.5,1))):
	tween.interpolate_property(p,
		'modulate',
		null,
		color,
		.3
	);
	tween.start();
	
func undim(p: Sprite):
	diffuse(p, Color(1,1,1,1))


func hl_idx(idx:int):
	for p in portraits:
		if p.idx==idx:
			p.undim()
			p.z_index = 0
		elif p.is_active:
			p.dim()
			p.z_index = -1

func dim_idx(idx:int):
	for p in portraits:
		if p.idx==idx:
			p.dim()
			p.z_index = -1
			break

func size():
	return cache.size()


func _ready():
	SCREEN_CENTER = Vector2(self.rect_pivot_offset.x, self.rect_pivot_offset.y)
	
	var vnPortraithandler = load("res://Cutscene/VNPortraitHandler.gd")
	for _i in range(5):
		var p = Node2D.new()
		p.set_script(vnPortraithandler)
		p.modulate.a=0.0
		#p.scale=Vector2(.75,.75) #We do it here instead of the whole node because scaling the whole node breaks positioning.
		portraits.append(p)
		add_child(p)
	connect("resized",self,"update_positions")
	
	tween = Tween.new()
	add_child(tween)

class_name Def
extends Node

const smSprite = preload("res://stepmania-compat/smSprite.gd")
const smQuad = preload("res://stepmania-compat/smQuad.gd")

static func BitmapText(d)->Label:
	var l = Label.new()
	for property in d:
		l.set(property,d[property])
	#l.set("custom_fonts/font",font)
	return l
	
static func LoadFont(font,d)->Label:
	var l = Label.new()
	for property in d:
		l.set(property,d[property])
	l.set("custom_fonts/font",font)
	return l
	
static func Quad(d)->smQuad:
	var q = smQuad.new()
	for property in d:
		if property=="size":
			q.setSize(d[property])
		else:
			q.set(property,d[property])
	return q
	
static func Sprite(d)->smSprite:
	var s = smSprite.new()
	for property in d:
		if property=="Texture":
			s.loadVNBG(d[property])
		elif property=="TextureFromDisk":
			s.loadFromExternal(d[property])
		elif property=="cover":
			s.Cover()
		else:
			s.set(property,d[property])
	return s

static func Video(d)->smVideo:
	var s = smVideo.new()
	for property in d:
		if property=="Texture":
			s.loadVNBG(d[property])
		#elif property=="TextureFromDisk":
		#	s.loadFromExternal(d[property])
		elif property=="cover":
			s.Cover()
		else:
			s.set(property,d[property])
	return s

static func Sound(d)->smSound:
	var s = smSound.new()

	for property in d:
		if property=="File":
			s.load_song(d[property],false)
		else:
			s.set(property,d[property])
	return s

static func SoundEffect(d)->smSound:
	var s = smSound.new()
	#s.bus="SFX"
	for property in d:
		if property=="File":
			s.load_sound(d[property])
		else:
			s.set(property,d[property])
	return s

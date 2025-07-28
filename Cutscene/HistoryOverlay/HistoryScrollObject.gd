extends HBoxContainer
#tool

onready var speakerObj = $Speaker
onready var messageObj = $Message
#var speakerObj
#var messageObj

export var speaker_text:String = "This is speaker text" setget set_speaker_text, get_speaker_text
export var dialogue_text:String = "This is dialogue text" setget set_message_text, get_message_text


func set_speaker_text(s:String):
	if is_instance_valid(speakerObj):
		speakerObj.text = s
	speaker_text = s
func get_speaker_text() -> String:
	if is_instance_valid(speakerObj):
		return speakerObj.text
	return speaker_text
	
func set_message_text(s:String):
	if is_instance_valid(messageObj):
		messageObj.bbcode_text = s
	dialogue_text = s
func get_message_text() -> String:
	if is_instance_valid(messageObj):
		return messageObj.text
	return dialogue_text

#Can't set child objects until after _ready() and _ready() doesn't exec until the obj is added to the tree
func init(speaker:String, dialogue:String):
	speaker_text = speaker
	dialogue_text = dialogue
	#set_speaker_text(speaker)
	#set_message_text(dialogue)

func _ready():
	set_speaker_text(speaker_text)
	set_message_text(dialogue_text)

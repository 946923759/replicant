#tool
extends Label

#export (String) var actual_text = "Hello World" setget set_text
onready var actual_text:String = text
export (int,0,100,1) var randomized_amount = 0 #setget set_random_amount
export (float,0.01,1,.01) var random_delay = .2

var characters = 'abcdefghijklmnopqrstuvwxyz'
onready var n_char = len(characters)
var elapsed:float = 0.0

func _ready():
	randomized_amount = min(len(actual_text), randomized_amount)
#	var new_word = generate_word(characters, 100)
#	print(new_word)
	#set_random_text()
	set_process(!Engine.editor_hint)

func _process(delta):
	if !visible:
		return
	elapsed+=delta
	if randomized_amount<=0:
		text = actual_text
		#set_process(false)
	elif elapsed >= random_delay:
		elapsed-=random_delay
		set_random_text()
		
func set_random_text():
	var tmp_txt = actual_text
	for i in range(len(tmp_txt)-1, len(tmp_txt)-randomized_amount-1,-1):
		tmp_txt[i] = characters[randi()% n_char]
	text = tmp_txt

func set_text(t):
	actual_text = t
	randomized_amount = min(len(actual_text), randomized_amount)
	set_random_text()

func set_random_amount(i):
	randomized_amount = min(len(actual_text), i)
#func set_random_text(chars, length):
#	var word: String
#	var n_char = len(chars)
#	for i in range(length):
#		word += chars[randi()% n_char]
#	return word

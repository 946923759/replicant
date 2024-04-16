extends Control

var lastBackgroundName:String = ""
var lastBackground:Node

func setNewBG(bgName:String, transition:String="",waitForAnim:float=0.0)->float:
	lastBackgroundName=bgName
	
	if bgName=="black":
		if is_instance_valid(lastBackground):
			if transition=='immediate' or transition=='instant':
				lastBackground.modulate.a=0
			else:
				lastBackground.hideActor(.5)
				waitForAnim+=.5
			lastBackground=null
	else:
		var newBackground = get_node(bgName)
		if !is_instance_valid(newBackground):
			printerr("[BackgroundManager] Could not find background node "+bgName+"! DO NOT USE SLASHES IN BACKGROUNDS!!!!!!")
		else:
			print(newBackground)
			#print(get_child_count())
			#print(newBackground.rect_position)
			#print(newBackground.rect_size)
			
			#Shitty way of handling transitions
			#If it works don't fix it... or something
			for n in get_children():
				if n!=lastBackground and n!=newBackground:
					n.modulate.a=0
			
			if transition=='fade':
				if is_instance_valid(lastBackground):
					VisualServer.canvas_item_set_z_index(lastBackground.get_canvas_item(),-11)
				VisualServer.canvas_item_set_z_index(newBackground.get_canvas_item(),-10)
				newBackground.modulate.a=0
				newBackground.showActor(.5)
			elif transition=='immediate' or transition=='instant':
				newBackground.modulate.a=1
				if newBackground is smVideo:
					newBackground.showActor(0)
				if is_instance_valid(lastBackground):
					lastBackground.modulate.a=0
			else: #Fade to black and fade in new background
				if lastBackground==newBackground:
					newBackground.hideShow(1)
					waitForAnim+=1
				elif is_instance_valid(lastBackground):
					lastBackground.hideActor(.5)
					newBackground.showActor(.5,.5) #time, delay
					waitForAnim+=1
					#if waitForAnim<.3: #This code is horrible
					#	waitForAnim+=.5
				else:
					#print("ShownewBackground!")
					newBackground.showActor(.5)
					waitForAnim+=.5
				#print("unknown bg tween? "+String(curMessage[2]))
			lastBackground=newBackground
	return waitForAnim

func setNewBG_tween(bgName:String, oldBGTween:String, newBGTween:String, bgLayerTween:String="") -> float:
	var newBackground = get_node(bgName)
	if !is_instance_valid(newBackground):
		printerr(bgName+" is an invalid background! DO NOT USE SLASHES IN BACKGROUNDS!!!!!!")
		return 0.0

	var tw:SceneTreeTween = get_tree().create_tween()
	var timeToWait = 0.0
	if is_instance_valid(lastBackground):
		timeToWait = smTween.cmd(tw,lastBackground,oldBGTween)
	timeToWait = max(timeToWait, smTween.cmd(tw,newBackground,newBGTween))
	if bgLayerTween:
		timeToWait = max(timeToWait, smTween.cmd(tw,newBackground,bgLayerTween))
	return timeToWait

func _ready():
	set_physics_process(true)

#So the original ShakeCamera2D script doesn't actually work correctly
#because it uses the completely wrong offset
#I just copypasted the code and fixed it

"""
MIT License

Copyright (c) 2020 Alex Nagel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
"""
export var max_offset : float =5.0
export var max_roll : float = 5.0
export var shakeReduction : float = 1.0

#Don't touch these unless you're testing it
var stress : float = 0.0
var shake : float = 0.0

var elapsed:float=0
func _physics_process(_delta):
	if stress == 0.0:
		return
	
	elapsed+=_delta
	if elapsed>1/60: #Lock to the frame rate
		elapsed=0
		_process_shake(Vector2(0,0), 0.0, _delta)
	pass


#TODO: It's tied to the update rate which is extremely inconsistent between computers
func _process_shake(center, angle, delta) -> void:
	shake = stress * stress

	#rotation_degrees = angle + (max_roll * shake *  _get_noise(randi(), delta))
	
	#offset = Vector2()
	rect_position.x = (max_offset * shake * _get_noise(randi(), delta + 1.0))
	rect_position.y = (max_offset * shake * _get_noise(randi(), delta + 2.0))
	#print(offset)
	stress -= (shakeReduction / 100.0)
	
	stress = clamp(stress, 0.0, max_offset)
	
	
func _get_noise(noise_seed, time) -> float:
	var n = OpenSimplexNoise.new()
	
	n.seed = noise_seed
	n.octaves = 4
	n.period = 20.0
	n.persistence = 0.8
	
	return n.get_noise_1d(time)
	
	
func add_stress(amount : float) -> void:
	stress += amount
		

func shakeCamera(magnitude:float=3.0):
	print("Shaking!")
	add_stress(magnitude)

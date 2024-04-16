class_name smTween

enum TWEEN_TYPE {
	LINEAR,
	DECELERATE,
	ACCELERATE,
	SLEEP
}
var time:float=0.0
var tween:SceneTreeTween

func _init(t:SceneTreeTween):
	tween=t
	#return self

"""
For example, we call a portrait "Kyuu" with something like
Kyuu.tween(decelerate,.2;zoom,2)

Which unpacks itself into
tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
tween.tween_property(Kyuu,"scale",Vector2(2,2),.2)

Or emotes:
Kyuu.tween(sleep,.5;emote,away;sleep,.5;emote,worried;sleep,.5;emote,away)

Which unpacks itself into
tween.tween_method(Kyuu,"set_expression",cur_expression,"away",0.0).set_delay(.5)

commands are 'separated' by decelerate,accelerate,sleep,etc
So you can do
tween(decelerate,.2;zoom,1.5;diffuse,Color.Red;linear,.3;x,500)
Which will make decelerate and zoom run parallel.

This should unpack to
tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
tween.tween_property(Kyuu,"zoom",1.5,.2).set_parallel(true)
tween.tween_property(Kyuu,"modulate",Color.Red,.2).set_parallel(true)
tween.tween_property(Kyuu,"position:x",500,.3).set_delay(.2).set_parallel(true)

However, the total time for a tween needs to be known, because we want to be
able to run tweens before text displays.
If two elements are tweened, VN engine can do max() on tween times.
"""
static func cmd(tw:SceneTreeTween, objectToTween:Node, tweenString:String) -> float:
	
	tw.set_parallel(true)
	var cmnds = tweenString.split(";",false)
	
	var tweenBatch = 0
	var tweenLength:float = 0.0
	var timeToDelay:float = 0.0
#It's not unused so why is it a warning???
# warning-ignore:unused_variable
	var curTweenType = TWEEN_TYPE.SLEEP
	
	
	var rectPrefix = ""
	if objectToTween is Control:
		rectPrefix = "rect_" #BUT WHY???
		
	var lastKnownPosition:Vector2 = objectToTween.get(rectPrefix+"position")
	var lastKnownColor:Color = objectToTween.modulate
	
	for cmd in cmnds:
		var splitCmd = cmd.split(",")
		match splitCmd[0]:
			"stoptweening": #This is such a massive hack
				if objectToTween.has_method("stoptweening"):
					#The engine will complain about a lack of tweeners so just do it this way
					tw.tween_callback(objectToTween,"stoptweening")
					#objectToTween.stoptweening()
			"linear":
				curTweenType = TWEEN_TYPE.LINEAR
				if tweenBatch>0:
					#Add previous tween length to delay
					timeToDelay+=tweenLength
				tweenBatch+=1
				tweenLength = float(splitCmd[1])
			"decelerate":
				curTweenType = TWEEN_TYPE.DECELERATE
				
				if tweenBatch>0:
					#Add previous tween length to delay
					timeToDelay+=tweenLength
				tweenBatch+=1
				
				tweenLength = float(splitCmd[1])
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			"accelerate":
				curTweenType = TWEEN_TYPE.ACCELERATE
				
				if tweenBatch>0:
					#Add previous tween length to delay
					timeToDelay+=tweenLength
				tweenBatch+=1
				
				tweenLength = float(splitCmd[1])
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			"sleep":
				curTweenType = TWEEN_TYPE.SLEEP
				tweenLength = 0.0
				timeToDelay += float(splitCmd[1])
			"x":
				tw.tween_property(objectToTween,rectPrefix+"position:x",float(splitCmd[1]),tweenLength).set_delay(timeToDelay)
			"y":
				tw.tween_property(objectToTween,rectPrefix+"position:y",float(splitCmd[1]),tweenLength).set_delay(timeToDelay)
			"xy":
				tw.tween_property(objectToTween,rectPrefix+"position:x",float(splitCmd[1]),tweenLength).set_delay(timeToDelay)
				tw.tween_property(objectToTween,rectPrefix+"position:y",float(splitCmd[2]),tweenLength).set_delay(timeToDelay)
			"addx":
				print("Applying addx "+splitCmd[1]+" after "+String(timeToDelay)+" sec... "+String(lastKnownPosition.x)+"+"+splitCmd[1])
				tw.tween_property(objectToTween,rectPrefix+"position:x",lastKnownPosition.x+float(splitCmd[1]),tweenLength).from(lastKnownPosition.x).set_delay(timeToDelay)
				lastKnownPosition.x+=float(splitCmd[1])
			"addy":
				print("Applying addy "+splitCmd[1]+" after "+String(timeToDelay)+" sec... "+String(lastKnownPosition.y)+"+"+splitCmd[1])
				tw.tween_property(objectToTween,rectPrefix+"position:y",lastKnownPosition.y+float(splitCmd[1]),tweenLength).from(lastKnownPosition.y).set_delay(timeToDelay)
				lastKnownPosition.y+=float(splitCmd[1])
			"zoom":
				var v2 = Vector2()
				if len(splitCmd) < 3:
					v2 = Vector2(float(splitCmd[1]),0.0)
					v2.y=v2.x
				else:
					v2 = Vector2(float(splitCmd[1]),float(splitCmd[2]))
				tw.tween_property(objectToTween,rectPrefix+"scale",v2,tweenLength).set_delay(timeToDelay)
			"zoomx":
				tw.tween_property(objectToTween,rectPrefix+"scale:x",float(splitCmd[1]),tweenLength).set_delay(timeToDelay)
			"diffuse","modulate":
				"""
				Usage examples:
					linear,.5;diffuse,#FF0000      <- Tween by hex colors
					linear,.5;diffuse,darkgreen    <- Tween by constants
					linear,.5;diffuse,1.0,0.5,0.3  <- Tween by float
				"""
				
				var val:Color = Color.black
				if splitCmd.size() >= 5:
					val = Color(float(splitCmd[1]),float(splitCmd[2]),float(splitCmd[3]),float(splitCmd[4]))
				elif splitCmd.size() == 4:
					val = Color(float(splitCmd[1]),float(splitCmd[2]),float(splitCmd[3]))
				elif splitCmd[1].begins_with("#"):
					val = Color(splitCmd[1])
				else:
					val = ColorN(splitCmd[1])
#					var expression = Expression.new()
#					expression.parse(splitCmd[1])
#					#Color.darkgreen
#					print("Tried to parse "+splitCmd[1])
#					#Convert Color.red, Color("#RRGGBB"), Color(1.0,0.5,1.0), etc
#					var res = expression.execute()
#					if res is Color:
#						val = res
				# LastKnownColor needed because tweens appear to have a bug in godot 3.5
				# https://github.com/godotengine/godot/issues/80388
				tw.tween_property(objectToTween,"modulate",val,tweenLength).from(lastKnownColor).set_delay(timeToDelay)
				lastKnownColor = val
			"visible":
				var val = splitCmd[1].to_lower()=="true"
				tw.tween_property(objectToTween,"visible",val,tweenLength).set_delay(timeToDelay)
			"diffusealpha":
				tw.tween_property(objectToTween,"modulate:a",float(splitCmd[1]),tweenLength).set_delay(timeToDelay)
			"horizalign":
				var horizalign = 0.5
				if splitCmd[1] == "left":
					horizalign = 0.0
				elif splitCmd[1] == "right":
					horizalign = 1.0
				tw.tween_property(objectToTween,"rect_pivot_offset:x",objectToTween.rect_size.x*horizalign,tweenLength).set_delay(timeToDelay)
				#print(objectToTween.rect_pivot_offset.x)
				
			"emote":
				if "cur_expression" in objectToTween:
					tw.tween_property(objectToTween,"cur_expression",splitCmd[1],0.0).set_delay(timeToDelay)
			_:
				print("Unregistered command "+String(splitCmd))
	return timeToDelay+tweenLength

static func get_total_tween_time(tweenStr:String) -> float:
	var totalTime:float = 0.0
	
	var cmnds = tweenStr.split(";",false)
	for cmd in cmnds:
		match cmd[0]:
			'linear','decelerate','accelerate','sleep':
				totalTime+=float(cmd[1])
	return totalTime

func decelerate(time):
	self.time=time
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return self

func t(prop):
	tween.interpolate_property(prop)
	return self


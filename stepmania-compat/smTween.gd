class_name smTween

enum TWEEN_TYPE {
	LINEAR,
	DECELERATE,
	ACCELERATE
}
var time:float=0.0
var tween:SceneTreeTween

func _init(t:SceneTreeTween):
	tween=t
	#return self

"""
For example, we call it with something like
cmd(decelerate,.2;zoom,2)
"""
func cmd(tweenString:String):
	var cmnds = tweenString.split(";",false)
	

func decelerate(time):
	self.time=time
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return self

func t(prop):
	tween.interpolate_property(prop)
	return self


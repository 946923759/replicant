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

func decelerate(time):
	self.time=time
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return self

func t(prop):
	tween.interpolate_property(prop)
	return self

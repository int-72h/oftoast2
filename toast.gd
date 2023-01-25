extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var tween
# Called when the node enters the scene tree for the first time.
var spin = true
var in_main = false

func _on_main_spin_start():
	if spin == true:
		tween = get_tree().create_tween()
		tween.connect("finished",self,"_on_main_spin_start")
		tween.tween_property(self,"rect_rotation",rect_rotation + 360,3)
	
func _on_main_spin_stop():
	spin = false
	tween.stop()
	tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self,"rect_rotation",rect_rotation + (360 - (int(rect_rotation) % 360)),3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	spin = true

func _ready():
	if spin == true:
		print("called")
		tween = get_tree().create_tween()
		tween.connect("finished",self,"_ready")
		tween.tween_property(self,"rect_rotation",rect_rotation + 360,5)
	
func stop():
	print("stopped")
	spin = false
	tween.stop()
	tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self,"rect_rotation",rect_rotation + (360 - (int(rect_rotation) % 360)),2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func switch():
	tween.stop()
	var tween = get_tree().create_tween().set_parallel()
	var time = 1.5
	var trans = Tween.TRANS_QUART
	var easing = Tween.EASE_IN_OUT
	tween.tween_property(self,"rect_pivot_offset",Vector2(172,172),time).set_trans(trans).set_ease(easing)
	tween.tween_property(self,"rect_size",Vector2(340,340),time).set_trans(trans).set_ease(easing)
	tween.tween_property(self,"modulate",Color.white,time).set_trans(trans).set_ease(easing)
	tween.tween_property(self,"rect_rotation",0.0,time).set_trans(trans).set_ease(easing)
	tween.tween_property(self,"rect_position",Vector2(55,125),time).set_trans(trans).set_ease(easing)
	yield(get_tree().create_timer(time),"timeout")



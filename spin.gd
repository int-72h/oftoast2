extends Spatial

var spin = true
var tween

# Called when the node enters the scene tree for the first time.
func _ready():
	if spin == true:
		var toast1 = $toast_20k.rotation_degrees
		toast1.y +=360
		tween = get_tree().create_tween().set_parallel()
		tween.connect("finished",self,"_ready")
		tween.tween_property($toast_20k,"rotation_degrees",toast1,2.5)


func stop():
	print("stopped")
	spin = false
	tween.stop()
	tween = get_tree().create_tween().set_parallel(true)
	var rot = $toast_20k.rotation_degrees
	rot.y = rot.y + (360 - (int(rot.y) % 360)) + 180
	tween.tween_property($toast_20k,"rotation_degrees",rot,2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(get_node("/root/Control/ViewportContainer"),"modulate",Color.transparent,2)

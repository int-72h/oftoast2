extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var tween
var spin = true

func _ready():
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self,"rect_scale",Vector2(1,1),1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
	
func start_tween():
	if spin == true:
		tween = get_tree().create_tween()
		tween.connect("finished",self,"start_tween")
		tween.tween_property(self,"rect_rotation",rect_rotation + 360,3)
	
func stop_tween():
	spin = false
	tween.stop()
	tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self,"rect_rotation",rect_rotation + (360 - (int(rect_rotation) % 360)),3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

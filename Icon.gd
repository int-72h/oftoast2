extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var spin = true

func _ready():
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self,"rect_scale",Vector2(1,1),2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_Update_pressed():
	spin = true
	start_tween()
	
func start_tween():
	if spin == true:
		var tween = get_tree().create_tween()
		tween.connect("finished",self,"start_tween")
		tween.tween_property(self,"rect_rotation",rect_rotation + 360,3)

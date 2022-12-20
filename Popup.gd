extends ConfirmationDialog

var val
signal pressed
func _ready():
	get_cancel().connect("pressed", self, "cancel")
	get_ok().connect("pressed",self,"ok")

func get_val(text):
	dialog_text = text
	popup()
	yield(self,"pressed")
	return val # 0 = retry, 1=ok


func cancel():
	val = 0
	emit_signal("pressed")
	
func ok():
	val = 1
	emit_signal("pressed")

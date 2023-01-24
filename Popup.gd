extends WindowDialog

var val
signal tpressed
func _on_Button_pressed():
	val = 0
	hide()
	emit_signal("tpressed")
	
func _on_Button3_pressed():
	val = 1
	hide()
	emit_signal("tpressed")

func _on_Button2_pressed():
	val = 2
	hide()
	emit_signal("tpressed")

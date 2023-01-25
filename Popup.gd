extends WindowDialog

var val
signal tpressed
var text
func init(text,input,cont):
	$VBoxContainer/Label.text = text
	call_deferred("resize")
	if input:
		$VBoxContainer/HBoxContainer/Button4.show()
		$VBoxContainer/LineEdit.show()
	if not cont:
		$VBoxContainer/HBoxContainer/Button.hide()
		$VBoxContainer/HBoxContainer/VSeparator.hide()
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


func _on_Button4_pressed():
	val = 3
	hide()
	emit_signal("tpressed")
	text = $VBoxContainer/LineEdit.text

func resize():
	rect_size.y += $VBoxContainer/Label.rect_size.y - 161 # this is needed untill pr #66711 fixes everything I assume

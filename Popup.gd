extends WindowDialog

var val
signal tpressed
var text
var textlen = 0
onready var original_size = rect_size.y
func init(text,input,cont):
	$VBoxContainer/Label.text = text
	call_deferred("resize")
	if input:
		$VBoxContainer/HBoxContainer/Button4.show()
		$VBoxContainer/LineEdit.show()
	if not cont:
		$VBoxContainer/HBoxContainer/Button.hide()
		$VBoxContainer/HBoxContainer/VSeparator.hide()
func _on_Button_pressed(): #ok there's an easier way to do this but I can't be bothered
	val = 0
	emit_signal("tpressed")
	rect_size.y = original_size
	hide()
	
func _on_Button3_pressed():
	val = 1
	emit_signal("tpressed")
	rect_size.y = original_size
	hide()

func _on_Button2_pressed():
	get_tree().quit()


func _on_Button4_pressed():
	print("input used...")
	val = 3
	text = $VBoxContainer/LineEdit.text
	print(text)
	if text == "":
		print("but there's no input")
		return
	emit_signal("tpressed")
	hide()

func resize():
	if len($VBoxContainer/Label.text) != textlen:
		textlen = len($VBoxContainer/Label.text)
		rect_size.y += $VBoxContainer/Label.rect_size.y - 161 # this is needed untill pr #66711 fixes everything I assume

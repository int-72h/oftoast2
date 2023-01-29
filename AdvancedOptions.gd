extends ScrollContainer
onready var threads = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Threads/Text
onready var inst_dir = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/InstallDir/Button
onready var mirrors = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Mirrors/Text
onready var max_threads = get_node("/root/Control/Control").max_threads
signal picker_open
var value
export var audio_bus_name := "Master"

onready var _bus := AudioServer.get_bus_index(audio_bus_name)



func _ready() -> void:
	value = db2linear(AudioServer.get_bus_volume_db(_bus))
	print("db val is " + str(value))
	
	
func _on_threads_changed(new_text):
	if new_text == "":
		return
	elif !new_text.is_valid_integer():
		new_text.erase(len(new_text)-1,1)
		threads.text = new_text
	elif int(new_text) > max_threads or int(new_text) < 1:
		threads.text = ""
	else:
		get_node("/root/Control/Control").threads = int(new_text)

func _on_mirrors_changed():
	print(mirrors.text)


func _on_Button_pressed():
	emit_signal("picker_open")

func _on_FileDialog_dir_selected(dir): # this is kinda silly, fix later
	inst_dir.text = dir
	get_node("/root/Control/Control").path = dir
	


func _on_HSlider_value_changed(value):
	AudioServer.set_bus_volume_db(_bus, linear2db(value))

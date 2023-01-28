extends ScrollContainer
onready var target_rev = $MarginContainer/VBoxContainer/VersionContainer/Revision/Text
onready var threads = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Threads/Text
onready var maxdl = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/MaxDLSpeed/Text
onready var inst_dir = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/InstallDir/Button
onready var mirrors = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Mirrors/Text
const MAX_THREADS = 10
signal picker_open

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#func _on_revision_changed(new_text):
#	get_node("/root/Control/Control").target_revision = target_rev.text

func _on_threads_changed(new_text):
	print(new_text)
	get_node("/root/Control/Control").threads = threads.text


func _on_maxdl_changed(new_text):
	print(new_text) # do this on the back end eventually


func _on_mirrors_changed():
	print(mirrors.text)


func _on_Button_pressed():
	emit_signal("picker_open")


func _on_FileDialog_dir_selected(dir): # this is kinda silly, fix later
	inst_dir.text = dir
	get_node("/root/Control/Control").path = dir
	

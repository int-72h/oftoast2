extends ScrollContainer
onready var target_rev = $MarginContainer/VBoxContainer/VersionContainer/Revision/Text
onready var threads = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Threads/Text
onready var maxdl = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/MaxDLSpeed/Text
onready var inst_dir = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/InstallDir/Text
onready var mirrors = $MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Mirrors/Text
const MAX_THREADS = 10


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_revision_changed(new_text):
	print(new_text)
	if int(new_text) < -1 or int(new_text) > get_node("/root/Control/Control").latest_rev:
		new_text.erase(new_text.length()-1,1)
		target_rev.text = new_text
	get_node("/root/Control/Control").target_revision = target_rev.text

func _on_threads_changed(new_text):
	print(new_text)
	get_node("/root/Control/Control").threads = threads.text


func _on_maxdl_changed(new_text):
	print(new_text) # do this on the back end eventually


func _on_installdir_changed(new_text):
	print(new_text)
	if new_text[-1] == get_node("/root/Control/Control").delim:
		new_text.erase(new_text.length()-1,1)
		inst_dir.text = new_text
	get_node("/root/Control/Control").path = inst_dir.text

func _on_mirrors_changed():
	print(mirrors.text)

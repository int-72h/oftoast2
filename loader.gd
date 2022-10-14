extends Control
const GDDL = preload("res://gdnative/gdnative/gddl.gdns")
var gd = GDDL.new()
const version = "0.0.1"

# Called when the node enters the scene tree for the first time.
func _ready():
#	var newver = gd.download_to_string("/latest_launcher_ver")  ## commented out for now as it hasn't been implemented serverside yet, but it does work
#	if newver > version:
#		var pid = OS.get_process_id()
#		if OS.get_name() == "X11":
#			var exec_path = ProjectSettings.globalize_path("user://" + newver)
#			gd.download_file("/latest_launcher_ver_linux",exec_path) # download latest launcher...
#			var cmd_str = exec_path + "& kill " + str(pid) 
#			OS.execute("/bin/bash",["-c",cmd_str])
		
	get_tree().change_scene("res://Main.tscn")

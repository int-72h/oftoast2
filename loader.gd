extends Control
const GDDL = preload("res://gdnative/gddl.gdns")
const main = preload("res://Main.tscn")
const default_url = "https://toast1.openfortress.fun/toast"
var gd = GDDL.new()
var mainn
const version = "0.0.1"

var t = Thread.new()
var thread_done = false
signal error_handled
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
		
	#get_tree().change_scene("res://Main.tscn")
	#_sanity_checks()
	#yield(self,"error_handled")
	yield(get_tree().create_timer(3),"timeout")
	$TextureRect.call("stop")
	yield(get_tree().create_timer(2),"timeout")
	mainn = main.instance()
	add_child(mainn)
	yield(mainn,"draw")
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property($LoaderUI,"modulate",Color.transparent,1.5)
	tween.tween_property($Control,"modulate",Color.white,1.5)
	#$Control/Icon.visible = false
	$TextureRect.call("switch")
	yield(get_tree().create_timer(1.5),"timeout")
	#$Control/Icon.visible = true
	#yield(self,"done_loading")
	#pass


func _sanity_checks():
	var dl_object = GDDL.new()
	dl_object.set_agent("murse/0.3.0")
	var response = dl_object.download_to_string(default_url+"/reithreads")
	if response != str(4):
		error_handler("Default URL invalid!")
		yield(self,"error_handled")
	
		
		
func error_handler(error):
	var dunn = preload("res://assets/this-is-bad.wav")
	$SFX.stream = dunn
	$SFX.play()
	$Popup1.set("dialog_text",str(error))
	$Popup1.popup()
	yield($Popup1,"pressed")
	var val = $Popup1.val
	print(val) 
	emit_signal("error_handled")


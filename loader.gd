extends Control
const GDDL = preload("res://gdnative/gddl.gdns")
const main = preload("res://Main.tscn")
var default_url = "https://toast.openfortress.fun/toast"
const CONTINUE = 0
const RETRY = 1
const HCF = 2  # use an enum damnit!!!!!!
const INPUT = 3
var gd = GDDL.new()
var mainn
var t = Thread.new()
var thread_done = false
signal error_handled
var error_result
var error_input
# Called when the node enters the scene tree for the first time.

		
		
func _ready():
	if gd == null:
		var dir = Directory.new()
		print(OS.get_name())
		if OS.get_name() == "X11":
			dir.copy("res://libgddl.so",OS.get_executable_path().get_base_dir() + "/libgddl.so")
		else:
			var z = dir.copy("res://libgddl.dll",OS.get_executable_path().get_base_dir().plus_file("libgddl.dll"))
			if z != OK:
				print("??????? something's gone wrong are you on wine")
				get_tree().quit()
		OS.execute(OS.get_executable_path(),[],false)
		get_tree().quit()
#	var newver = gd.download_to_string("/latest_launcher_ver")  ## commented out for now as it hasn't been implemented serverside yet, but it does work
#	if newver > version:
#		var pid = OS.get_process_id()
#		if OS.get_name() == "X11":
#			var exec_path = ProjectSettings.globalize_path("user://" + newver)
#			gd.download_file("/latest_launcher_ver_linux",exec_path) # download latest launcher...
#			var cmd_str = exec_path + "& kill " + str(pid) 
#			OS.execute("/bin/bash",["-c",cmd_str])
		
	#get_tree().change_scene("res://Main.tscn")
	var dl_object = GDDL.new()
	assert(dl_object != null)
	print(dl_object)
	var response = dl_object.download_to_string(default_url+"/reithreads")
	print(response)
	if dl_object.get_error() != OK:
		error_handler("Default URL invalid, or the internets down. Please check your connection first. Either:\nQuit.\nTry Again.\nInput another valid URL.\nDetailed error for nerds:\n" + str(dl_object.get_detailed_error()),true,false)
		yield(self,"error_handled")
		match error_result:
			RETRY:
				return _ready()
			HCF:
				get_tree().quit()
			INPUT:
				default_url = error_input
	yield(get_tree().create_timer(3),"timeout")
	$ViewportContainer/Viewport/Spatial.stop()
	$TextureRect.stop()
	yield(get_tree().create_timer(2),"timeout")
	mainn = main.instance()
	add_child(mainn)
	yield(mainn,"draw")
	$Control.modulate = Color.transparent
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property($LoaderUI,"modulate",Color.transparent,1.5)
	tween.tween_property($Control,"modulate",Color.white,1.5)
	#$Control/Icon.visible = false
	$TextureRect.call("switch")
	yield(get_tree().create_timer(1.5),"timeout")
	$Control.connect("started",$TextureRect,"_on_main_spin_start")
	$Control.connect("all_done",$TextureRect,"_on_main_spin_stop")
	$TextureRect.in_main = true
	#$Control/Icon.visible = true
	#yield(self,"done_loading")
	#pass

func error_handler(error,input=false,cont=true):
	var dunn = preload("res://assets/this-is-bad.wav")
	$SFX.stream = dunn
	$SFX.play()
	$Popup1.init(error,input,cont)
	$Popup1.popup()
	yield($Popup1,"tpressed")
	error_result = $Popup1.val
	emit_signal("error_handled")
	if input:
		error_input = $Popup1.text


extends Control
const GDDL = preload("res://gdnative/gddl.gdns")
const main = preload("res://Main.tscn")
var default_url = "https://toastware.org/toast/"
const version = 1
const CONTINUE = 0
const RETRY = 1
const HCF = 2  # use an enum!!
const INPUT = 3
var gd = GDDL.new()
var mainn
var t = Thread.new()
var thread_done = false
signal error_handled
var error_result
var error_input

		
func _ready():
	if gd == null:
		var dir = Directory.new()
		var z
		print(OS.get_name())
		if OS.get_name() == "X11":
			z = dir.copy("res://libgddl.so",OS.get_executable_path().get_base_dir().plus_file("libgddl.so"))
		else:
			z = dir.copy("res://libgddl.dll",OS.get_executable_path().get_base_dir().plus_file("libgddl.dll"))
		if z != OK:
			print("??????? something's gone wrong...")
			OS.kill(OS.get_process_id())
		OS.execute(OS.get_executable_path(),[],false)
		OS.kill(OS.get_process_id())
	var newver = gd.download_to_string(default_url+"toastware/latest_t2.ver")
	if not newver.is_valid_integer():
		error_handler("Can't check for latest launcher version! could be an internet connection issue.",false,false)
		yield(self,"error_handled")
		match error_result:
			HCF:
				OS.kill(OS.get_process_id())
			RETRY:
				OS.kill(OS.get_process_id())
	if int(newver) > version:
		if OS.get_name() == "X11":
			var exec_path = ProjectSettings.globalize_path("user://" + newver)
			gd.download_file(default_url + "toastware/latest_t2.nix",exec_path) # download latest launcher...
			if gd.get_error() == 0:
				OS.execute("chmod",["+x",exec_path])
				OS.execute(exec_path,[],false)
				OS.kill(OS.get_process_id())
		else:
			var exec_path = ProjectSettings.globalize_path("user://" + newver)
			gd.download_file(default_url+ "toastware/latest_t2.exe",exec_path) # download latest launcher...
			if gd.get_error() == 0:
				OS.execute(exec_path,[],false)
				OS.kill(OS.get_process_id())
	print("Downloading failed...")
	var dl_object = GDDL.new()
	assert(dl_object != null)
	print(dl_object)
	var response = dl_object.download_to_string(default_url+"/toastware/default_t2.threads")
	print(response)
	yield(get_tree().create_timer(3),"timeout")
	#$ViewportContainer/Viewport/Spatial.stop()
	$TextureRect.stop()
	yield(get_tree().create_timer(2),"timeout") # to allow the transition
	mainn = main.instance() # instance the main scene... this will call _init()
	add_child(mainn) # add it! this will call _ready()
	yield(mainn,"draw") # we wait for it to all chug through
	$Control.modulate = Color.transparent # make the main scene transparent
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property($LoaderUI,"modulate",Color.transparent,1.5) # tween the two together
	tween.tween_property($Control,"modulate",Color.white,1.5)
	#$Control/Icon.visible = false
	$TextureRect.call("switch")
	yield(get_tree().create_timer(1.5),"timeout")
	$Control.connect("started",$TextureRect,"_on_main_spin_start") # hook up the toast to the main stuff
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
		if $Popup1.text != null:
			error_input = $Popup1.text

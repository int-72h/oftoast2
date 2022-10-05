extends Control

const GDDL = preload("res://gdnative/gddl.gdns")
onready var tvn = get_node("/root/Control/tvn")
var music = preload("res://assets/toast.wav")
var start = preload("res://assets/start.wav")
var done = preload("res://assets/done.wav")
const version = "0.0.1"
func _on_Icon_pressed():
	$Popup1.popup_centered(Vector2(50,50))
var revisions = []
var arr_of_threads = []
var downloading
var done_threads = 0
var done_threads_arr = []
var failed_files = []
var threads = 8
var delim = "/"
const ua = "toast_ua/" + version
signal all_done
signal file_done(path)
signal verif_fail(path)
signal thread_done(thread_no)
var has_of = false
var current_revision
var steam_dir
var of_dir


func get_of_path():
	if OS.get_name() == "X11":
		print("this is linux!")
		var dir = Directory.new()
		var home_dir = OS.get_data_dir().split("/.local")[0]
		print(home_dir)
		steam_dir = home_dir + "/.steam/steam/"
		of_dir = steam_dir + "steamapps/sourcemods/open_fortress"
		if dir.dir_exists(of_dir):
			print("ja you has the oopen fortress")
			has_of = true
		elif dir.dir_exists(steam_dir):
			print("no of? dam")
			dir.make_dir_recursive(of_dir)
		else:
			print("no steam??? wtf")
			return
	elif OS.get_name() == "Windows":
		print("this is windows!")
		var cmd_str = "@echo off\nfor /f \"tokens=2*\" %%a in ('reg query \"HKLM\\SOFTWARE\\WOW6432Node\\Valve\\Steam\" /v InstallPath') do @echo %%b"
		var temp = File.new()
		var tomp = Directory.new()
		tomp.remove("user://tmp.bat")
		temp.open("user://tmp.bat",File.WRITE)
		var bat_path = ProjectSettings.globalize_path("user://tmp.bat")
		temp.store_string(cmd_str)
		temp.close()
		var reg = []
		OS.execute("cmd.exe",["/C",bat_path],true,reg)
		if "ERROR" in reg[0]:
			print("no steam??? wtf")
			return
		else:
			steam_dir = reg[0]
			of_dir = steam_dir + "\\steamapps\\sourcemods\\open_fortress" 
		
	if has_of:
		var file = File.new()
		if file.file_exists(of_dir + "/.revision"):
			file.open(of_dir + "/.revision",file.READ)
			var rev = file.get_line()
			if rev.is_valid_integer():
				current_revision = int(rev)
				print(current_revision)

func _ready():
	get_of_path()
	tvn.ua = ua

func _on_Verify_pressed():
	start(true)

func _on_Update_pressed():
	start()

func _on_Control_file_done(path):
	$ProgressBar.value += 1

func _on_Control_thread_done(thread_no):
	$Label3.text = str(int($Label3.text) + 1)


func _on_Control_verif_fail(path):
	$Label2.text = str(int($Label2.text) + 1)

func start(verify=false):
	$Icon.spin = true
	$Icon.start_tween()
	$Music.stream = music
	$SFX.stream = start
	$SFX.play()
	$Music.play()
	$Update.disabled = true
	$Verify.disabled = true
	$ProgressBar.show()
	var url = "https://toast-eu.openfortress.fun"
	get_of_path()
	var path = of_dir
	if not("/toast/" in url):
		if url[-1] != '/':
			url += '/'
		url += "toast/" # basic string formatting
	if not("open_fortress" in path):
		if path[-1] != delim:
			path += delim
		path += "open_fortress" # basic string formatting
	var installed_revision = tvn.get_installed_revision(path) # see if anythings already where we're downloading
	print(installed_revision)
	threads = int(tvn.dl_file_to_mem(url + "reithreads"))
	var latest_ver = tvn.dl_file_to_mem(url + "reiversion")
	var latest_rev = int(tvn.dl_file_to_mem(url + "revisions/latest"))
	threads = 128
	var verif = Crypto.new()
	var key_obj = CryptoKey.new()
	var key = key_obj.load("res://assets/pubkey.pub",true)
	installed_revision = -1
	var revisions = tvn.fetch_revisions(url,installed_revision,latest_rev,verif,key_obj)
	var changes = tvn.replay_changes(revisions)
	var writes = filter(tvn.TYPE_WRITE,changes)
	var dl_array = []
	for x in writes:
		dl_array.append([url + "objects/" + x["object"], path + "/" + x["path"]])
	for x in filter(tvn.TYPE_DELETE,changes):
		var error
		var dir = Directory.new()
		if dir.file_exists(path + "/" + x["path"]):
			error = dir.remove(path + "/" + x["path"])
			if error != OK:
				print_debug(error)
	for x in filter(tvn.TYPE_MKDIR,changes):
		var error
		var dir = Directory.new()
		error = dir.make_dir_recursive(path +"/" + x["path"])
		if error != OK and (error != 20):
			print_debug(error)
	var error
	var dir = Directory.new()
	error = dir.remove(path + "/.revision")
	if error != OK:
		print_debug(error)
	$ProgressBar.max_value = len(dl_array)
	if verify == false:
		 work(dl_array)
	else:
		verify(dl_array)
		pass
	yield(self,"all_done")
	var file = File.new()
	error = file.open(path+ '/.revision', File.WRITE)
	if error != OK:
		print_debug(error)
	file.store_string(str(latest_rev))
	file.close()
	$Icon.stop_tween()
	$SFX.stream = done
	$SFX.volume_db = 20
	$SFX.play()
	$Music.stop()
	

func _work(arr):
	var arr_of_files = arr[0]
	var thread_no = arr[1]
	for dl in arr_of_files:
		var file_downloaded = false
		while file_downloaded == false:
			var dl_object = GDDL.new()
			var path = dl[1]
			var url = dl[0]
			if not dl_object.download_file(url,path):
				print("uh oh.")
				print_debug(dl_object.get_error()) # we really need to handle these properly.
				emit_signal("verif_fail",path)
			else:
				emit_signal("file_done",path)
				file_downloaded = true
	print("whole thread done!")
	done_threads_arr.append(thread_no)

func chunk(arr, size):
	var ret = []
	var i = 0
	var j = -1
	for el in arr:
		if i % size == 0:
			ret.push_back([])
			j += 1;
		ret[j].push_back(el)
		i += 1
	return ret


static func filter(type, candidate_array):
	var filtered_array := []
	for candidate_value in candidate_array:
		if candidate_value["type"] == type:
			filtered_array.append(candidate_value)
	return filtered_array


func work(arr):
	print(len(arr))
	var z
	print(threads)
	if threads == 1:
		_work([arr,0])
	elif len(arr) > threads:
		z = chunk(arr,int(ceil(len(arr) / threads)))
		for x in range(0,threads):
			var t = Thread.new()
			arr_of_threads.append(t)
			arr_of_threads[x].start(self,"_work",[z[x],x])
		
	else:
		threads = len(arr)
		for x in range(0,len(arr)):
			var t = Thread.new()
			arr_of_threads.append(t)
			arr_of_threads[x].start(self,"_work",[[arr[x]],x])
	print_debug("threads started")
	

func verify(dl_array):
	var redl_array = []
	var file = File.new()
	for dl in dl_array:
		if dl["hash"] != file.get_sha256(file["path"]):
			emit_signal("verif_fail",dl["path"])
			redl_array.append(dl)
	if redl_array == []:
		emit_signal("all_done")
	else:
		work(redl_array)


func _process(delta):
	if done_threads_arr != []:
		for t in done_threads_arr:
			arr_of_threads[t].wait_to_finish()
			done_threads += 1
			emit_signal("thread_done",0)
		done_threads_arr = []
	if done_threads == threads:
		emit_signal("all_done")



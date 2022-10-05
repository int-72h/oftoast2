extends Control

const GDDL = preload("res://gdnative/gddl.gdns")
onready var tvn = get_node("/root/Control/tvn")
onready var steam = get_node("steam")
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
var delim = ""
const ua = "murse/0.3.0" # temporary
signal all_done
signal file_done(path)
signal verif_fail(path)
signal thread_done(thread_no)

func _ready():
	if OS.get_name() == "X11":
		delim = "/"
	else:
		delim = "\\"
	steam.get_of_path()
	tvn.ua = ua

func _on_Verify_pressed():
	start(true)

func _on_Update_pressed():
	start()

func _on_Control_file_done(path):
	$ProgressBar.value += 1
	$Label7.text =  str(int($Label7.text) + 1)

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
	var path = steam.of_dir
	if not("/toast/" in url):
		if url[-1] != '/':
			url += '/'
		url += "toast/" # basic string formatting
#	if not("open_fortress" in path):
#		if path[-1] != delim:
#			path += delim
#		path += "open_fortress" # this is left untill we have a path input box.
	var installed_revision = tvn.get_installed_revision(path) # see if anythings already where we're downloading
	print("installed revision: " + str(installed_revision))
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
		dl_array.append([url + "objects/" + x["object"], path + delim + x["path"],x["hash"]])
	for x in filter(tvn.TYPE_DELETE,changes):
		var error
		var dir = Directory.new()
		if dir.file_exists(path + delim + x["path"]):
			error = dir.remove(path + delim + x["path"])
			if error != OK:
				print_debug(error)
	for x in filter(tvn.TYPE_MKDIR,changes):
		var error
		var dir = Directory.new()
		error = dir.make_dir_recursive(path +delim+ x["path"])
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
	$SFX.play()
	$Music.stop()
	$Update.disabled = false
	$Verify.disabled = false
	

func _work(arr):
	var arr_of_files = arr[0]
	var thread_no = arr[1]
	for dl in arr_of_files:
		var file_downloaded = false
		while file_downloaded == false:
			var dl_object = GDDL.new()
			dl_object.set_agent(ua)
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
	var t = Thread.new()
	t.start(self,"_verify",dl_array)


func _verify(dl_array):
	var redl_array = []
	var file = File.new()
	for dl in dl_array:
		var f = file.open(dl[1],File.READ)
		if dl[2] != file.get_md5(dl[1]):
			print("MISMATCH:" + file.get_md5(dl[1]) + " " + dl[2])
			emit_signal("verif_fail",dl[1])
			redl_array.append(dl)
		else:
			emit_signal("file_done",dl[1])
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

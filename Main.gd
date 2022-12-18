extends Control

const GDDL = preload("res://gdnative/gddl.gdns")
onready var tvn = get_node("/root/Control/Control/tvn")
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
var dl_array
var threads = 8
var delim = ""
const ua = "murse/0.3.0" # temporary
var installed_revision
var latest_rev
signal all_done
signal file_done(path)
signal verif_fail(path)
signal thread_done(thread_no)
signal error_handled
var path
var url
var mut = Mutex.new()

func thing():
	tvn.ua = ua
	url = "https://toast1.openfortress.fun/toast/"
	var gd = GDDL.new()
	if OS.get_name() == "X11":
		delim = "/"
	else:
		delim = "\\"
	steam.get_of_path()
	steam.check_tf2_sdk_exists()
	path = steam.of_dir
	if path == null:
		$VBoxContainer/Update.disabled = true
		$VBoxContainer/Verify.disabled = true
		installed_revision = -1
		#do thingy here to get path.
	else:
		installed_revision = tvn.get_installed_revision(path) # see if anythings already where we're downloading
		print("installed revision: " + str(installed_revision))
		$AdvancedPanel.inst_dir.text = path
	#threads = int(tvn.dl_file_to_mem(url + "/reithreads"))
	threads = 64
	latest_rev = int(tvn.dl_file_to_mem(url + "/revisions/latest"))
	$AdvancedPanel.threads.text = str(threads)
	$AdvancedPanel.target_rev.text = str(latest_rev)
	revisions = tvn.fetch_revisions(url,-1,12)
	print("revision len is " + str(len(revisions)))
	emit_signal("draw")

func _ready():
#	var t = Thread.new()
#	t.start(self,"thing") # this reduces hitching
	call_deferred("thing")
	$advlabel.rect_position = Vector2(-800,0)
	$AdvancedPanel.rect_position = Vector2(-800,150)

func _on_Verify_pressed():
	start(true)
	
func _on_Update_pressed():
	start()


func _on_Control_file_done():
	$ProgressBar.value +=1
	
func start(verify=false):
	dl_array = []
	$ProgressBar.show()
	$Icon.spin = true
	$Icon.start_tween()
	$Music.stream = music
	$SFX.stream = start
	$SFX.play()
	$Music.play()
	$VBoxContainer/Update.disabled = true
	$VBoxContainer/Verify.disabled = true
	$ProgressBar.show()
	var dir = Directory.new()
	var error
#	if not("open_fortress" in path):
#		if path[-1] != delim:
#			path += delim
#		path += "open_fortress" # this is left untill we have a path input box.
	if tvn.check_partial_download(path) != tvn.FAIL:
		verify = true
	if installed_revision == -11 and verify == false: # the zip thing
		var t = Thread.new()
		#arr_of_threads.append(t)
		#arr_of_threads[0].start(self,"_dozip",["",path]) ## no url as it hasn't been implemented serverside yet
	else:
		installed_revision = -1
		if verify:
			installed_revision = -1
		var changes = tvn.replay_changes(revisions)
		var writes = filter(tvn.TYPE_WRITE,changes)
		for x in writes:
			dl_array.append([url + "objects/" + x["object"], path + delim + x["path"],x["hash"]])
		for x in filter(tvn.TYPE_DELETE,changes):
			dir = Directory.new()
			if dir.file_exists(path + delim + x["path"]):
				error = dir.remove(path + delim + x["path"])
				if error != OK:
					print_debug(error)
		for x in filter(tvn.TYPE_MKDIR,changes):
			dir = Directory.new()
			error = dir.make_dir_recursive(path +delim+ x["path"])
			if error != OK and (error != 20):
				print_debug("CRITICAL: can't write ")
		error = dir.remove(path + "/.revision")
		if error != OK:
			print_debug("no .revision, ok....")
		var file = File.new()
		error = file.open(path+ '/.dl_started', File.WRITE) # allows us to check for partial dls
		if error != OK:
			error_handler("can't write dl_started file... this is a non-issue really, but could be a sign for worse things. Press OK to continue.")
			yield(self,"error_handled")
		file.store_string(str(latest_rev))
		file.close()
		$ProgressBar.max_value = len(dl_array)
		if verify == false:
			work()
			pass
		else:
			verify()
			pass
	yield(self,"all_done")
	var file = File.new()
	error = file.open(path+ '/.revision', File.WRITE)
	if error != OK:
		error_handler("Failed to write .revision file: the game may launch, however it won't update without a complete reinstall.\nThis could be due to a permissions error, running out of space, or something else.")
		yield(self,"error_handled")
	file.store_string(str(latest_rev))
	file.close()
	$Icon.stop_tween()
	$SFX.stream = done
	$SFX.play()
	$Music.stop()
	$ProgressBar.hide()
	$VBoxContainer/Update.disabled = false
	$VBoxContainer/Verify.disabled = false
	

func _dozip(arr):
	var url = arr[0]
	var lpath = arr[1]
	var dl_object = GDDL.new()
	var ziploc = ProjectSettings.globalize_path("user://latest.zip")
	var error = tvn.download_file(url,ziploc)
	if error != tvn.OK:
		error_handler("failed to download zip: " + error)
		yield(self,"error_handled")
	var z = dl_object.unzip(ziploc,lpath)
	if z != "0":
		error_handler("failed to unzip!")
		yield(self,"error_handled")
	var f = Directory.new()
	f.remove(ziploc) ## delete zipx
	done_threads_arr.append(0)

func _work(arr):
	var thread_no = arr
	print("hello from thread " + str(thread_no))
	var all_dls_done = false
	while !all_dls_done:
		mut.lock()
		print("we locked the mutex...")
		print(len(dl_array))
		if len(dl_array) == 0:
			mut.unlock()
			all_dls_done = true
			break
		var dl = dl_array.pop_back()
		mut.unlock()
		print("and we unlocked it!")
		print(dl)
		var file_downloaded = false
		while file_downloaded == false:
			var dl_object = GDDL.new()
			dl_object.set_agent(ua)
			var path = dl[1]
			var url = dl[0]
			if not dl_object.download_file(url,path):
				mut.lock()
				print("uh oh.")
				error_handler(dl_object.get_error() + " Path: " + path + "\n url: " + url)
				yield(self,"error_handled")
				mut.unlock()
				print("we've unlocked the mutex at least... thread "+ str(thread_no))
			else:
				emit_signal("file_done")
				file_downloaded = true
	print("And we're done!")
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


func work():
	if threads == 1:
		var t = Thread.new()
		arr_of_threads.append(t)
		arr_of_threads[0].start(self,"_work",0)
		#_work(0)
	elif len(dl_array) > threads:
		for x in range(0,threads):
			var t = Thread.new()
			arr_of_threads.append(t)
			arr_of_threads[x].start(self,"_work",x)
		
	else:
		for x in range(0,len(dl_array)):
			var t = Thread.new()
			arr_of_threads.append(t)
			arr_of_threads[x].start(self,"_work",x)
	print_debug("threads started")
	
func verify():
	var t = Thread.new()
	t.start(self,"_verify")


func _verify():
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
		dl_array = redl_array
		work()


func _process(delta):
	if len(done_threads_arr) > 0:
		for t in done_threads_arr:
			arr_of_threads[t].wait_to_finish()
			done_threads += 1
			emit_signal("thread_done",0)
		done_threads_arr = []
	if done_threads == threads:
		emit_signal("all_done")

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


func _on_Advanced_pressed():
	var transition = Tween.TRANS_BACK
	var easeing = Tween.EASE_IN_OUT
	var time = 0.75
	if !$AdvancedPanel.visible:
		$AdvancedPanel.visible = true
		$advlabel.visible = true
		$VBoxContainer/Advanced.disabled = true
		$AdvancedPanel.rect_position = Vector2(-800,150)
		$advlabel.rect_position = Vector2(-700,150)
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property($AdvancedPanel,"rect_position",Vector2(400,150),time).set_trans(transition).set_ease(easeing)
		#yield(get_tree().create_timer(0.1),"timeout")
		tween.tween_property($advlabel,"rect_position",Vector2(408,0),time).set_trans(transition).set_ease(easeing)
		tween.tween_property($BlogPanel/TabContainer,"modulate",Color.transparent,time).set_trans(transition).set_ease(easeing)
		tween.tween_property($templabel,"modulate",Color.transparent,time).set_trans(transition).set_ease(easeing)
		yield(get_tree().create_timer(time),"timeout")
		$BlogPanel.visible = !$BlogPanel.visible
		$VBoxContainer/Advanced.disabled = false
	else:
		$BlogPanel.visible = true
		$VBoxContainer/Advanced.disabled = true
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property($AdvancedPanel,"rect_position",Vector2(-800,150),time).set_trans(transition).set_ease(easeing)
		tween.tween_property($advlabel,"rect_position",Vector2(-800,150),time).set_trans(transition).set_ease(easeing)
		tween.tween_property($BlogPanel/TabContainer,"modulate",Color.white,time).set_trans(transition).set_ease(easeing)
		tween.tween_property($templabel,"modulate",Color.white,time).set_trans(transition).set_ease(easeing)
		yield(get_tree().create_timer(0.5),"timeout")
		$AdvancedPanel.visible = !$AdvancedPanel.visible
		$VBoxContainer/Advanced.disabled = false
		$advlabel.visible = false

func _throw_error(): # throws an error
	error_handler("ERROR TEST... LOVELY")
	yield(self,"error_handled")
	print("this should print after the error has been handled")

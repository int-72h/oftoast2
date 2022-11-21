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
var threads = 8
var delim = ""
const ua = "murse/0.3.0" # temporary
var installed_revision
var latest_rev
signal all_done
signal file_done(path)
signal verif_fail(path)
signal thread_done(thread_no)
var path

func thing():
	tvn.ua = ua
	var url = "https://toast1.openfortress.fun/toast/"
	print(tvn.url)
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
	threads = int(tvn.dl_file_to_mem(url + "/reithreads"))
	latest_rev = int(tvn.dl_file_to_mem(url + "/revisions/latest"))
	$AdvancedPanel.threads.text = str(threads)
	$AdvancedPanel.target_rev.text = str(latest_rev)
	revisions = tvn.fetch_revisions(installed_revision,latest_rev) # we precalculate the revision data sneakily

func _ready():
#	var t = Thread.new()
#	t.start(self,"thing") # this reduces hitching
	thing()
	$advlabel.rect_position = Vector2(-800,0)
	$AdvancedPanel.rect_position = Vector2(-800,150)

func _on_Verify_pressed():
	start(true)

func _on_Update_pressed():
	start()


func _on_Control_file_done(_eggs):
	$ProgressBar.value +=1
	
func start(verify=false):
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
#	if not("open_fortress" in path):
#		if path[-1] != delim:
#			path += delim
#		path += "open_fortress" # this is left untill we have a path input box.
	if installed_revision == -1 and verify == false: # the zip thing
		var t = Thread.new()
		arr_of_threads.append(t)
		arr_of_threads[0].start(self,"_dozip",["",path]) ## no url as it hasn't been implemented serverside yet
	else:
		#installed_revision = -1
		if verify:
			installed_revision = -1
		var changes = tvn.replay_changes(revisions)
		var writes = filter(tvn.TYPE_WRITE,changes)
		var dl_array = []
		for x in writes:
			dl_array.append([tvn.url + "objects/" + x["object"], path + delim + x["path"],x["hash"]])
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
		var file = File.new()
		error = file.open(path+ '/.dl_started', File.WRITE) # allows us to check for partial dls
		if error != OK:
			print_debug(error)
		file.store_string(str(latest_rev))
		file.close()
		$ProgressBar.max_value = len(dl_array)
		if verify == false:
			work(dl_array)
			pass
		else:
			verify(dl_array)
			pass
	yield(self,"all_done")
	var file = File.new()
	var error = file.open(path+ '/.revision', File.WRITE)
	if error != OK:
		print_debug(error)
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
	if not tvn.download_file(url,ziploc):
		print("uh oh.") # do more error handling
	var z = dl_object.unzip(ziploc,lpath)
	if z != "0":
		print("uh oh.")
	var f = Directory.new()
	f.remove(ziploc) ## delete zipx
	done_threads_arr.append(0)

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


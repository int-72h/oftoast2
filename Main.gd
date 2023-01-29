extends Control


signal all_done
signal file_done(path)
signal verif_fail(path)
signal error_handled
signal started
signal settings_ok
const CONTINUE = 0
const RETRY = 1
const HCF = 2  # use an enum damnit!!!!!!
const INPUT = 3
const GDDL = preload("res://gdnative/gddl.gdns")
const TVN = preload("res://tvn.gd")
var music = preload("res://assets/toast.wav")
var start_music = preload("res://assets/start.wav")
var done = preload("res://assets/done.wav")
var user_threads
var revisions = []
var arr_of_threads = []
var downloading
var done_threads = 0
var done_threads_arr = []
var failed_files = []
var dl_array = []
var threads = OS.get_processor_count()
var delim = ""
var changes
var installed_revision
var max_threads = 72
var latest_rev
var path
var url
var writes
var mut = Mutex.new()
var error_result: int
var error_input: String
var target_revision: int
onready var tvn = TVN.new()
onready var steam = get_node("steam")



func _ready():
#	var t = Thread.new()
#	t.start(self,"thing") # this reduces hitching but stops debugging!
	call_deferred("thing")
	$advlabel.rect_position = Vector2(-800, 0)
	$AdvancedPanel.rect_position = Vector2(-800, 150)
	
func thing():
	url = "https://toast.openfortress.fun/toast/" # use mirrors idk
	var gd = GDDL.new()
	if OS.get_name() == "X11":
		delim = "/"
	else:
		delim = "\\"
	steam.get_of_path()
	steam.check_tf2_sdk_exists()
	path = steam.of_dir
	print(path)
	if path == null:
		$VBoxContainer/Update.disabled = true
		$VBoxContainer/Verify.disabled = true
		installed_revision = -1
		#do thingy here to get path.
	else:
		installed_revision = tvn.get_installed_revision(path)  # see if anythings already where we're downloading
		print("installed revision: " + str(installed_revision))
		$AdvancedPanel.inst_dir.text = path
		$FileDialog.current_path = path
	latest_rev = gd.download_to_string(url + "/revisions/latest")
	if gd.get_error() != OK:
		error_handler(
			"Downloading target threads and/or latest revision failed:\n" + str(gd.get_error())
		)
		yield(self, "error_handled")
		if error_result == RETRY:
			return thing()
	var tmp = do_stuff()
	if typeof(tmp) == TYPE_OBJECT:
		yield(tmp,"completed")
	latest_rev = int(latest_rev)
	target_revision = latest_rev
	$AdvancedPanel.threads.text = str(threads)
	if installed_revision == -1:
		$VBoxContainer2/Label.text = "NOT INSTALLED!"
	else:
		$VBoxContainer2/Label.text = "INSTALLED: " + str(installed_revision)
	$VBoxContainer2/Label2.text = "LATEST: " + str(latest_rev)
	if installed_revision == latest_rev:
		$VBoxContainer/Update.disabled = true
	emit_signal("draw")


func start(verify = false, dozip=true):
	$VBoxContainer3/Label2.text = "Downloading..."
	$VBoxContainer3/Label2.show()
	$VBoxContainer3/ProgressBar.show()
	$Music.stream = music
	$SFX.stream = start_music
	$SFX.play()
	$Music.play()
	$VBoxContainer/Update.disabled = true
	$VBoxContainer/Verify.disabled = true
	emit_signal("started")
	var dir = Directory.new()
	var error
	if tvn.check_partial_download(path) != tvn.FAIL:
		verify = true
#	if installed_revision == -1 and verify == false and dozip == true:  # the zip thing
#		pass
		#$VBoxContainer3/Label2.text = "Using Advanced Compressed Archival Technology™..."
		#var t = Thread.new()
		#arr_of_threads.append(t)
		#arr_of_threads[0].start(self,"_dozip",["",path]) ## no url as it hasn't been implemented serverside yet
	#else:
		if verify:
			$VBoxContainer3/Label2.text = "Verifying..."
			installed_revision = -1
			do_stuff()
		$VBoxContainer3/ProgressBar.max_value = len(dl_array)
		$VBoxContainer3/ProgressBar.value = 0
		for x in filter(tvn.TYPE_DELETE, changes):
			dir = Directory.new()
			if dir.file_exists(path + delim + x["path"]):
				error = dir.remove(path + delim + x["path"])
				if error != OK:
					print_debug(error)
		for x in filter(tvn.TYPE_MKDIR, changes):
			dir = Directory.new()
			error = dir.make_dir_recursive(path + delim + x["path"])
			if error != OK and (error != 20):
				print_debug("CRITICAL: can't write ")
		if verify == false:
			error = dir.remove(path + "/.revision")  # godot file/dir api consistently uses unix path seperators - GDNATIVE API DOESN'T?!
			if error != OK:
				print_debug("no .revision, ok....")
			var file = File.new()
			error = file.open(path + "/.dl_started", File.WRITE)  # allows us to check for partial dls
			if error != OK:
				error_handler(
					"can't write dl_started file... this is a non-issue really, but could be a sign for worse things. Press the continue button to continue."
				)
				yield(self, "error_handled")
			file.store_string(str(latest_rev))
			file.close()
			work()
		else:
			verify()
	yield(self, "all_done")
	var file = File.new()
	error = file.open(path + "/.revision", File.WRITE)
	if error != OK:
		error_handler(
			"Failed to write .revision file: the game may launch, however it won't update without a complete reinstall.\nThis could be due to a permissions error, running out of space, or something else.\nTo fix this manually, simply put a file called .revision in the open_fortress folder with the current revision number in.")
		yield(self, "error_handled")
	file.store_string(str(latest_rev))
	file.close()
	$SFX.stream = done
	$SFX.play()
	$Music.stop()
	installed_revision = latest_rev
	$VBoxContainer2/Label.text = "INSTALLED: " + str(latest_rev)
	$VBoxContainer3/ProgressBar.hide()
	$VBoxContainer3/ProgressBar.value = 0
	$VBoxContainer3/Label2.hide()
	$VBoxContainer/Verify.disabled = false


func _dozip(arr):
	var url = arr[0]
	var lpath = arr[1]
	var dl_object = GDDL.new()
	var ziploc = ProjectSettings.globalize_path("user://latest.zip")
	var error = tvn.download_file(url, ziploc)
	if error != tvn.OK:
		error_handler("failed to download zip: " + error,false,false)
		yield(self, "error_handled")
		match error_result:
			RETRY:
				return _dozip(arr)
			
	var z = dl_object.unzip(ziploc, lpath)
	if z != "0":
		error_handler("failed to unzip!")
		yield(self, "error_handled")
	var f = Directory.new()
	f.remove(ziploc)  ## delete zipx
	done_threads_arr.append(0)

func work():
	for x in range(0, threads):
		var t = Thread.new()
		arr_of_threads.append(t)
		arr_of_threads[x].start(self, "_work", x)
	print_debug("threads started")

func _work(arr):
	var thread_no = arr
	print("hello from thread " + str(thread_no))
	var all_dls_done = false
	while !all_dls_done:
		mut.lock()
		if len(dl_array) == 0:
			mut.unlock()
			all_dls_done = true
			break
		var dl = dl_array.pop_back()
		mut.unlock()
		var file_downloaded = false
		while file_downloaded == false:
			var dl_object = GDDL.new()
			var path = dl[1]
			var url = dl[0]
			if not dl_object.download_file(url, path):
				mut.lock()
				print("uh oh.")
				error_handler(dl_object.get_detailed_error() + " Path: " + path + "\n url: " + url)
				yield(self, "error_handled")
				match error_result: # if we're retrying then we don't need to specify anything
					CONTINUE:
						emit_signal("file_done")
						file_downloaded = true
						print("continuing - bad idea...")
					
				mut.unlock()
				print("we've unlocked the mutex at least... thread " + str(thread_no))
			else:
				emit_signal("file_done")
				file_downloaded = true
	print("And we're done!")
	done_threads_arr.append(thread_no)


func filter(type, candidate_array):  # used for tvn shenanigans
	var filtered_array := []
	for candidate_value in candidate_array:
		if candidate_value["type"] == type:
			filtered_array.append(candidate_value)
	return filtered_array

func do_stuff():
	revisions = tvn.fetch_revisions(url, -1, int(latest_rev), false)  # returns an error string otherwise
	if typeof(revisions) != TYPE_ARRAY:
		error_handler(("Error fetching revisions: "+ revisions),false,false)
		yield(self, "error_handled")
		if error_result == RETRY or error_result == CONTINUE:
			return thing()
		return
	changes = tvn.replay_changes(revisions)
	writes = filter(tvn.TYPE_WRITE, changes)
	for x in writes:
		dl_array.append([url + "objects/" + x["object"], path + delim + x["path"], x["hash"]])
	print("stuff done")



func verify():
	var t = Thread.new()
	t.start(self, "_verify")
	arr_of_threads.append(t)


func _verify():
	if dl_array == []:
		print("huh?")
	var redl_array = []
	var file = File.new()
	for dl in dl_array:
		if dl[2] != file.get_md5(dl[1]):
			print("MISMATCH:" + file.get_md5(dl[1]) + " " + dl[2])
			#emit_signal("verif_fail", dl[1])
			redl_array.append(dl)
		else:
			emit_signal("file_done")
	$VBoxContainer3/ProgressBar.value = 0
	if redl_array == []:
		emit_signal("all_done")
	elif len(redl_array) == len(dl_array):
		start(false,true)
	else:
		dl_array = redl_array
		$VBoxContainer3/Label2.text = "Redownloading " + str(len(dl_array)) + " files"
		work()
	done_threads_arr.append(0)


func error_handler(error, input = false,cont=true):
	var dunn = preload("res://assets/this-is-bad.wav")
	$SFX.stream = dunn
	$SFX.play()
	$Popup1.init(error,input,cont)
	$Popup1.popup()
	yield($Popup1, "tpressed")
	error_result = $Popup1.val
	if error_result == INPUT:
		error_input = $Popup1.text
	emit_signal("error_handled")


func _on_Advanced_pressed():
	print($VBoxContainer/Advanced.disabled)
	var transition = Tween.TRANS_BACK
	var easeing = Tween.EASE_IN_OUT
	var time = 0.75
	$AdvancedPanel/MarginContainer/VBoxContainer/LauncherContainer/VBoxContainer/Threads/Text.text = str(threads)
	if !$AdvancedPanel.visible:
		$VBoxContainer/Update.disabled = true
		$VBoxContainer/Verify.disabled = true
		$AdvancedPanel.visible = true
		$advlabel.visible = true
		$VBoxContainer/Advanced.disabled = true
		$AdvancedPanel.rect_position = Vector2(-900, 150)
		$advlabel.rect_position = Vector2(-900, 150)
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property($AdvancedPanel, "rect_position", Vector2(528, 128), time).set_trans(transition).set_ease(
			easeing
		)
		#yield(get_tree().create_timer(0.1),"timeout")
		tween.tween_property($advlabel, "rect_position", Vector2(528, 24), time).set_trans(transition).set_ease(
			easeing
		)
		tween.tween_property($VBoxContainer3/BlogPanel, "modulate", Color.transparent, time).set_trans(transition).set_ease(
			easeing
		)
		tween.tween_property($templabel, "modulate", Color.transparent, time).set_trans(transition).set_ease(
			easeing
		)
		yield(get_tree().create_timer(time), "timeout")
		$VBoxContainer3/BlogPanel.visible = false
		$VBoxContainer/Advanced.disabled = false
	else:
		
		$VBoxContainer3/BlogPanel.visible = true
		$VBoxContainer/Advanced.disabled = true
		var z = check_settings()
		if typeof(z) == TYPE_OBJECT:
			yield(z,"completed")
		print_debug(z)
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property($AdvancedPanel, "rect_position", Vector2(-900, 150), time).set_trans(transition).set_ease(
			easeing
		)
		tween.tween_property($advlabel, "rect_position", Vector2(-900, 150), time).set_trans(transition).set_ease(
			easeing
		)
		tween.tween_property($VBoxContainer3/BlogPanel, "modulate", Color.white, time).set_trans(transition).set_ease(
			easeing
		)
		tween.tween_property($templabel, "modulate", Color.white, time).set_trans(transition).set_ease(
			easeing
		)
		yield(get_tree().create_timer(0.5), "timeout")
		$AdvancedPanel.visible = !$AdvancedPanel.visible
		$VBoxContainer/Advanced.disabled = false
		if installed_revision != latest_rev:
			$VBoxContainer/Update.disabled = false
		$VBoxContainer/Verify.disabled = false


func check_settings(): # this is awful rewrite at some point
#	if not check_install_path(path):
#		error_handler("Invalid path. Maybe you haven't got enough space idk.",true,false)
#		yield(self,"error_handled")
#		match error_result:
#			INPUT:
#				if check_install_path(error_input):
#					path = error_input
#				else:
#					return check_settings()
#			RETRY:
#				return check_settings()
	installed_revision = tvn.get_installed_revision(path)  # see if anythings already where we're downloading
	print("new installed revision: " + str(installed_revision))
	$AdvancedPanel.inst_dir.text = path
	$FileDialog.current_path = path
	if installed_revision == -1:
		$VBoxContainer2/Label.text = "NOT INSTALLED!"
	else:
		$VBoxContainer2/Label.text = "INSTALLED: " + str(installed_revision)
	return true
	



func check_install_path(path): # file picker does most of this for us but we need to check a few things 
	if not steam.check_disk_space(path):
		return false
	print("passed disk check")
	var file = File.new()
	var error = file.open(path.plus_file(".toast-test"), File.WRITE)
	if error != OK:
		return false
	return true

func _on_Verify_pressed():
	start(true)


func _on_Update_pressed():
	start()


func _on_Control_file_done():
	#print("done with file " + str($VBoxContainer3/ProgressBar.value) + "/" + str($VBoxContainer3/ProgressBar.max_value))
	$VBoxContainer3/ProgressBar.value += 1


func _throw_error():  # throws an error
	error_handler("ERROR TEST... LOVELY")
	yield(self, "error_handled")
	print("this should print after the error has been handled")


func _process(_delta):
	if len(done_threads_arr) > 0:
		for t in done_threads_arr:
			arr_of_threads[t].wait_to_finish()
			done_threads += 1
		done_threads_arr = []
	if done_threads == int(threads):
		emit_signal("all_done")
		done_threads = 0
		done_threads_arr = []


func _on_AdvancedPanel_picker_open():
	$FileDialog.popup()

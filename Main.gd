extends Control

const GDDL = preload("res://gdnative/gddl.gdns")
var music = preload("res://assets/toast.wav")
var start = preload("res://assets/start.wav")
var done = preload("res://assets/done.wav")
const version = "0.0.1"
signal thread_done(thread_no)
func _on_Icon_pressed():
	$Popup1.popup_centered(Vector2(50,50))
var revisions = []	
var arr_of_threads = []
func _on_Verify_pressed():
	pass
signal all_done
signal file_done(path)

 



func start():
	$Icon.spin = true
	$Icon.start_tween()
	$Music.stream = music
	$SFX.stream = start
	$SFX.play()
	$Music.play()
	$Update.disabled = true
	$Verify.disabled = true
	$ProgressBar.show()
	var url = "https://toast3.openfortress.fun"
	var path = "[fill path here]"
	if not("/toast/" in url):
		if url[-1] != '/':
			url += '/'
		url += "toast/" # basic string formatting
	var installed_revision = get_installed_revision(path) # see if anythings already where we're downloading
	var num_threads = 16
	var latest_ver = "0.0.1"
	var latest_rev = 9
	var verif = Crypto.new()
	var key_obj = CryptoKey.new()
	var key = key_obj.load("res://assets/pubkey.pub",true)
	var revisions = fetch_revisions(url,installed_revision,latest_rev,verif,key_obj)
	var changes = replay_changes(revisions)
	var writes = filter(TYPE_WRITE,changes)
	var dl_array = []
	for x in writes:
		dl_array.append([url + "objects/" + x["object"], path + "/" + x["path"]])
	for x in filter(TYPE_DELETE,changes):
		var error
		var dir = Directory.new()
		if dir.file_exists(path + "/" +  x["path"]):
			error = dir.remove(path + "/" + x["path"])
			if error != OK:
				print_debug(error)
	for x in filter(TYPE_MKDIR,changes):
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
	work(dl_array)
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
	

func _work(arr):
	var arr_of_files = arr[1]
	var thread_no = arr[2]
	for dl in arr_of_files:
		var dl_object = GDDL.new()
		var path = dl[1]
		var url = dl[0]
		print("hello from thread " + str(thread_no))
		print_debug("Downloading to:", path)
		if not dl_object.download_file(url,path):
			print("uh oh.")
			print_debug(dl_object.get_error()) # we really need to handle these properly!
		else:
			print("done!")
			emit_signal("file_done",path)
	emit_signal("thread_done",thread_no)

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


static func filter(type, candidate_array: Array)->Array:
	var filtered_array := []
	for candidate_value in candidate_array:
		if candidate_value["type"] == type:
			filtered_array.append(candidate_value)
	return filtered_array


func work(arr):
	var z = chunk(arr,8)
	for x in range(0,8):
		var t = Thread.new()
		arr_of_threads.append(t)
		arr_of_threads[x].start(self,"_work",[0,z[x],x])


func _on_thread_done(thread_no):
	arr_of_threads[thread_no].wait_to_finish()
	var flag = true
	for x in arr_of_threads:
		if x.is_active():
			flag = false
	if flag ==true:
		emit_signal("all_done")
	
	
func _on_Update_pressed():
	start()
	

	
	
	
	
const TYPE_WRITE = 0
const TYPE_DELETE = 2
const TYPE_MKDIR = 1

func replay_changes(changesets):
	var cumlmap = {}
	if changesets == null:
		return []
	for revision in changesets:
		for change in revision:
			cumlmap[change["path"]] = change
	return map_to_changes(cumlmap)

func changes_to_map(changes):
	var d = {}
	if changes == null:
		return d
	for x in changes:
		d[x["path"]] = x
	return d

func map_to_changes(changes):
	var d = []
	for key in changes:
		d.append(changes[key])
	return d

func invert_change(change):
	var newchange
	if change["type"] == TYPE_WRITE or TYPE_MKDIR:
		newchange = change
		newchange["type"] = TYPE_DELETE
		return newchange
	else:
		newchange = change
		newchange["type"] = TYPE_WRITE
		return newchange

func get_installed_revision(dir):
	var file = File.new() 
	var error = file.open(dir + '/.revision', File.READ)
	if error != OK:
		return -1
	else:
		return int(file.get_as_text())


func dl_file_to_mem(url,bin=false):
	var data = GDDL.new()
	var z = data.download_file(url,"/tmp/oggs")
	if not z:
		return print_debug(data.get_error())
	var file = File.new() 
	var error = file.open("/tmp/oggs", File.READ)
	var content
	if error != OK:
		return -1
	else:
		if bin == false:
			content =  file.get_as_text()
		else:
			content =  file.get_buffer(file.get_len())
	return content
	




func fetch_revisions(url, first, last, verif,key):
	for x in range(first+1,last+1):
		if not (x<0):
			var error = false
			var rev = dl_file_to_mem(url + "/revisions/" + str(x))
			var sig = dl_file_to_mem(url + "/revisions/" + str(x) + ".sig",true)
			var verified = verif.verify(HashingContext.HASH_SHA256, rev.sha256_buffer(), sig, key)
			var rev_json = JSON.parse(rev) ## handle the eror here
			#if rev_json.result["revision"] != x:
			#	error = true
			if (error == true) or (rev_json.error != OK):
				return -1
			revisions.append(rev_json.result) # ["changes"]
	return revisions



func _on_Control_file_done(path):
	$ProgressBar.value += 1

extends Node
class_name tvn
const GDDL = preload("res://gdnative/gddl.gdns")
var revisions = []
var ua = ""
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
	data.set_agent(ua)
	if bin == false:
		var ret = data.download_to_string(url)
		if ret:
			return ret
		else:
			error_handler(data.get_error())
	else:
		var z = data.download_file(url,"/tmp/oggs")
		if not z:
			error_handler(data.get_error())
		var file = File.new() 
		var error = file.open("/tmp/oggs", File.READ)
		var content
		if error != OK:
			return -1
		else:
			content =  file.get_buffer(file.get_len())
		return content
	
func error_handler(error):
	var dunn = preload("res://assets/this-is-bad.wav")
	get_node("/root/Control/SFX").stream = dunn
	get_node("/root/Control/SFX").play()
	#get_node("/root/Control/Popup1/Label2").set("dialog_text",str(error))
	#get_node("/root/Control/Popup1").popup()
	return yield(get_node("/root/Control/Popup1").get_val(str(error)),"completed")
	
	

func fetch_revisions(url, first, last, verif,key):
	for x in range(first+1,last+1):
		if not (x<0):
			var error = false
			var dl = GDDL.new()
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

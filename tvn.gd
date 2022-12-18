extends Node
class_name tvn
const GDDL = preload("res://gdnative/gddl.gdns")
var revisions = []
var ua = ""
var url
var key_obj =  CryptoKey.new()
var verif = Crypto.new()
const TYPE_WRITE = 0
const TYPE_DELETE = 2
const TYPE_MKDIR = 1
const OK = 0
const FAIL = 1
signal tvn_ready

func _ready():
	key_obj.load("res://assets/pubkey.pub",true)

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
		return FAIL
	else:
		return int(file.get_as_text())

func check_partial_download(dir):
	var file = File.new() 
	var error = file.open("/.dl_started", File.READ)
	if error != OK:
		return FAIL
	else:
		return int(file.get_as_text())


func download_file(url,path):
	var data = GDDL.new()
	data.set_agent(ua)
	data.download_file(url,path)
	if not data:
		return data.get_error()
	else:
		return OK


func dl_file_to_mem(url,bin=false):
	var data = GDDL.new()
	data.set_agent(ua)
	if bin == false:
		var ret = data.download_to_string(url)
		if ret:
			return ret
		else:
			return data.get_error()
	else:
		var z = data.download_to_array(url)
		if not z:
			return data.get_error()
		return z
	
	

func get_mirrors(url):
	var mirrorlist # do mirror things idk


func get_tag(revision):
	var dl = GDDL.new()
	var rev = dl_file_to_mem("/revisions/" + str(revision))
	var sig = dl_file_to_mem("/revisions/" + str(revision) + ".sig",true)
	var verified = verif.verify(HashingContext.HASH_SHA256, rev.sha256_buffer(), sig, key_obj)
	var rev_json = JSON.parse(rev)
	return revision["tag"]

func set_url(_url):
	if _url[-1] != '/':
		_url += '/'
	url = _url


func fetch_revisions(url,first, last):
	for x in range(first+1,last+1):
		if not (x<0):
			var error = false
			var dl = GDDL.new()
			dl.set_agent(ua)
			var rev = dl_file_to_mem(url + "revisions/" + str(x))
			var sig = dl_file_to_mem(url + "revisions/" + str(x) + ".sig",true)
			var verified = verif.verify(HashingContext.HASH_SHA256, rev.sha256_buffer(), sig, key_obj)
			var rev_json = JSON.parse(rev) ## handle the error here
			#if rev_json.result["revision"] != x:
			#	error = true
			if (error == true) or (rev_json.error != OK):
				return -1
			revisions.append(rev_json.result) # ["changes"]
			print("fetched revision " + str(x))
	return revisions

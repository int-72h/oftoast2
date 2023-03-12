extends Node
class_name tvn
const GDDL = preload("res://gdnative/gddl.gdns")
var revisions = []
var url
var key_obj =  CryptoKey.new()
var verif = Crypto.new()
const FAIL = 1
var dl_error = ""
const TYPE_WRITE = 0
const TYPE_DELETE = 2
const TYPE_MKDIR = 1


func _ready():
	key_obj.load("res://assets/pubkey.pub",true)

func replay_changes(changesets):
	var cumlmap = {}
	if changesets == null:
		return []
	for revision in changesets:
		for change in revision:
			cumlmap[change["path"]] = change
	var z = cumlmap.values()
	return z
	
func changes_to_map(changes):
	var d = {}
	if changes == null:
		return d
	for x in changes:
		d[x["path"]] = x
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

func check_partial_download(dir):
	var file = File.new() 
	var error = file.open(dir + "/.dl_started", File.READ)
	if error != OK:
		return -1
	else:
		return int(file.get_as_text())

func get_tag(revision): # not the most efficient?
	var dl = GDDL.new()
	var rev = dl.download_to_sring("/revisions/" + str(revision),key_obj)
	var rev_json = JSON.parse(rev)
	return rev_json["tag"]

func fetch_revisions(url,first, last,verif=true):
	for x in range(first+1,last+1):
		if not (x<0):
			var dl = GDDL.new()
			var rev = dl.download_to_string(url + "revisions/" + str(x))
			var sig = dl.download_to_array(url + "revisions/" + str(x) + ".sig")
			if dl.get_error() != OK:
				return "Download failiure! " + dl.get_detailed_error()
			var verified
			verified = verif.verify(HashingContext.HASH_SHA256, rev.sha256_buffer(), sig, key_obj) if verif else true
			if not verified:
				return "Signature invalid for revision " + str(x)
			var rev_json = JSON.parse(rev) ## handle the error here
			if rev_json.error != OK:
				return "Invalid JSON, Possible tampering serverside!"
			if rev_json.result["revision"] != x:
				return "Revision field doesn't match with file. Possible tampering serverside!"
			revisions.append(rev_json.result["changes"])
	return revisions

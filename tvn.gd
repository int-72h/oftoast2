extends Node
class_name tvn
const GDDL = preload("res://gdnative/gddl.gdns")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
	if change["type"] == 0 or 1:
		newchange = change
		newchange["type"] = 2
		return newchange
	else:
		newchange = change
		newchange["type"] = 0
		return newchange

func get_installed_revision(dir):
	var file = File.new() 
	var error = file.open(dir + '/.revision', File.READ)
	if error != OK:
		return -1
	else:
		return int(file.get_as_text())

extends Node

var of_path: String
var tf2_exists: bool
var of_exists: bool
var sdk_exists: bool


func get_of_path():
	if OS.get_name() == "X11":
		print("this is linux!")
		var dir = Directory.new()
		var home_dir = OS.get_data_dir().split(".local")[0]
		print(home_dir)
	elif OS.get_name() == "Windows":
		print("this is windows!")

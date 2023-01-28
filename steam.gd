extends Node

var tf2_exists: bool
var of_exists: bool
var sdk_exists: bool
const list_of_possible_steam_dirs = ["/.steam/steam","/.local/share/Steam","/.var/app/com.valvesoftware.Steam/data/Steam"]
var current_revision
var steam_dir
var of_dir


func get_of_path():
	if OS.get_name() == "X11":
		print("this is linux!")
		var dir = Directory.new()
		var home_dir = OS.get_data_dir().split("/.local")[0]
		print(home_dir)
		for i in list_of_possible_steam_dirs:
			steam_dir = home_dir + i
			of_dir = steam_dir + "/steamapps/sourcemods/open_fortress"
			if dir.dir_exists(of_dir):
				print("ja you has the oopen fortress")
				break
			elif dir.dir_exists(steam_dir):
				print("no of? dam")
				dir.make_dir_recursive(of_dir) 
				break
			else:
				print("no steam??? wtf")
		if not steam_dir:
			return
	elif OS.get_name() == "Windows":
		print("this is windows!")
		var cmd_str = "@echo off\nfor /f \"tokens=2*\" %%a in ('reg query \"HKLM\\SOFTWARE\\WOW6432Node\\Valve\\Steam\" /v InstallPath') do @echo %%b"
		var temp = File.new()
		var tomp = Directory.new()
		tomp.remove("user://tmp.bat")
		temp.open("user://tmp.bat",File.WRITE)
		var bat_path = ProjectSettings.globalize_path("user://tmp.bat")
		temp.store_string(cmd_str)
		temp.close()
		var reg = []
		OS.execute("cmd.exe",["/C",bat_path],true,reg)
		if "ERROR" in reg[0]:
			print("no steam??? wtf")
			return
		else:
			steam_dir = reg[0].split("\n")[0].strip_edges()
			of_dir = steam_dir + "\\steamapps\\sourcemods\\open_fortress"



func check_tf2_sdk_exists():
	var f = File.new()
	f.open(steam_dir + "/steamapps/libraryfolders.vdf",File.READ)
	var z = f.get_as_text()
	if "243750" in z:
		print("we got the sdk")
		sdk_exists = true
	if "440" in z:
		print("we got tf2")
		tf2_exists = true
			
			

func check_disk_space(path):
	if OS.get_name() == "X11":
		print("getting disk space...")
		var cmdstring = "df -PT | awk '{ if (NR!=1) {print $5, $7}}'"
		var temp = File.new()
		var tomp = Directory.new()
		tomp.remove("user://tmp.sh")
		temp.open("user://tmp.sh",File.WRITE)
		var sh_path = ProjectSettings.globalize_path("user://tmp.sh")
		temp.store_string(cmdstring)
		temp.close()
		var reg = []
		OS.execute("bash",[sh_path],true,reg)
		var a = []
		for x in reg:
			for z in x.split("\n"):
				var f = z.split(" ")
				a.append(f)
		print(a)
		var longest = [0,0]
		for x in a:
			if len(x) > 1:
				if path.begins_with(x[1]):
					if len(x[1]) > longest[0]:
						longest[0] = len(x[1])
						longest[1] = x
		if longest == [0,0]:
			return true
		if int(longest[1][0]) < 8589935: # 8gib, 1k blocks
			return false
		return true
	if OS.get_name() == "Windows":
		var cmd_str = "wmic logicaldisk get freespace,caption"
		var temp = File.new()
		var tomp = Directory.new()
		tomp.remove("user://tmp.bat")
		temp.open("user://tmp.bat",File.WRITE)
		var bat_path = ProjectSettings.globalize_path("user://tmp.bat")
		temp.store_string(cmd_str)
		temp.close()
		var reg = []
		OS.execute("cmd.exe",["/C",bat_path],true,reg)
		var a = []
		for x in reg:
			for z in x.split("\n"):
				var f = z.split(" ")
				a.append(f)
		a.pop_front() #remove caption
		for x in a:
			if path.begins_with(x[0]):
				if int(x[1]) <= 8589934592: #bytes
					return false
				return true

extends Control

const GDDL = preload("res://gdnative/gddl.gdns")

const version = "0.0.1"
signal thread_done(thread_no)
func _on_Icon_pressed():
	$Popup1.popup_centered(Vector2(50,50))
	
var arr_of_threads = []
func _on_Verify_pressed():
	$Icon.spin = false



func _work(dl_object, arr_of_files,thread_no):
	for dl in arr_of_files:
		var path = dl[1]
		var url = dl[0]
		print_debug("Downloading to:", path)
		if not dl_object.download_file(url,path):
			print_debug(dl_object.get_error())
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


func work(arr):
	var z = chunk(arr,8)
	for x in range(0,8):
		var f = GDDL.new()
		var t = Thread.new()
		arr_of_threads.append(t)
		arr_of_threads[x].start(self,"_work",f,z[x],x)



func _on_thread_done(thread_no):
	arr_of_threads[thread_no].wait_to_finish()

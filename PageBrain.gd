extends Control
const GDDL = preload("res://gdnative/gddl.gdns")
onready var tvn = get_node("/root/Control/Control/tvn")
enum {
	HTML_P,
	HTML_H1,
	HTML_LI
	}

const THUMBNAIL_HEIGHT = 150
const BAR_WIDTH = 872
const THUMB_WIDTH = floor(BAR_WIDTH/3)-20
func html2bbcode(pageText):
	pageText = pageText.replace("<strong>", "<b>");
	pageText = pageText.replace("</strong>", "</b>");
	pageText = pageText.replace("<b>", "[b]");
	pageText = pageText.replace("</b>", "[/b]");
	pageText = pageText.replace("<em>", "[i]");
	pageText = pageText.replace("</em>", "[/i]");	
	pageText = pageText.replace("<h1>", "[font=res://fonts/font_header.tres]");
	pageText = pageText.replace("</h1>", "[/font][LINEEND]");
	pageText = pageText.replace("<p>", "");
	pageText = pageText.replace("</p>", "[LINEEND]");
	pageText = pageText.replace("<li>", txt_bullet);
	pageText = pageText.replace("<code>", "[font=res://fonts/font_code.tres]");
	pageText = pageText.replace("</code>", "[/font][LINEEND]");
	pageText = pageText.replace("</li>", "");
	pageText = pageText.replace("&amp;", "&");
	pageText = pageText.replace("]]>", "");
	return pageText


func _ready():
	xml_parse(tvn.dl_file_to_mem("https://openfortress.fun/blog/rss/feed",false)) # get rss
	
signal draw_blog()
signal thread_done(tab_no)
var txt_bullet = "[EPICBOOL]"; # used for replacing list bullets in final steps
var title_arr = []
var desc_arr = []
var tot_rev
var done_drawing = false
var gddl = GDDL.new()
var tmp
onready var rtl1 = $PageViewer/RichTextLabel
onready var rtl2 = $PageViewer2/RichTextLabel
onready var rtl3 = $PageViewer3/RichTextLabel
onready var tab = self
func display_text(arr):
	var rtl = arr[0]
	var offset = arr[1]
	var tab_no = arr[2]
	print("hello from tab" + str(tab_no))
	var bb_imageQueue = []
	var bb_parsed = []
	var pageText = desc_arr[offset]
	var titleText = title_arr[offset]
	pageText = html2bbcode(pageText)
	bb_parsed.append("[font=res://fonts/font_header.tres]" + html2bbcode(titleText) + "[/font]\n")
	var pageSplit = pageText.split("\n");
	
	pageText = pageText.replace("[HEADINGEND]", "\n");
	pageText = pageText.replace("[PARAEND]", "\n");
	
	# get da focking text...
	var indents = 0;
	var img_no = 0
	var icon
	rtl.bbcode_text = "";
	for i in range(0, len(pageSplit)):
		var line = pageSplit[i];
		line = line.strip_edges();
		if "[LINEEND]" in line:
			line = line.replace("[LINEEND]", "");
		if ( len(line) == 0 ):
			continue;
		elif ( line.substr(0,4) == "<ul>" ):
			indents += 1;
			continue;
		elif ( line.substr(0,5) == "</ul>" ):
			indents -= 1;
			continue;
		elif ( "<img" in line ):
			print("image found...");
			var lineSplit = line.find("src=\"")+5;
			var getLineStart = line.substr(lineSplit).split("\"");
			var imageLink = getLineStart[0];
			var comb_name = imageLink.md5_text()
			var img_path = "user://"+comb_name+".png"
			bb_parsed.append("[img=600]user://" + comb_name + ".tres[/img]\n")
			var img_file = File.new()
			if not img_file.file_exists(img_path):
				gddl.download_file(imageLink,ProjectSettings.globalize_path(img_path))
			else:
				print("we fackin got it already, " + img_path )
			gen_tres(comb_name)
			if img_no == 0:
				icon = genthumbnail(comb_name)
				img_no +=1
			continue
		if ( indents > 1 ):
			line = line.replace(txt_bullet, "[color=#574168]•[/color]  ");
			line = "[color=#A8A8A8]"+line+"[/color]";
		else:
			line = line.replace(txt_bullet, "[color=#574168][b]-[/b][/color]  ");
		# construct the line
		var nextLine = "";
		for _g in range(0,indents):
			nextLine += "\t";
		nextLine += line;
		bb_parsed.append(nextLine+"\n");
	if icon:
		tab.set_tab_icon(tab_no,icon)
		tab.set_tab_title(tab_no,"")
		pass
	else:
		icon = genthumbnail("toast")
		tab.set_tab_icon(tab_no,icon)
		tab.set_tab_title(tab_no,"")
	for i in bb_parsed:
		rtl.append_bbcode(i)
		
func xml_parse(body):
	var p = XMLParser.new()
	var in_item_node = false
	var in_title_node = false
	var in_description_node = false
	body = body.to_utf8()
	p.open_buffer(body)
	while p.read() == OK:
		var node_type = p.get_node_type()
		var node_name
		var node_data
		if node_type == XMLParser.NODE_TEXT:
			node_data = p.get_node_data() # doesn't work if not text
		else:
			node_name = p.get_node_name() # doesn't work if text
		if(node_name == "item"):
			in_item_node = !in_item_node #toggle item mode

		if (node_name == "title") and (in_item_node == true):
			in_title_node = !in_title_node
			continue
		
		if(node_name == "description") and (in_item_node == true):
			in_description_node = !in_description_node
			continue
			
		if(in_description_node == true):
			if node_type == XMLParser.NODE_TEXT:
				desc_arr.append(node_data)
			else:
				desc_arr.append(node_name)
		
		if(in_title_node == true):
			if node_type == XMLParser.NODE_TEXT:
				title_arr.append(node_data)
			else:
				title_arr.append(node_name)
	tot_rev = len(title_arr)
	display_text([rtl1,0,0])
	display_text([rtl2,1,1])
	display_text([rtl3,2,2])
	emit_signal("draw_blog")
	tab.tabs_visible = true

#
			
	
func genthumbnail(name):
	var thumbnail_path = "user://thumb_" + name + ".png"
	var path  = "user://" + name + ".png"
	var file = File.new()
	var doresize = true
	if file.file_exists(thumbnail_path):
		print("thumbnail exists, gettining")
		#path = thumbnail_path
	var image_t = Image.new()
	var error = image_t.load(path)
	if error != OK:
		push_error("Couldn't load the image.")
	var texture = ImageTexture.new();
	var new_image = Image.new()
	if doresize: # we need to pad out the images to fit the width.
		var aspect_ratio = float(image_t.get_width()) / float(image_t.get_height()) 
		image_t.resize(aspect_ratio*THUMBNAIL_HEIGHT,THUMBNAIL_HEIGHT,4)
		var image_width = image_t.get_width()
		new_image.create(THUMB_WIDTH,THUMBNAIL_HEIGHT,false,Image.FORMAT_RGBA8)
		var padding_offset = -floor((image_width - THUMB_WIDTH )/2) # dunno why its minus, but this is the offset it needs to be be so it's in the centre of the new image.
		var image_rect = Rect2(Vector2(0,0),Vector2(image_width,THUMBNAIL_HEIGHT))
		new_image.blit_rect(image_t,image_rect,Vector2(padding_offset,0)) # blit the thumbnail into the new canvas
		new_image.save_png(thumbnail_path)
	texture.create_from_image(new_image)
	return texture

func gen_tres(image_name):
	var f = File.new()
	if f.file_exists("user://"+image_name+".tres"):
		return
	var image = Image.new()
	var error = image.load("user://" + image_name + ".png")
	if error != OK:
		push_error("Couldn't load the image.")
	var texture = ImageTexture.new();
	texture.create_from_image(image);
	var imageName = "user://"+image_name+".tres";
	var saved = ResourceSaver.save(imageName, texture);
	assert(saved == OK, "Returned "+str(saved));
	print(imageName+" ~ "+str(saved));
	
func _process(_delta):
	pass
	


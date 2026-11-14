extends Control

const PLAYER_SHEET := "res://Art Assets/Player - Walking Animations (Clean).png"
const SAM_SHEET := "res://Art Assets/Sam - Front walking spritesheet transparent.png"
const PLAYER_SPEED := 210.0
const PLAYER_RADIUS := 13.0
const PLAYER_SCALE := 0.19
const COLLEGE_CATEGORIES: Array[Dictionary] = [
	{
		"title": "Programs & Internships",
		"intro": "Gaining early understanding of scientific principles and skills can prepare students for future careers.\n(It also looks great on college applications!)",
		"bottom_note": "",
		"featured": [
			{"title": "Biotechnology Research and Fellowship Program (BRFP)", "short_title": "BRFP", "description": "A pre-apprenticeship training program that provides students with over 120 hours of combined laboratory, research, communication, and workforce readiness training.\n\nCost: $5,026\n\nRequirements: Must be New Jersey high school students aged 16 years or older (at least a rising sophomore too) and fill out a registration form.", "image": "", "url": "https://mycareer.nj.gov/training/52948"},
			{"title": "Waksman Institute Summer Experience (WISE)", "short_title": "WISE", "description": "A summer research program that allows high school students to isolate, sequence, and analyze genes. Once finalized, research data may be published to GenBank, a DNA sequence database managed by the National Center for Biotechnology Information (NCBI).\n\nCost: $2,200 (can take virtual bioinformatics course for $600)\n\nRequirements: Must have completed a high school biology course and fill out a registration form.", "image": "", "url": "https://wssp.rutgers.edu/wise"},
			{"title": "Princeton University Laboratory Learning Program (LLP)", "short_title": "Princeton LLP", "description": "An opportunity for high school students to work alongside Princeton researchers and professionals in both natural science and engineering laboratories.\n\nCost: $0 (free)\n\nRequirements: Must be 16 years or older by June 15 of the application year, be a U.S. citizen, live near the university, and complete a registration form.", "image": "", "url": "https://scienceoutreach.princeton.edu/laboratory-learning-program"},
		],
	},
	{
		"title": "Community Colleges",
		"intro": "New Jersey’s 19 county colleges host postsecondary CTE programs offering two-year Associate degrees and professional certificates.\nGraduates can transfer credits to four-year colleges and universities.",
		"bottom_note": "These colleges are known for their high transfer rates, specialized facilities, and graduate salary potential.",
		"featured": [
			{"title": "County College of Morris", "short_title": "County College of Morris", "description": "Acceptance rate: 95–100%\n\nAverage annual cost (full-time): $7,000–$14,200\n\nRequirements: Submit an application (fee: $30) and provide proof of high school completion. Specific clinical CTE tracks usually require a minimum GPA of 2.5, background checks, and a separate secondary application.", "image": "", "url": "https://www.ccm.edu/programs/"},
			{"title": "Brookdale Community College", "short_title": "Brookdale Community College", "description": "Acceptance rate: 100%\n\nAverage annual cost (full-time): $6,000–$10,700\n\nRequirements: Submit an application (fee: $25–30) and provide proof of high school completion. Specific clinical CTE tracks usually require a minimum GPA of 2.5, background checks, and a separate secondary application.", "image": "", "url": "https://www.brookdalecc.edu/about/about-the-college/"},
			{"title": "Raritan Valley Community College", "short_title": "Raritan Valley CC", "description": "Acceptance rate: 100%\n\nAverage annual cost (full-time): $6,000–$10,000\n\nRequirements: Submit an application (fee: $25–30) and provide proof of high school completion. Specific clinical CTE tracks usually require a minimum GPA of 2.5, background checks, and a separate secondary application.", "image": "", "url": "https://www.raritanval.edu/programs/academics/degree-certificate-programs/"},
		],
	},
	{
		"title": "Research Universities",
		"intro": "New Jersey is known for its research universities, which produce skilled scientists, engineers, and other PhD talent for the hundreds of existing research employers.\nBesides contributing to the workforce, these universities facilitate scientific breakthroughs that help develop therapies, medical devices, and the biotechnology industry.",
		"bottom_note": "As of Fall 2026.",
		"featured": [
			{"title": "Rutgers University (public)", "short_title": "Rutgers University", "description": "Member of the Association of American Universities (AUU); offers undergraduate, graduate, and medical programs across three campuses in New Brunswick, Newark, and Camden.\n\nAcceptance rate: 58.6%\n\nAverage annual cost (full-time): $24,700–$62,800\n\nRequirements: Submit an application (fee: $70) and provide proof of high school completion.", "image": "", "url": "https://www.rutgers.edu/"},
			{"title": "New Jersey Institute of Technology (NJIT) (public)", "short_title": "NJIT", "description": "Top-ranked university specializing in science, technology, engineering, and math (STEM).\n\nAcceptance rate: 66%\n\nAverage annual cost (full-time): $22,400–$42,300\n\nRequirements: Submit an application (fee: $75), provide proof of high school completion, and have a GPA of at least 3.0.", "image": "", "url": "https://catalog.njit.edu/about-university/"},
			{"title": "Princeton University (private)", "short_title": "Princeton University", "description": "A renowned Ivy League university in Princeton known for its scholarship, molecular biology, AI research, and graduate salaries.\n\nAcceptance rate: 4.2%\n\nAverage annual cost (full-time): $94,600–$96,400 per year\n\nRequirements: Submit an application (fee: $75) and provide proof of high school completion. GPA standard is an average of 3.96.", "image": "", "url": "https://www.princeton.edu/academics"},
		],
	},
]
const RESOURCE_ITEMS: Array[Dictionary] = [
	{"title": "BioNJ", "description": "BioNJ is the trade network representing New Jersey’s biotechnology and pharmaceutical companies. While the site is built largely for industry professionals, its intern recruiting page maps out how local life science companies partner with high schools, specialized STEM academies, and hands-on programs like Students 2 Science to bring younger students into the lab!\n\nStudents can search for internships and entry-level job opportunities across over 400 research-based organizations and participate in challenges and conferences.", "image": "", "url": "https://bionj.org/recruiting-nj-interns/"},
	{"title": "Research With New Jersey", "description": "Run by the New Jersey Commission on Science, Innovation, and Technology, this free database indexes over 7,200 professors, labs, and active research grants across eight major NJ institutions, including Rutgers, Princeton, NJIT, and Hackensack Meridian Health. Instead of digging through dozens of separate college websites, you can search a specific science topic, or paste in a paragraph about a project idea, to see which local researchers are publishing in that exact area and find their contact details!\n\nResearch With New Jersey is an online portal that connects students with employers, professionals in the field, and research opportunities.", "image": "", "url": "https://www.researchwithnj.com/"},
	{"title": "More Resources", "description": "More community and career resources will be added here.", "image": "", "url": ""},
]
const NAVY := Color("#192787")
const CREAM := Color("#FAF5E6")
const SAGE := Color("#5D9374")
const INK := Color("#42636a")

var player: CharacterBody2D
var player_sprite: AnimatedSprite2D
var room_objects: Array[Rect2] = []
var modal_open := false
var active_table := ""
var current_items: Array = []
var sam_dialogue_lines: Array[String] = []
var sam_dialogue_index := 0
var selected_category := -1
var selected_item := -1
var current_item_title: Label
var current_item_description: Label
var website_button: Button
var website_status: Label
var intro_layer: Control
var information_layer: Control
var intro_message: Label
var category_intro: Label
var category_bottom_note: Label
var featured_heading: Label
var featured_buttons: Array[Button] = []
var category_content_scroll: ScrollContainer
var interact_hint := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_depth_layers()
	_build_player()
	_build_room_objects()
	_build_overlays()
	_style_room_labels()
	_update_interaction_hint()
	_play_entry_dialogue()


func _physics_process(_delta: float) -> void:
	if modal_open:
		player.velocity = Vector2.ZERO
		player_sprite.stop()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.velocity = direction * PLAYER_SPEED
	if direction.length_squared() > 0.0:
		if absf(direction.x) > absf(direction.y):
			player_sprite.play("side_right" if direction.x > 0.0 else "side_left")
		else:
			player_sprite.play("front" if direction.y > 0.0 else "back")
	else:
		player_sprite.stop()
	var previous_position := player.position
	player.move_and_slide()
	if not _is_walkable(player.position):
		player.position = previous_position
		player.velocity = Vector2.ZERO
	var sam := get_node("Sam") as Node2D
	player.z_index = 1 if player.position.y > sam.position.y else -1
	_update_interaction_hint()
	_refresh_room_ui()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if modal_open:
		if event.keycode == KEY_ESCAPE:
			_close_overlays()
			get_viewport().set_input_as_handled()
		elif intro_layer.visible and event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_advance_sam_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		_try_exit_room()
	elif event.keycode == KEY_E:
		if _is_near_exit():
			_try_exit_room()
		elif _is_near_access_point("CollegeProgramsAccessPoint"):
			_open_information_screen("college", 0)
		elif _is_near_access_point("CollegeCommunityCollegesAccessPoint"):
			_open_information_screen("college", 1)
		elif _is_near_access_point("CollegeResearchUniversitiesAccessPoint"):
			_open_information_screen("college", 2)
		elif _is_near_access_point("ResourcesBioNJAccessPoint"):
			_open_information_screen("resources", 0)
		elif _is_near_access_point("ResourcesResearchNJAccessPoint"):
			_open_information_screen("resources", 1)
		elif _is_near_access_point("ResourcesMoreAccessPoint"):
			_open_information_screen("resources", 2)
		elif _is_near_table("CollegeTableAccessPoint"):
			_open_information_screen("college")
		elif _is_near_table("ResourcesTableAccessPoint"):
			_open_information_screen("resources")


func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(630, 620)
	player.collision_layer = 1
	player.collision_mask = 1
	player.z_index = 1
	add_child(player)
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.12, 0.15, 0.2, 0.28)
	shadow.polygon = PackedVector2Array([Vector2(-13, 2), Vector2(-9, -4), Vector2(9, -4), Vector2(13, 2), Vector2(8, 6), Vector2(-8, 6)])
	player.add_child(shadow)
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.sprite_frames = _player_frames()
	player_sprite.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE)
	player_sprite.position = Vector2(0, -56)
	player.add_child(player_sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PLAYER_RADIUS
	collision.shape = shape
	collision.position = Vector2(0, -7)
	player.add_child(collision)


func _build_room_objects() -> void:
	room_objects = [
		Rect2(Vector2(64, 184), Vector2(282, 422)),
		Rect2(Vector2(748, 432), Vector2(458, 178)),
	]


func _configure_depth_layers() -> void:
	# Keep the floor behind the player; furniture gets its own foreground depth.
	(get_node("MapArt") as CanvasItem).z_index = -2
	var foreground_names: Array[String] = [
		"CabinetShadow", "Cabinet", "CabinetLabel",
		"CollegeTableShadow", "CollegeTable", "CollegeTableTop", "CollegeTableLabel",
		"Flyer_CommunityColleges", "FlyerAccent_CommunityColleges", "FlyerLabel_CommunityColleges",
		"Flyer_ResearchUniversities", "FlyerAccent_ResearchUniversities", "FlyerLabel_ResearchUniversities",
		"Flyer_Internships", "FlyerAccent_Internships", "FlyerLabel_Internships",
		"ResourcesTableShadow", "ResourcesTable", "ResourcesTableTop", "ResourcesTableLabel",
		"Flyer_BioNJ", "FlyerAccent_BioNJ", "FlyerLabel_BioNJ",
		"Flyer_ResearchNJ", "FlyerAccent_ResearchNJ", "FlyerLabel_ResearchNJ",
		"Flyer_CareerResources", "FlyerAccent_CareerResources", "FlyerLabel_CareerResources",
	]
	for node_name in foreground_names:
		var art_node := get_node_or_null("MapArt/" + node_name) as CanvasItem
		if art_node != null:
			art_node.z_index = 2


func _build_overlays() -> void:
	intro_layer = Control.new()
	intro_layer.name = "SamTableDialogue"
	intro_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_layer.z_index = 20
	intro_layer.visible = false
	add_child(intro_layer)
	_add_panel(intro_layer, "DialogueCard", Rect2(70, 500, 1140, 152), Color("#19233B"), SAGE, 3)
	_add_rect(intro_layer, "PanelTrim", Rect2(74, 504, 1132, 8), SAGE)
	_add_sam_portrait(intro_layer, Rect2(92, 492, 112, 156))
	_add_label(intro_layer, "Speaker", Rect2(230, 520, 720, 30), "SAM  ·  LAB TECHNICIAN", 15, CREAM)
	intro_message = _add_label(intro_layer, "Message", Rect2(230, 552, 900, 72), "", 16, CREAM, true)
	var continue_button := _add_button(intro_layer, "Continue", Rect2(980, 604, 196, 38), "NEXT  (ENTER)", SAGE, CREAM, 13)
	continue_button.pressed.connect(_advance_sam_dialogue)

	information_layer = Control.new()
	information_layer.name = "OpportunityBrowser"
	information_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	information_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	information_layer.z_index = 30
	information_layer.visible = false
	add_child(information_layer)
	_add_rect(information_layer, "Scrim", Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.035, 0.07, 0.2, 0.78))
	_add_panel(information_layer, "BrowserCard", Rect2(80, 66, 1120, 588))
	_add_rect(information_layer, "PanelTrim", Rect2(84, 70, 1112, 10), SAGE)
	_add_label(information_layer, "Title", Rect2(120, 92, 980, 42), "OPPORTUNITY INFORMATION", 24, NAVY)
	var close_browser := _add_button(information_layer, "Close", Rect2(1126, 84, 48, 42), "X", Color("#D8D2C3"), NAVY, 15)
	close_browser.pressed.connect(_close_overlays)
	for index in 3:
		var option_button := _add_button(
			information_layer,
			"Option%d" % (index + 1),
			Rect2(120 + index * 350, 148, 330, 62),
			"FLYER %d" % (index + 1),
			Color("#F3EEDC"),
			Color("#303856"),
			15
		)
		option_button.pressed.connect(_select_category.bind(index))
	_add_panel(information_layer, "FeaturedListCard", Rect2(120, 230, 320, 382), Color("#E6E0D2"), SAGE, 2)
	category_content_scroll = ScrollContainer.new()
	category_content_scroll.name = "CategoryContentScroll"
	category_content_scroll.position = Vector2(132, 242)
	category_content_scroll.size = Vector2(296, 368)
	category_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	information_layer.add_child(category_content_scroll)
	var category_content := VBoxContainer.new()
	category_content.name = "CategoryContent"
	category_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_content.add_theme_constant_override("separation", 8)
	category_content_scroll.add_child(category_content)
	category_intro = _add_label(category_content, "CategoryIntro", Rect2(Vector2.ZERO, Vector2(276, 0)), "Choose a category above to get started.", 13, INK, true)
	category_intro.custom_minimum_size = Vector2(276, 0)
	category_intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	featured_heading = _add_label(category_content, "FeaturedHeading", Rect2(Vector2.ZERO, Vector2(276, 22)), "FEATURED", 14, NAVY)
	featured_heading.custom_minimum_size = Vector2(276, 22)
	featured_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in 3:
		var featured_button := _add_button(category_content, "Featured%d" % (index + 1), Rect2(Vector2.ZERO, Vector2(276, 48)), "FEATURED ITEM", Color("#F3EEDC"), Color("#303856"), 12)
		featured_button.custom_minimum_size = Vector2(276, 48)
		featured_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		featured_button.pressed.connect(_select_option.bind(index))
		featured_button.hide()
		featured_buttons.append(featured_button)
	category_bottom_note = _add_label(category_content, "CategoryBottomNote", Rect2(Vector2.ZERO, Vector2(276, 0)), "", 11, INK, true)
	category_bottom_note.custom_minimum_size = Vector2(276, 0)
	category_bottom_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_panel(information_layer, "EmailCard", Rect2(460, 230, 700, 382), Color("#E6E0D2"), SAGE, 2)
	current_item_title = _add_label(information_layer, "ItemTitle", Rect2(484, 250, 652, 52), "Choose a featured item", 17, NAVY, true)
	var description_scroll := ScrollContainer.new()
	description_scroll.name = "DescriptionScroll"
	description_scroll.position = Vector2(484, 306)
	description_scroll.size = Vector2(652, 234)
	description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	description_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	description_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	information_layer.add_child(description_scroll)
	current_item_description = Label.new()
	current_item_description.name = "ItemDescription"
	current_item_description.text = "Select a featured item to read its information."
	current_item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_item_description.add_theme_font_override("font", GameFont.FONT)
	current_item_description.add_theme_font_size_override("font_size", 13)
	current_item_description.add_theme_color_override("font_color", INK)
	current_item_description.custom_minimum_size = Vector2(632, 0)
	current_item_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_item_description.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	current_item_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_scroll.add_child(current_item_description)
	website_button = _add_button(information_layer, "OpenWebsite", Rect2(484, 550, 220, 42), "LEARN MORE HERE", SAGE, CREAM, 13)
	website_button.pressed.connect(_open_selected_website)
	website_status = _add_label(information_layer, "WebsiteStatus", Rect2(720, 548, 416, 48), "Choose an item to view its website link.", 12, INK, true)


func _play_entry_dialogue() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		var save_state: Dictionary = save_manager.get_save_state()
		var world_flags: Dictionary = save_state.get("world_flags", {}).duplicate(true)
		if bool(world_flags.get("community_center_intro_seen", false)):
			return
		world_flags["community_center_intro_seen"] = true
		save_state["world_flags"] = world_flags
		save_manager.set_save_state(save_state)
	modal_open = true
	sam_dialogue_lines = [
		"This is the Community Connection Center.",
		"New Jersey has over 3,200 life science companies, each of which contribute to life-saving products.",
		"Go look at the featured information at each table!",
	]
	sam_dialogue_index = 0
	intro_message.text = sam_dialogue_lines[sam_dialogue_index]
	intro_layer.show()
	_update_interaction_hint()
	_refresh_room_ui()


func _advance_sam_dialogue() -> void:
	if sam_dialogue_index + 1 < sam_dialogue_lines.size():
		sam_dialogue_index += 1
		intro_message.text = sam_dialogue_lines[sam_dialogue_index]
		var final_line := sam_dialogue_index + 1 == sam_dialogue_lines.size()
		var continue_button := intro_layer.get_node("Continue") as Button
		continue_button.text = "FINISH  (ENTER)" if final_line else "NEXT  (ENTER)"
		return
	_close_overlays()


func _open_information_screen(table: String, initial_index: int = -1) -> void:
	active_table = table
	modal_open = true
	intro_layer.hide()
	information_layer.show()
	var screen_title := "COLLEGE OPPORTUNITIES" if active_table == "college" else "COMMUNITY RESOURCES"
	(information_layer.get_node("Title") as Label).text = screen_title
	for index in 3:
		var button := information_layer.get_node("Option%d" % (index + 1)) as Button
		button.text = str(COLLEGE_CATEGORIES[index].title) if active_table == "college" else str(RESOURCE_ITEMS[index].title)
		button.disabled = false
	selected_category = -1
	selected_item = -1
	category_intro.text = "Choose a category above to view its featured programs and schools." if active_table == "college" else "Choose a resource above to see how it can help you find opportunities."
	featured_heading.visible = active_table == "college"
	category_content_scroll.scroll_vertical = 0
	for button in featured_buttons:
		button.hide()
	category_bottom_note.text = ""
	current_item_title.text = "Choose a featured item"
	current_item_description.text = "Select an item to read its description, costs, requirements, and link."
	website_button.disabled = true
	website_status.text = "Choose an item to view its website link."
	if active_table == "resources":
		category_intro.text = "Select one of the community resources above. Its description and website link will appear here."
	if initial_index >= 0:
		_select_category(initial_index)
	_update_interaction_hint()
	_refresh_room_ui()


func _select_category(index: int) -> void:
	if active_table == "resources":
		current_items = RESOURCE_ITEMS.duplicate(true)
		category_content_scroll.scroll_vertical = 0
		category_intro.text = "Select one of the community resources above. Its description and website link will appear here."
		for button in featured_buttons:
			button.hide()
		category_bottom_note.text = ""
		_select_option(index)
		return
	if index < 0 or index >= COLLEGE_CATEGORIES.size():
		return
	selected_category = index
	var category: Dictionary = COLLEGE_CATEGORIES[index]
	current_items = category["featured"].duplicate(true)
	category_intro.text = str(category.intro)
	category_bottom_note.text = str(category.bottom_note)
	featured_heading.show()
	category_content_scroll.scroll_vertical = 0
	for item_index in featured_buttons.size():
		var button := featured_buttons[item_index]
		button.visible = item_index < current_items.size()
		if button.visible:
			button.text = str(current_items[item_index].get("short_title", current_items[item_index].title))
	selected_item = -1
	current_item_title.text = "Choose a featured item"
	current_item_description.text = "Select one of the featured titles to view its description and link."
	website_button.disabled = true
	website_status.text = "Choose a featured item to view its website link."


func _select_option(index: int) -> void:
	if index < 0 or index >= current_items.size():
		return
	selected_item = index
	var item: Dictionary = current_items[index]
	current_item_title.text = str(item.title)
	current_item_description.text = str(item.description)
	var website_url := str(item.url)
	website_button.disabled = not (website_url.begins_with("https://") or website_url.begins_with("http://"))
	website_status.text = "Click LEARN MORE HERE to open this website." if not website_button.disabled else "A website link will be added for this resource."


func _open_selected_website() -> void:
	if selected_item < 0 or selected_item >= current_items.size():
		return
	var website_url := str(current_items[selected_item].url)
	if website_url.begins_with("https://") or website_url.begins_with("http://"):
		OS.shell_open(website_url)


func _close_overlays() -> void:
	modal_open = false
	intro_layer.hide()
	information_layer.hide()
	_update_interaction_hint()
	_refresh_room_ui()


func _update_interaction_hint() -> void:
	if modal_open:
		interact_hint = ""
	elif _is_near_exit():
		interact_hint = "E  Exit to hallway"
	elif _is_near_access_point("CollegeProgramsAccessPoint"):
		interact_hint = "E  View Programs & Internships"
	elif _is_near_access_point("CollegeCommunityCollegesAccessPoint"):
		interact_hint = "E  View Community Colleges"
	elif _is_near_access_point("CollegeResearchUniversitiesAccessPoint"):
		interact_hint = "E  View Research Universities"
	elif _is_near_access_point("ResourcesBioNJAccessPoint"):
		interact_hint = "E  View BioNJ"
	elif _is_near_access_point("ResourcesResearchNJAccessPoint"):
		interact_hint = "E  View Research With NJ"
	elif _is_near_access_point("ResourcesMoreAccessPoint"):
		interact_hint = "E  View More Resources"
	elif _is_near_table("CollegeTableAccessPoint"):
		interact_hint = "E  View college opportunities"
	elif _is_near_table("ResourcesTableAccessPoint"):
		interact_hint = "E  Browse community resources"
	else:
		interact_hint = "WASD / arrows  Move     E  Use a table     ESC  Leave room"


func _refresh_room_ui() -> void:
	var footer := get_node("UI/Footer/Prompt") as Label
	footer.text = interact_hint


func _is_near_table(point_name: String) -> bool:
	var access_point := get_node(point_name) as Marker2D
	return player.position.distance_to(access_point.position) < 104.0


func _is_near_access_point(point_name: String) -> bool:
	var access_point := get_node(point_name) as Marker2D
	return player.position.distance_to(access_point.position) < 76.0


func _is_near_exit() -> bool:
	var exit_point := get_node("ExitAccessPoint") as Marker2D
	return player.position.distance_to(exit_point.position) < 82.0


func _try_exit_room() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_map.tscn")


func _is_walkable(at: Vector2) -> bool:
	if at.x < 64.0 or at.x > 1216.0 or at.y < 144.0 or at.y > 646.0:
		return false
	var player_feet := Rect2(at - Vector2(PLAYER_RADIUS, PLAYER_RADIUS), Vector2(PLAYER_RADIUS * 2.0, PLAYER_RADIUS * 2.0))
	for obstacle in room_objects:
		if player_feet.intersects(obstacle):
			return false
	return true


func _player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_player_strip(frames, "front", 0)
	_add_player_strip(frames, "side_right", 4)
	_add_player_strip(frames, "side_left", 8)
	_add_player_strip(frames, "back", 12)
	return frames


func _add_player_strip(frames: SpriteFrames, animation_name: String, start_frame: int) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 8.0)
	var sheet := load(PLAYER_SHEET) as Texture2D
	for frame_index in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2((start_frame + frame_index) * 306.0, 0), Vector2(306, 646))
		frames.add_frame(animation_name, atlas)


func _style_room_labels() -> void:
	for label in find_children("*", "Label", true, false):
		(label as Label).add_theme_font_override("font", GameFont.FONT)


func _add_sam_portrait(parent: Control, area: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(SAM_SHEET) as Texture2D
	atlas.region = Rect2(430, 285, 350, 700)
	var portrait := TextureRect.new()
	portrait.name = "SamPortrait"
	portrait.position = area.position
	portrait.size = area.size
	portrait.texture = atlas
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(portrait)


func _add_rect(parent: Control, node_name: String, area: Rect2, fill: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = area.position
	rect.size = area.size
	rect.color = fill
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _add_panel(parent: Control, node_name: String, area: Rect2, fill: Color = CREAM, border: Color = NAVY, border_width: int = 4) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = area.position
	panel.size = area.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _add_label(parent: Control, node_name: String, area: Rect2, text: String, font_size: int, color: Color, wrap: bool = false, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = area.position
	label.size = area.size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("font", GameFont.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _add_button(parent: Control, node_name: String, area: Rect2, text: String, fill: Color, text_color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = area.position
	button.size = area.size
	button.text = text
	button.add_theme_font_override("font", GameFont.FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _button_style(fill, NAVY))
	button.add_theme_stylebox_override("hover", _button_style(fill.lightened(0.08), NAVY))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.06), NAVY))
	button.add_theme_stylebox_override("focus", _button_style(fill, NAVY))
	parent.add_child(button)
	return button


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style

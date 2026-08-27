extends Control

const CharacterCreation = preload("res://features/character/character_creation.gd")
var logic: Node

# UI Refs
@onready var lbl_rolls = %LblRolls
@onready var btn_roll_all = %BtnRollAll
@onready var btn_roll_physique = %BtnRollPhysique
@onready var btn_roll_spiritual = %BtnRollSpiritual
@onready var btn_roll_soul = %BtnRollSoul
@onready var btn_roll_fortune = %BtnRollFortune
@onready var btn_roll_aptitude = %BtnRollAptitude
@onready var btn_roll_mystery = %BtnRollMystery
@onready var btn_roll_traits = %BtnRollTraits
@onready var btn_start = %BtnStart

# Individual Stat Labels
@onready var lbl_physique = get_node_or_null("%LblPhysique")
@onready var lbl_spiritual = get_node_or_null("%LblSpiritual")
@onready var lbl_soul = get_node_or_null("%LblSoul")
@onready var lbl_fortune = get_node_or_null("%LblFortune")
@onready var lbl_aptitude = get_node_or_null("%LblAptitude")
@onready var lbl_mystery = get_node_or_null("%LblMystery")

@onready var lbl_stats = get_node_or_null("%LblStats")
@onready var lbl_traits = get_node_or_null("%LblTraits")
@onready var lbl_background = get_node_or_null("%LblBackgroundInfo")

# Container for interactive trait items
var traits_container: VBoxContainer

# Semi-transparent popup modal for displaying trait details
var trait_popup: Control
var popup_panel: PanelContainer
var popup_title_lbl: Label
var popup_rarity_lbl: Label
var popup_desc_lbl: RichTextLabel
var popup_mods_lbl: RichTextLabel

# Mobile touch & press-and-hold tracking for traits
var active_press_trait: TraitData = null
var is_holding: bool = false
var hold_timer: Timer
var press_start_position: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 14.0 # Cancel long-press if finger drags to scroll

# Floating stat description tooltip
var stat_tooltip: Control
var popup_panel_stat: PanelContainer
var stat_title_lbl: Label
var stat_desc_lbl: RichTextLabel

# Stat touch tracking
var active_stat_key: String = ""
var is_holding_stat: bool = false
var stat_touch_start_pos: Vector2 = Vector2.ZERO

const STAT_DESCRIPTIONS: Dictionary = {
	"physique": {
		"title": "Thể Phách",
		"desc": "Tăng Máu (HP), Sức tấn công vật lý và Giáp vật lý. Tăng tốc độ tôi luyện thân thể.",
		"border_color": Color(1.0, 0.3, 0.3, 0.95), # Red border
		"title_color": Color(1.0, 0.6, 0.6)
	},
	"spiritual_power": {
		"title": "Linh Lực",
		"desc": "Tăng Năng lượng (MP), Sức tấn công phép và Kháng phép. Tăng tốc độ học linh thuật, luyện đan.",
		"border_color": Color(0.2, 0.65, 1.0, 0.95), # Ocean Blue border
		"title_color": Color(0.5, 0.85, 1.0)
	},
	"soul_power": {
		"title": "Hồn Lực",
		"desc": "Tăng khả năng chống lại ảo thuật và khống chế tâm trí, tăng tốc độ ngộ đạo về hồn phách.",
		"border_color": Color(0.88, 0.9, 0.94, 0.95), # White/Silver border
		"title_color": Color(0.95, 0.95, 0.98)
	},
	"fortune": {
		"title": "Khí Vận",
		"desc": "Tăng tỉ lệ thành công cho các sự kiện ngẫu nhiên và ảnh hưởng trực tiếp tới Gia Cảnh khi nhập thế.",
		"border_color": Color(0.3, 0.9, 0.4, 0.95), # Green border
		"title_color": Color(0.5, 1.0, 0.6)
	},
	"aptitude": {
		"title": "Tư Chất",
		"desc": "Tăng khả năng học tập, tốc độ linh khí quy tụ và hiệu quả kỹ năng.",
		"border_color": Color(1.0, 0.7, 0.15, 0.95), # Orange-Yellow Gold border
		"title_color": Color(1.0, 0.82, 0.3)
	},
	"mystery_stat": {
		"title": "???",
		"desc": "Chỉ số ẩn đầy bí ẩn, tác động đến các thiên cơ và nhân duyên chưa biết.",
		"border_color": Color(0.1, 0.1, 0.12, 0.95), # Black border
		"title_color": Color(0.75, 0.75, 0.8)
	}
}

func _ready() -> void:
	ButtonEffects.setup_all_buttons(self)
	logic = CharacterCreation.new()
	add_child(logic)
	
	_setup_hold_timer()
	_setup_trait_ui_nodes()
	_setup_stat_tooltip_node()
	_setup_stat_input_bindings()
	
	logic.stats_rolled.connect(_update_ui)
	logic.traits_rolled.connect(_update_ui)
	logic.creation_finished.connect(_on_creation_finished)
	
	# Connect buttons
	btn_roll_all.pressed.connect(func(): logic.roll_all_stats())
	btn_roll_physique.pressed.connect(func(): logic.roll_single_stat("physique"))
	btn_roll_spiritual.pressed.connect(func(): logic.roll_single_stat("spiritual_power"))
	btn_roll_soul.pressed.connect(func(): logic.roll_single_stat("soul_power"))
	btn_roll_fortune.pressed.connect(func(): logic.roll_single_stat("fortune"))
	btn_roll_aptitude.pressed.connect(func(): logic.roll_single_stat("aptitude"))
	btn_roll_mystery.pressed.connect(func(): logic.roll_single_stat("mystery_stat"))
	btn_roll_traits.pressed.connect(func(): logic.roll_traits_only())
	
	btn_start.pressed.connect(func(): logic.apply_and_start_game())
	
	_update_ui()

func _setup_hold_timer() -> void:
	hold_timer = Timer.new()
	hold_timer.one_shot = true
	hold_timer.wait_time = 0.25 # 250ms mobile long press threshold
	hold_timer.timeout.connect(_on_hold_timer_timeout)
	add_child(hold_timer)

func _setup_trait_ui_nodes() -> void:
	# Hide default raw text in lbl_traits and set as section header
	if lbl_traits:
		lbl_traits.text = "--- MỆNH CÁCH ---"
		lbl_traits.offset_bottom = lbl_traits.offset_top + 30
		
	# Create traits_container for mobile thumb-friendly trait item rows
	traits_container = VBoxContainer.new()
	traits_container.name = "TraitsContainer"
	traits_container.layout_mode = 0
	traits_container.offset_left = 97.0
	traits_container.offset_top = 505.0
	traits_container.offset_right = 589.0
	traits_container.offset_bottom = 950.0
	traits_container.add_theme_constant_override("separation", 10)
	add_child(traits_container)
	
	# Create mobile modal popup overlay
	trait_popup = Control.new()
	trait_popup.name = "TraitPopup"
	trait_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	trait_popup.visible = false
	trait_popup.z_index = 100
	
	# Dimmed background layer - Tapping anywhere closes popup on mobile
	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_dim.color = Color(0, 0, 0, 0.65)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_dim.gui_input.connect(_on_popup_bg_gui_input)
	trait_popup.add_child(bg_dim)
	
	# Popup Panel Container (Center semi-transparent card - enlarged for easy reading)
	popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(540, 320)
	popup_panel.layout_mode = 1
	popup_panel.anchors_preset = 8 # Center
	popup_panel.anchor_left = 0.5
	popup_panel.anchor_top = 0.5
	popup_panel.anchor_right = 0.5
	popup_panel.anchor_bottom = 0.5
	popup_panel.offset_left = -270
	popup_panel.offset_top = -160
	popup_panel.offset_right = 270
	popup_panel.offset_bottom = 160
	
	# StyleBox for glassmorphism / dark semi-transparent style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.12, 0.94)
	style_box.border_color = Color(0.8, 0.7, 0.4, 0.85) # Gold border
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(14)
	style_box.set_content_margin_all(20)
	style_box.shadow_color = Color(0, 0, 0, 0.6)
	style_box.shadow_size = 14
	popup_panel.add_theme_stylebox_override("panel", style_box)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 12)
	popup_panel.add_child(content_vbox)
	
	popup_title_lbl = Label.new()
	popup_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title_lbl.clip_contents = false
	popup_title_lbl.add_theme_font_size_override("font_size", 28)
	popup_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	content_vbox.add_child(popup_title_lbl)
	
	popup_rarity_lbl = Label.new()
	popup_rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_rarity_lbl.clip_contents = false
	popup_rarity_lbl.add_theme_font_size_override("font_size", 20)
	content_vbox.add_child(popup_rarity_lbl)
	
	var hs = HSeparator.new()
	content_vbox.add_child(hs)
	
	popup_desc_lbl = RichTextLabel.new()
	popup_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_desc_lbl.bbcode_enabled = true
	popup_desc_lbl.fit_content = true
	popup_desc_lbl.scroll_active = false
	popup_desc_lbl.clip_contents = false
	popup_desc_lbl.add_theme_font_size_override("normal_font_size", 20)
	popup_desc_lbl.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0))
	content_vbox.add_child(popup_desc_lbl)
	
	popup_mods_lbl = RichTextLabel.new()
	popup_mods_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_mods_lbl.bbcode_enabled = true
	popup_mods_lbl.fit_content = true
	popup_mods_lbl.scroll_active = false
	popup_mods_lbl.clip_contents = false
	popup_mods_lbl.add_theme_font_size_override("normal_font_size", 18)
	content_vbox.add_child(popup_mods_lbl)
	
	var hint_lbl = Label.new()
	hint_lbl.text = "(Chạm bất kỳ đâu để đóng)"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	content_vbox.add_child(hint_lbl)
	
	trait_popup.add_child(popup_panel)
	add_child(trait_popup)

func _setup_stat_tooltip_node() -> void:
	stat_tooltip = Control.new()
	stat_tooltip.name = "StatTooltip"
	stat_tooltip.visible = false
	stat_tooltip.z_index = 105
	
	popup_panel_stat = PanelContainer.new()
	popup_panel_stat.custom_minimum_size = Vector2(480, 0) # Significantly enlarged width for mobile
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	stat_title_lbl = Label.new()
	stat_title_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(stat_title_lbl)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	stat_desc_lbl = RichTextLabel.new()
	stat_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat_desc_lbl.bbcode_enabled = true
	stat_desc_lbl.fit_content = true
	stat_desc_lbl.scroll_active = false
	stat_desc_lbl.add_theme_font_size_override("normal_font_size", 20)
	stat_desc_lbl.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(stat_desc_lbl)
	
	popup_panel_stat.add_child(vbox)
	stat_tooltip.add_child(popup_panel_stat)
	add_child(stat_tooltip)

func _setup_stat_input_bindings() -> void:
	var stat_nodes = {
		"physique": lbl_physique,
		"spiritual_power": lbl_spiritual,
		"soul_power": lbl_soul,
		"fortune": lbl_fortune,
		"aptitude": lbl_aptitude,
		"mystery_stat": lbl_mystery
	}
	
	for stat_key in stat_nodes.keys():
		var node = stat_nodes[stat_key]
		if node != null:
			node.mouse_filter = Control.MOUSE_FILTER_STOP
			node.clip_contents = false # Prevent diacritics clipping on stat labels
			node.gui_input.connect(_on_stat_gui_input.bind(stat_key))

func _on_stat_gui_input(event: InputEvent, stat_key: String) -> void:
	var global_pos: Vector2 = get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_stat_touch_down(global_pos, stat_key)
			else:
				_on_stat_touch_up()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_stat_touch_down(global_pos, stat_key)
		else:
			_on_stat_touch_up()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_holding_stat and global_pos.distance_to(stat_touch_start_pos) > DRAG_THRESHOLD:
			_cancel_stat_holding()

func _on_stat_touch_down(global_pos: Vector2, stat_key: String) -> void:
	active_stat_key = stat_key
	stat_touch_start_pos = global_pos
	is_holding_stat = true
	_show_stat_tooltip(stat_key, global_pos)

func _on_stat_touch_up() -> void:
	is_holding_stat = false
	active_stat_key = ""
	_hide_stat_tooltip()

func _cancel_stat_holding() -> void:
	is_holding_stat = false
	active_stat_key = ""
	_hide_stat_tooltip()

func _show_stat_tooltip(stat_key: String, global_pos: Vector2) -> void:
	if not STAT_DESCRIPTIONS.has(stat_key) or stat_tooltip == null:
		return
		
	var info: Dictionary = STAT_DESCRIPTIONS[stat_key]
	stat_title_lbl.text = info["title"]
	stat_title_lbl.add_theme_color_override("font_color", info["title_color"])
	
	stat_desc_lbl.text = info["desc"]
	
	# Apply per-stat custom border color stylebox
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.06, 0.08, 0.12, 0.95) # Original dark glass background
	style_box.border_color = info["border_color"]
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(14)
	style_box.set_content_margin_all(18)
	style_box.shadow_color = Color(0, 0, 0, 0.6)
	style_box.shadow_size = 12
	popup_panel_stat.add_theme_stylebox_override("panel", style_box)
	
	stat_tooltip.visible = true
	
	# Position near touch point (above finger)
	var popup_size = popup_panel_stat.get_combined_minimum_size()
	var target_x = clampf(global_pos.x - (popup_size.x / 2.0), 15.0, 720.0 - popup_size.x - 15.0)
	var target_y = global_pos.y - popup_size.y - 25.0
	
	if target_y < 20.0:
		target_y = global_pos.y + 40.0
		
	stat_tooltip.global_position = Vector2(target_x, target_y)

func _hide_stat_tooltip() -> void:
	if stat_tooltip != null:
		stat_tooltip.visible = false

func _format_stat_bbcode(stat_title: String, base_val: int, mod_val: int) -> String:
	if mod_val > 0:
		return "%s: %d [color=#00cc44](+%d)[/color]" % [stat_title, base_val, mod_val]
	elif mod_val < 0:
		return "%s: %d [color=#ee3333](%d)[/color]" % [stat_title, base_val, mod_val]
	else:
		return "%s: %d" % [stat_title, base_val]

func _update_ui() -> void:
	if lbl_rolls:
		lbl_rolls.text = "Free Rolls: %d | Ad Rolls: %d" % [logic.free_rolls, logic.ad_rolls]
	
	var s = logic.current_stats
	
	# Calculate stat modifiers from traits
	var mods = {
		"physique": 0,
		"spiritual_power": 0,
		"soul_power": 0,
		"fortune": 0,
		"aptitude": 0,
		"mystery_stat": 0
	}
	for t in logic.current_traits:
		if t != null:
			mods["physique"] += t.physique_mod
			mods["spiritual_power"] += t.spiritual_power_mod
			mods["soul_power"] += t.soul_power_mod
			mods["fortune"] += t.fortune_mod
			mods["aptitude"] += t.aptitude_mod
			mods["mystery_stat"] += t.mystery_stat_mod

	if lbl_physique:
		lbl_physique.text = _format_stat_bbcode("Thể phách", s["physique"], mods["physique"])
	if lbl_spiritual:
		lbl_spiritual.text = _format_stat_bbcode("Linh lực", s["spiritual_power"], mods["spiritual_power"])
	if lbl_soul:
		lbl_soul.text = _format_stat_bbcode("Hồn lực", s["soul_power"], mods["soul_power"])
	if lbl_fortune:
		lbl_fortune.text = _format_stat_bbcode("Khí vận", s["fortune"], mods["fortune"])
	if lbl_aptitude:
		lbl_aptitude.text = _format_stat_bbcode("Tư chất", s["aptitude"], mods["aptitude"])
	if lbl_mystery:
		lbl_mystery.text = _format_stat_bbcode("???", s["mystery_stat"], mods["mystery_stat"])
		
	if lbl_stats:
		lbl_stats.text = "--- CHỈ SỐ ---\n"
		lbl_stats.text += _format_stat_bbcode("Thể phách", s["physique"], mods["physique"]) + "\n"
		lbl_stats.text += _format_stat_bbcode("Linh lực", s["spiritual_power"], mods["spiritual_power"]) + "\n"
		lbl_stats.text += _format_stat_bbcode("Hồn lực", s["soul_power"], mods["soul_power"]) + "\n"
		lbl_stats.text += _format_stat_bbcode("Khí vận", s["fortune"], mods["fortune"]) + "\n"
		lbl_stats.text += _format_stat_bbcode("Tư chất", s["aptitude"], mods["aptitude"]) + "\n"
		lbl_stats.text += _format_stat_bbcode("???", s["mystery_stat"], mods["mystery_stat"]) + "\n"

	_render_trait_items()
				
	if lbl_background:
		var effective_fortune = s["fortune"] + mods["fortune"]
		var fortune_bonus = (effective_fortune - 5) * 2
		var sign_str = "+" if fortune_bonus >= 0 else ""
		lbl_background.text = "\n--- GIA CẢNH ---\n?? (Khí vận đang tác động: %s%d%%)\n(Sẽ đổ khi vào game)" % [sign_str, fortune_bonus]

func _render_trait_items() -> void:
	if not traits_container:
		return
		
	# Clear existing trait item nodes
	for child in traits_container.get_children():
		child.queue_free()
		
	for trait_data in logic.current_traits:
		var item_panel = PanelContainer.new()
		item_panel.custom_minimum_size = Vector2(0, 64) # Extra large touch target row for mobile
		
		# Semi-transparent dark background card for each trait row
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.18, 0.85) if not trait_data.is_hidden else Color(0.08, 0.22, 0.32, 0.85)
		style.border_color = Color(0.4, 0.4, 0.5, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.set_content_margin_all(12)
		item_panel.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.clip_contents = false
		if trait_data.is_hidden:
			lbl.text = "🔒 [MỆNH CÁCH ẨN] %s" % trait_data.trait_name
			lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		else:
			lbl.text = "✦ %s" % trait_data.trait_name
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			
		lbl.add_theme_font_size_override("font_size", 21)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_panel.add_child(lbl)
		
		# Enable input capture for touch & long-press on mobile
		item_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		item_panel.gui_input.connect(_on_trait_item_gui_input.bind(trait_data))
		
		traits_container.add_child(item_panel)

func _on_trait_item_gui_input(event: InputEvent, trait_data: TraitData) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_touch_down(event.position, trait_data)
			else:
				_on_touch_up()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event.position, trait_data)
		else:
			_on_touch_up()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_holding and event.position.distance_to(press_start_position) > DRAG_THRESHOLD:
			_cancel_holding()

func _on_touch_down(pos: Vector2, trait_data: TraitData) -> void:
	active_press_trait = trait_data
	press_start_position = pos
	is_holding = true
	# Start hold timer on touch down; do NOT pop up instantly so scrolling is smooth
	hold_timer.start()

func _on_touch_up() -> void:
	if is_holding:
		if not trait_popup.visible and active_press_trait != null:
			_show_trait_popup(active_press_trait)
			
		is_holding = false
		hold_timer.stop()

func _cancel_holding() -> void:
	is_holding = false
	active_press_trait = null
	hold_timer.stop()

func _on_hold_timer_timeout() -> void:
	if is_holding and active_press_trait != null:
		_show_trait_popup(active_press_trait)

func _on_popup_bg_gui_input(event: InputEvent) -> void:
	# Tap anywhere on dimmed overlay to dismiss popup on mobile
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_hide_trait_popup()

func _show_trait_popup(trait_data: TraitData) -> void:
	if trait_data == null or trait_popup == null:
		return
		
	popup_title_lbl.text = trait_data.trait_name
	
	# Rarity text & color
	var rarity_info = _get_rarity_info(trait_data.rarity)
	popup_rarity_lbl.text = "Độ hiếm: " + rarity_info["name"]
	popup_rarity_lbl.add_theme_color_override("font_color", rarity_info["color"])
	
	popup_desc_lbl.text = trait_data.description
	
	# Format stat modifiers with green (+) for buffs and red (-) for debuffs
	var mod_strings: Array[String] = []
	if trait_data.physique_mod > 0:
		mod_strings.append("[color=#00cc44]+%d Thể phách[/color]" % trait_data.physique_mod)
	elif trait_data.physique_mod < 0:
		mod_strings.append("[color=#ee3333]%d Thể phách[/color]" % trait_data.physique_mod)
		
	if trait_data.spiritual_power_mod > 0:
		mod_strings.append("[color=#00cc44]+%d Linh lực[/color]" % trait_data.spiritual_power_mod)
	elif trait_data.spiritual_power_mod < 0:
		mod_strings.append("[color=#ee3333]%d Linh lực[/color]" % trait_data.spiritual_power_mod)
		
	if trait_data.soul_power_mod > 0:
		mod_strings.append("[color=#00cc44]+%d Hồn lực[/color]" % trait_data.soul_power_mod)
	elif trait_data.soul_power_mod < 0:
		mod_strings.append("[color=#ee3333]%d Hồn lực[/color]" % trait_data.soul_power_mod)
		
	if trait_data.fortune_mod > 0:
		mod_strings.append("[color=#00cc44]+%d Khí vận[/color]" % trait_data.fortune_mod)
	elif trait_data.fortune_mod < 0:
		mod_strings.append("[color=#ee3333]%d Khí vận[/color]" % trait_data.fortune_mod)
		
	if trait_data.aptitude_mod > 0:
		mod_strings.append("[color=#00cc44]+%d Tư chất[/color]" % trait_data.aptitude_mod)
	elif trait_data.aptitude_mod < 0:
		mod_strings.append("[color=#ee3333]%d Tư chất[/color]" % trait_data.aptitude_mod)
		
	if trait_data.mystery_stat_mod > 0:
		mod_strings.append("[color=#00cc44]+%d ???[/color]" % trait_data.mystery_stat_mod)
	elif trait_data.mystery_stat_mod < 0:
		mod_strings.append("[color=#ee3333]%d ???[/color]" % trait_data.mystery_stat_mod)
		
	if not mod_strings.is_empty():
		popup_mods_lbl.text = "Tác động chỉ số: " + ", ".join(mod_strings)
		popup_mods_lbl.visible = true
	else:
		popup_mods_lbl.visible = false
		
	trait_popup.visible = true

func _hide_trait_popup() -> void:
	if trait_popup != null:
		trait_popup.visible = false

func _get_rarity_info(rarity: TraitData.Rarity) -> Dictionary:
	match rarity:
		TraitData.Rarity.TRASH:
			return {"name": "Phế Phẩm", "color": Color(0.6, 0.6, 0.6)}
		TraitData.Rarity.MORTAL:
			return {"name": "Phàm Phẩm", "color": Color(0.9, 0.9, 0.9)}
		TraitData.Rarity.SPIRIT:
			return {"name": "Linh Phẩm", "color": Color(0.2, 0.9, 0.3)}
		TraitData.Rarity.EARTH:
			return {"name": "Địa Phẩm", "color": Color(0.2, 0.6, 1.0)}
		TraitData.Rarity.HEAVEN:
			return {"name": "Thiên Phẩm", "color": Color(0.7, 0.3, 1.0)}
		TraitData.Rarity.IMMORTAL:
			return {"name": "Tiên Phẩm", "color": Color(1.0, 0.6, 0.1)}
		TraitData.Rarity.DIVINE:
			return {"name": "Thần Phẩm", "color": Color(1.0, 0.84, 0.0)}
		TraitData.Rarity.SUPREME:
			return {"name": "Vô Thượng", "color": Color(1.0, 0.2, 0.4)}
		TraitData.Rarity.HIDDEN:
			return {"name": "Mệnh Cách Ẩn", "color": Color(0.0, 0.9, 1.0)}
		_:
			return {"name": "Không rõ", "color": Color(1.0, 1.0, 1.0)}

func _on_creation_finished() -> void:
	var player = GameManager.player_stats
	if lbl_background:
		lbl_background.text = "\n--- GIA CẢNH ---\n[%d] %s" % [player.background_rarity, player.background_name]
	
	btn_roll_all.disabled = true
	btn_roll_physique.disabled = true
	btn_roll_spiritual.disabled = true
	btn_roll_soul.disabled = true
	btn_roll_fortune.disabled = true
	btn_roll_aptitude.disabled = true
	btn_roll_mystery.disabled = true
	btn_roll_traits.disabled = true
	btn_start.disabled = true
	
	print("Character creation complete. Awaiting gameplay scene.")

extends Control

@onready var slot1_btn = $VBoxContainer/Slot1Btn
@onready var slot1_lbl = $VBoxContainer/Slot1Btn/VBoxContainer/Label
@onready var slot1_del = $VBoxContainer/Slot1Btn/DeleteBtn

@onready var slot2_btn = $VBoxContainer/Slot2Btn
@onready var slot2_lbl = $VBoxContainer/Slot2Btn/VBoxContainer/Label
@onready var slot2_icon = $VBoxContainer/Slot2Btn/LockIcon
@onready var slot2_del = $VBoxContainer/Slot2Btn/DeleteBtn

@onready var toast_lbl = $ToastLabel

@onready var create_popup = $CreatePopup
@onready var name_input = $CreatePopup/Panel/VBoxContainer/NameInput
@onready var error_lbl = $CreatePopup/Panel/VBoxContainer/ErrorLabel
@onready var male_btn = $CreatePopup/Panel/VBoxContainer/GenderContainer/MaleBtn
@onready var female_btn = $CreatePopup/Panel/VBoxContainer/GenderContainer/FemaleBtn

var selected_gender: int = 0 # 0 = Nam, 1 = Nữ

func _ready() -> void:
	if has_node("/root/ButtonEffects"):
		get_node("/root/ButtonEffects").setup_all_buttons(self)
		
	toast_lbl.modulate.a = 0
	create_popup.visible = false
	_refresh_slots()

func _refresh_slots() -> void:
	# Slot 1
	var has_s1 = SaveSystem.has_save(1)
	if has_s1:
		var info = SaveSystem.get_save_info(1)
		var bg_str = info.get("background_name", "Bình Phàm")
		slot1_lbl.text = "Luân Hồi 1\n[ %s ] - Cảnh giới %d" % [bg_str.strip_edges(), info.get("realm_level", 0)]
		slot1_del.visible = true
	else:
		slot1_lbl.text = "Luân Hồi 1\n[ Tạo Mới ]"
		slot1_del.visible = false

	# Slot 2
	var has_s2 = SaveSystem.has_save(2)
	if GameManager.is_second_slot_unlocked:
		slot2_btn.modulate = Color(1, 1, 1, 1)
		slot2_icon.visible = false
		if has_s2:
			var info = SaveSystem.get_save_info(2)
			var bg_str = info.get("background_name", "Bình Phàm")
			slot2_lbl.text = "Luân Hồi 2\n[ %s ] - Cảnh giới %d" % [bg_str.strip_edges(), info.get("realm_level", 0)]
			slot2_del.visible = true
		else:
			slot2_lbl.text = "Luân Hồi 2\n[ Tạo Mới ]"
			slot2_del.visible = false
	else:
		slot2_btn.modulate = Color(0.5, 0.5, 0.5, 1)
		slot2_icon.visible = true
		slot2_lbl.text = "Luân Hồi 2\n[ Đã Khóa ]"
		slot2_del.visible = false

func _on_slot1_pressed() -> void:
	SaveSystem.current_slot = 1
	if SaveSystem.has_save(1):
		_load_and_play()
	else:
		_show_create_popup()

func _on_slot1_delete_pressed() -> void:
	SaveSystem.delete_save(1)
	_refresh_slots()

func _on_slot2_pressed() -> void:
	if not GameManager.is_second_slot_unlocked:
		_show_toast("Cần hoàn thành cơ duyên ẩn để mở khóa slot này.")
		return
		
	SaveSystem.current_slot = 2
	if SaveSystem.has_save(2):
		_load_and_play()
	else:
		_show_create_popup()

func _on_slot2_delete_pressed() -> void:
	SaveSystem.delete_save(2)
	_refresh_slots()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://features/main_menu/main_menu.tscn")

func _load_and_play() -> void:
	var stats = SaveSystem.load_game()
	if stats:
		GameManager.player_stats = stats
		get_tree().change_scene_to_file("res://features/gameplay/placeholder_gameplay.tscn")
	else:
		_show_toast("Lỗi tải save!")

func _show_create_popup() -> void:
	name_input.text = ""
	error_lbl.visible = false
	_select_gender(0) # Default Male
	create_popup.visible = true

func _on_male_btn_pressed() -> void:
	_select_gender(0)

func _on_female_btn_pressed() -> void:
	_select_gender(1)

func _select_gender(g: int) -> void:
	selected_gender = g
	male_btn.button_pressed = (g == 0)
	female_btn.button_pressed = (g == 1)

func _on_popup_cancel_pressed() -> void:
	create_popup.visible = false

func _on_popup_confirm_pressed() -> void:
	var c_name = name_input.text.strip_edges()
	
	if c_name.is_empty():
		error_lbl.text = "Vui lòng nhập tên nhân vật!"
		error_lbl.visible = true
		return
		
	if not _is_valid_name(c_name):
		error_lbl.text = "Tên không được chứa ký tự đặc biệt!"
		error_lbl.visible = true
		return
		
	error_lbl.visible = false
	GameManager.pending_char_name = c_name
	GameManager.pending_char_gender = selected_gender
	create_popup.visible = false
	get_tree().change_scene_to_file("res://features/character/character_creation_ui.tscn")

func _is_valid_name(text: String) -> bool:
	var regex = RegEx.new()
	# Unicode letters, digits, and spaces only
	regex.compile("^[\\p{L}\\p{N} ]+$")
	var result = regex.search(text)
	return result != null

func _show_toast(msg: String) -> void:
	toast_lbl.text = msg
	var tw = create_tween()
	tw.tween_property(toast_lbl, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(toast_lbl, "modulate:a", 0.0, 0.5)

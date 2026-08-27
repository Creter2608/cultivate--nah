extends Control

func _ready() -> void:
	# Refresh UI just in case
	var player = GameManager.player_stats
	if player:
		$VBoxContainer/LabelStats.text = "Gia cảnh: %s\nTu vi: Cảnh giới %d" % [player.background_name, player.realm_level]
	else:
		$VBoxContainer/LabelStats.text = "Lỗi: Không tìm thấy dữ liệu nhân vật!"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://features/main_menu/main_menu.tscn")

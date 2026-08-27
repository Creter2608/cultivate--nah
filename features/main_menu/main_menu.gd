extends Control

func _ready() -> void:
	ButtonEffects.setup_all_buttons(self)

func _on_start_button_pressed() -> void:
	print("Start Game Pressed")
	await get_tree().create_timer(0.15).timeout
	# Chuyển sang màn hình chọn slot thay vì tạo nhân vật
	get_tree().change_scene_to_file("res://features/save_slots/save_slots_ui.tscn")

func _on_shop_button_pressed() -> void:
	print("Shop Pressed - Coming soon")

func _on_settings_button_pressed() -> void:
	print("Settings Pressed - Coming soon")

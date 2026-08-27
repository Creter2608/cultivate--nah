extends Node

signal player_stats_changed

var player_stats: CharacterStats = null
var unlocked_heavenly_fragments: Array[int] = []
var is_second_slot_unlocked: bool = false

var pending_char_name: String = "Vô Danh"
var pending_char_gender: int = 0

func _ready() -> void:
	# Load global data (unlockables, metadata) on startup
	SaveSystem.load_global_data()
	# Note: We do NOT load player_stats here anymore.
	# The player will explicitly load a save via slot selection.

func start_new_game(char_name: String = "Vô Danh", char_gender: int = 0) -> void:
	player_stats = CharacterStats.new()
	player_stats.character_name = char_name
	player_stats.gender = char_gender as CharacterStats.Gender
	
	# Mortal lifespan randomization (60 - 100 years)
	if player_stats.realm_level == 0:
		player_stats.lifespan = randi_range(60, 100)
		
	# Calculate starting stats (HP, MP...)
	player_stats.calculate_derived_stats()
	
	# Ensure max_hp/max_mp at the start
	player_stats.current_hp = player_stats.max_hp
	player_stats.current_mp = player_stats.max_mp
	
	player_stats_changed.emit()
	print("New game initialized. Lifespan set to: ", player_stats.lifespan)

func save_current_game() -> void:
	if player_stats:
		SaveSystem.save_game(player_stats)

func has_heavenly_fragment(id: int) -> bool:
	return unlocked_heavenly_fragments.has(id)

func unlock_heavenly_fragment(id: int) -> void:
	if not unlocked_heavenly_fragments.has(id):
		unlocked_heavenly_fragments.append(id)
		print("Heavenly Fragment #%d UNLOCKED!" % id)
		SaveSystem.save_global_data() # Update global data

func unlock_second_slot() -> void:
	if not is_second_slot_unlocked:
		is_second_slot_unlocked = true
		print("Second character slot UNLOCKED!")
		SaveSystem.save_global_data()


## Utility function to easily change scenes
func change_scene(scene_path: String) -> void:
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		printerr("Error changing to scene: ", scene_path)

## Thay đổi tần số quét (FPS) để tối ưu pin hoặc độ mượt
func set_target_fps(fps: int) -> void:
	if fps > 0:
		# Tắt VSync để ép FPS theo ý muốn
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = fps
	else:
		# Nếu fps <= 0, bật lại VSync (tuỳ thuộc vào tần số quét tối đa của máy)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0
		
	print("Đã đổi FPS mục tiêu thành: ", str(fps) if fps > 0 else "Tự động (VSync)")

extends Node

signal player_stats_changed

var player_stats: CharacterStats = null
var unlocked_heavenly_fragments: Array[int] = []

func _ready() -> void:
	# Attempt to load saved data when the game starts
	var saved_stats = SaveSystem.load_game()
	if saved_stats:
		player_stats = saved_stats
	else:
		start_new_game()

func start_new_game() -> void:
	player_stats = CharacterStats.new()
	
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
		SaveSystem.save_game(player_stats)

## Utility function to easily change scenes
func change_scene(scene_path: String) -> void:
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		printerr("Error changing to scene: ", scene_path)

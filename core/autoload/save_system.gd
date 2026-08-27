extends Node

var current_slot: int = 1
const GLOBAL_SAVE_PATH = "user://global_data.json"

func get_save_path(slot_index: int) -> String:
	return "user://savegame_%d.json" % slot_index

func save_game(stats: CharacterStats) -> void:
	var save_data: Dictionary = {
		"version": "1.0",
		"player_stats": stats.to_dict(),
		# Note: unlocked_heavenly_fragments is moved to global data, but keep it here if it's per-save.
		# But we decided to move global data to global_data.json. 
		# We'll save it in global instead.
	}
	
	if get_node_or_null("/root/InventoryManager"):
		save_data["inventory"] = get_node("/root/InventoryManager").to_dict()
	
	# If TimeManager exists, save its state as well
	if get_node_or_null("/root/TimeManager"):
		var time_manager = get_node("/root/TimeManager")
		if time_manager.has_method("to_dict"):
			save_data["time_system"] = time_manager.to_dict()
	
	var json_string = JSON.stringify(save_data, "\t") # Pretty print with tab
	var path = get_save_path(current_slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Game saved successfully to: ", path)
		# Also save global data when we save game
		save_global_data()
	else:
		printerr("Error: Could not open file to save game!")

func load_game() -> CharacterStats:
	var path = get_save_path(current_slot)
	if not FileAccess.file_exists(path):
		print("No save file found for slot ", current_slot, ". Starting a new game.")
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var save_data = json.data
			if typeof(save_data) == TYPE_DICTIONARY and save_data.has("player_stats"):
				var stats = CharacterStats.new()
				stats.from_dict(save_data["player_stats"])
				
				# Load time system if it exists in the save and the node is available
				if save_data.has("time_system") and get_node_or_null("/root/TimeManager"):
					var time_manager = get_node("/root/TimeManager")
					if time_manager.has_method("from_dict"):
						time_manager.from_dict(save_data["time_system"])
						
				if save_data.has("inventory") and get_node_or_null("/root/InventoryManager"):
					get_node("/root/InventoryManager").from_dict(save_data["inventory"])
						
				print("Game loaded successfully from slot ", current_slot)
				return stats
		else:
			printerr("JSON parse error in save file!")
	
	return null

func delete_save(slot_index: int) -> void:
	var path = get_save_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save file deleted for slot ", slot_index)

func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_index))

func get_save_info(slot_index: int) -> Dictionary:
	var path = get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var save_data = json.data
			if typeof(save_data) == TYPE_DICTIONARY and save_data.has("player_stats"):
				var stats = save_data["player_stats"]
				return {
					"background_name": stats.get("background_name", "Bình Phàm"),
					"realm_level": stats.get("realm_level", 0),
					"lifespan": stats.get("lifespan", 0)
				}
	return {}

func save_global_data() -> void:
	var global_data: Dictionary = {
		"version": "1.0",
		"unlocked_heavenly_fragments": GameManager.unlocked_heavenly_fragments,
		"is_second_slot_unlocked": GameManager.is_second_slot_unlocked
	}
	var json_string = JSON.stringify(global_data, "\t")
	var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_global_data() -> void:
	if not FileAccess.file_exists(GLOBAL_SAVE_PATH):
		# Create a default one if it doesn't exist
		save_global_data()
		return
		
	var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var global_data = json.data
			if typeof(global_data) == TYPE_DICTIONARY:
				if global_data.has("unlocked_heavenly_fragments"):
					var fragments = global_data["unlocked_heavenly_fragments"]
					var typed_array: Array[int] = []
					for f in fragments:
						typed_array.append(int(f))
					GameManager.unlocked_heavenly_fragments = typed_array
				
				if global_data.has("is_second_slot_unlocked"):
					GameManager.is_second_slot_unlocked = global_data["is_second_slot_unlocked"]

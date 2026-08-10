extends Node

const SAVE_FILE_PATH = "user://savegame.json"

func save_game(stats: CharacterStats) -> void:
	var save_data: Dictionary = {
		"version": "1.0",
		"player_stats": stats.to_dict(),
		"unlocked_heavenly_fragments": GameManager.unlocked_heavenly_fragments
	}
	
	if get_node_or_null("/root/InventoryManager"):
		save_data["inventory"] = get_node("/root/InventoryManager").to_dict()
	
	# If TimeManager exists, save its state as well
	if get_node_or_null("/root/TimeManager"):
		var time_manager = get_node("/root/TimeManager")
		if time_manager.has_method("to_dict"):
			save_data["time_system"] = time_manager.to_dict()
	
	var json_string = JSON.stringify(save_data, "\t") # Pretty print with tab
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Game saved successfully to: ", SAVE_FILE_PATH)
	else:
		printerr("Error: Could not open file to save game!")

func load_game() -> CharacterStats:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found. Starting a new game.")
		return null
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
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
						
				if save_data.has("unlocked_heavenly_fragments"):
					var fragments = save_data["unlocked_heavenly_fragments"]
					var typed_array: Array[int] = []
					for f in fragments:
						typed_array.append(int(f))
					GameManager.unlocked_heavenly_fragments = typed_array
					
				if save_data.has("inventory") and get_node_or_null("/root/InventoryManager"):
					get_node("/root/InventoryManager").from_dict(save_data["inventory"])
						
				print("Game loaded successfully!")
				return stats
		else:
			printerr("JSON parse error in save file!")
	
	return null

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save file deleted.")

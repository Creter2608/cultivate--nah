extends Node

signal stats_rolled
signal traits_rolled
signal creation_finished

var free_rolls: int = 5
var ad_rolls: int = 3
var has_infinite_rolls: bool = false
var has_gamepass: bool = false

# Current rolled stats
var current_stats: Dictionary = {
	"physique": 1,
	"spiritual_power": 1,
	"soul_power": 1,
	"fortune": 1,
	"aptitude": 1,
	"mystery_stat": 1
}

# Array of TraitData
var current_traits: Array[TraitData] = []

func _ready() -> void:
	randomize()
	_randomize_initial_state()

func _randomize_initial_state() -> void:
	for stat_name in current_stats.keys():
		current_stats[stat_name] = _roll_stat_value()
	_roll_normal_traits()
	_check_and_add_hidden_traits()

func roll_all_stats() -> void:
	if not _consume_roll():
		return
		
	# Roll stats
	for stat_name in current_stats.keys():
		current_stats[stat_name] = _roll_stat_value()
		
	# Randomize normal traits during roll all (example: 1-2 random traits)
	_roll_normal_traits()
	
	# Check for 11 and add hidden traits
	_check_and_add_hidden_traits()
	
	stats_rolled.emit()
	print("Rolled all stats: ", current_stats)

func roll_single_stat(stat_name: String) -> void:
	if not current_stats.has(stat_name):
		printerr("Invalid stat name: ", stat_name)
		return
		
	if not _consume_roll():
		return
		
	current_stats[stat_name] = _roll_stat_value()
	_check_and_add_hidden_traits()
	
	stats_rolled.emit()
	print("Rolled ", stat_name, " to ", current_stats[stat_name])

func roll_traits_only() -> void:
	if not _consume_roll():
		return
		
	_roll_normal_traits()
	_check_and_add_hidden_traits() # Re-add hidden traits just in case
	
	traits_rolled.emit()
	print("Rolled traits manually.")

func _consume_roll() -> bool:
	if has_infinite_rolls:
		return true
	
	if free_rolls > 0:
		free_rolls -= 1
		print("Used a free roll. Remaining: ", free_rolls)
		return true
	elif ad_rolls > 0:
		ad_rolls -= 1
		print("Used an ad roll. Remaining: ", ad_rolls)
		return true
	
	print("No rolls left!")
	return false

func _roll_stat_value() -> int:
	var roll = randf() * 100.0
	if roll <= 0.5: # 0.5% chance
		return 11
	return randi_range(1, 10)

func _roll_normal_traits() -> void:
	# Clear previous normal traits
	var new_traits: Array[TraitData] = []
	for trait_data in current_traits:
		if trait_data.is_hidden:
			new_traits.append(trait_data)
	current_traits = new_traits
	
	# Roll exactly 3 normal traits for the starting slots
	for i in range(3):
		var rolled_rarity = _roll_trait_rarity()
		var new_trait = _generate_mock_trait_by_rarity(rolled_rarity)
		current_traits.append(new_trait)

func _roll_trait_rarity() -> TraitData.Rarity:
	var roll = randf() * 100.0
	
	if roll <= 0.2:
		return TraitData.Rarity.SUPREME
	elif roll <= 1.0: # 0.2 + 0.8
		return TraitData.Rarity.DIVINE
	elif roll <= 5.0: # 1.0 + 4.0
		return TraitData.Rarity.IMMORTAL
	elif roll <= 15.0: # 5.0 + 10.0
		return TraitData.Rarity.HEAVEN
	elif roll <= 30.0: # 15.0 + 15.0
		return TraitData.Rarity.EARTH
	elif roll <= 50.0: # 30.0 + 20.0
		return TraitData.Rarity.SPIRIT
	elif roll <= 80.0: # 50.0 + 30.0
		return TraitData.Rarity.MORTAL
	else: # 80.0 + 20.0 = 100.0
		return TraitData.Rarity.TRASH

func _generate_mock_trait_by_rarity(rarity: TraitData.Rarity) -> TraitData:
	var trait_data = TraitData.new()
	trait_data.rarity = rarity
	trait_data.is_hidden = false
	
	match rarity:
		TraitData.Rarity.TRASH:
			trait_data.trait_name = "Thế Nhược"
			trait_data.description = "[Phế Phẩm] Cơ thể ốm yếu."
			trait_data.physique_mod = -1
		TraitData.Rarity.MORTAL:
			trait_data.trait_name = "Bình Dung"
			trait_data.description = "[Phàm Phẩm] Không có gì nổi bật."
		TraitData.Rarity.SPIRIT:
			trait_data.trait_name = "Mộc Thể"
			trait_data.description = "[Linh Phẩm] Hấp thụ linh khí hệ mộc tốt hơn."
			trait_data.spiritual_power_mod = 1
		TraitData.Rarity.EARTH:
			trait_data.trait_name = "Hảo Vận"
			trait_data.description = "[Địa Phẩm] Hay gặp may mắn nhỏ."
			trait_data.fortune_mod = 2
		TraitData.Rarity.HEAVEN:
			trait_data.trait_name = "Thiên Tài"
			trait_data.description = "[Thiên Phẩm] Tốc độ tu luyện vượt trội."
			trait_data.aptitude_mod = 3
		TraitData.Rarity.IMMORTAL:
			trait_data.trait_name = "Tiên Tư"
			trait_data.description = "[Tiên Phẩm] Tư chất sánh ngang tiên nhân."
			trait_data.aptitude_mod = 5
			trait_data.physique_mod = 2
		TraitData.Rarity.DIVINE:
			trait_data.trait_name = "Thần Hồn"
			trait_data.description = "[Thần Phẩm] Hồn phách ngưng tụ thành thực thể."
			trait_data.soul_power_mod = 8
		TraitData.Rarity.SUPREME:
			trait_data.trait_name = "Hỗn Độn Đạo Thể"
			trait_data.description = "[Vô Thượng] Thể chất tối cao trong truyền thuyết."
			trait_data.physique_mod = 10
			trait_data.spiritual_power_mod = 10
			
	return trait_data

func _check_and_add_hidden_traits() -> void:
	# Ensure hidden traits are assigned correctly
	
	# Remove old hidden traits first so they don't stack if stats change
	var new_traits: Array[TraitData] = []
	for trait_data in current_traits:
		if not trait_data.is_hidden:
			new_traits.append(trait_data)
	current_traits = new_traits
	
	if current_stats["physique"] == 11:
		_add_hidden_trait("Lực bạt sơn hà", "Sức mạnh thân thể vô địch.", "physique")
	if current_stats["spiritual_power"] == 11:
		_add_hidden_trait("Linh thể", "Thể chất gần gũi với thiên địa linh khí.", "spiritual_power")
	if current_stats["soul_power"] == 11:
		_add_hidden_trait("Linh hồn bất diệt", "Hồn phách mạnh mẽ vô cùng.", "soul_power")
	if current_stats["fortune"] == 11:
		_add_hidden_trait("Thiên mệnh chi tử", "Con cưng của trời, làm gì cũng thuận lợi.", "fortune")
	if current_stats["aptitude"] == 11:
		_add_hidden_trait("Học bá", "Ngộ tính đỉnh cao, học 1 hiểu 10.", "aptitude")
	if current_stats["mystery_stat"] == 11:
		_add_hidden_trait("???", "Bí ẩn khó lường.", "mystery_stat")

func _add_hidden_trait(trait_name: String, desc: String, _stat_mod_name: String) -> void:
	var hidden_trait = TraitData.new()
	hidden_trait.trait_name = trait_name
	hidden_trait.description = desc
	hidden_trait.is_hidden = true
	# Optional: hidden trait could also provide further stat buffs
	current_traits.append(hidden_trait)

func apply_and_start_game() -> void:
	GameManager.start_new_game()
	var player = GameManager.player_stats
	
	player.physique = current_stats["physique"]
	player.spiritual_power = current_stats["spiritual_power"]
	player.soul_power = current_stats["soul_power"]
	player.fortune = current_stats["fortune"]
	player.aptitude = current_stats["aptitude"]
	player.mystery_stat = current_stats["mystery_stat"]
	
	player.traits.clear()
	for t in current_traits:
		player.traits.append(t)
		
	player.calculate_derived_stats()
	
	_roll_background(player)
	
	GameManager.save_current_game()
	creation_finished.emit()
	print("Character creation finished. Game saved.")

func _roll_background(player: CharacterStats) -> void:
	# Calculate Fortune impact: 1 point above/below 5 = 2% impact. Can be negative!
	var fortune_bonus = (player.fortune - 5) * 2
	
	# Gamepass adds a flat bonus chunk to high rarities
	var gamepass_bonus = 10 if has_gamepass else 0
	
	# Calculate thresholds (base + modifiers). 
	# If fortune is low, negative bonus increases bad backgrounds and decreases good ones.
	var orphan_chance = max(0, 10 - (fortune_bonus * 2))
	var normal_chance = max(0, 50 - fortune_bonus)
	var good_chance = max(0, 20 + (fortune_bonus * 1.5) + gamepass_bonus)
	var very_good_chance = max(0, 15 + fortune_bonus + (gamepass_bonus / 2.0))
	var super_good_chance = max(0, 5 + (fortune_bonus / 2.0) + (gamepass_bonus / 2.0))
	
	# Normalize to ensure sum is exactly 100 (in case of weird float math)
	var total_weight = orphan_chance + normal_chance + good_chance + very_good_chance + super_good_chance
	var roll = randf() * total_weight
	
	var accumulated = 0.0
	
	accumulated += super_good_chance
	if roll <= accumulated:
		player.background_rarity = CharacterStats.BackgroundRarity.SUPER_GOOD
		player.background_name = ["Thế gia cổ lão", "Ngũ đại tiên môn"][randi() % 2]
		return
		
	accumulated += very_good_chance
	if roll <= accumulated:
		player.background_rarity = CharacterStats.BackgroundRarity.VERY_GOOD
		player.background_name = ["Thế gia", "Thành chủ", "Thân vương", "Tiểu môn phái"][randi() % 4]
		return
		
	accumulated += good_chance
	if roll <= accumulated:
		player.background_rarity = CharacterStats.BackgroundRarity.GOOD
		player.background_name = ["Địa chủ", "Quan thứ phẩm", "Thương đoàn"][randi() % 3]
		return
		
	accumulated += normal_chance
	if roll <= accumulated:
		player.background_rarity = CharacterStats.BackgroundRarity.NORMAL
		player.background_name = ["Thợ rèn", "Nông dân", "Thợ may", "Thầy thuốc", "Khách điếm"][randi() % 5]
		return
		
	player.background_rarity = CharacterStats.BackgroundRarity.ORPHAN
	player.background_name = "Mồ côi"

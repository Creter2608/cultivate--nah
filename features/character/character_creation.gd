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
	# Clear previous normal traits, keeping hidden ones
	var new_traits: Array[TraitData] = []
	var existing_names: Array[String] = []
	
	for trait_data in current_traits:
		if trait_data.is_hidden:
			new_traits.append(trait_data)
			existing_names.append(trait_data.trait_name)
			
	current_traits = new_traits
	
	# Roll exactly 3 normal traits without duplicate names
	for i in range(3):
		var rolled_trait = _roll_unique_trait(existing_names)
		if rolled_trait != null:
			current_traits.append(rolled_trait)
			existing_names.append(rolled_trait.trait_name)

func _roll_unique_trait(existing_names: Array[String]) -> TraitData:
	# Try rolling by rarity up to 10 times to find a unique trait
	for attempt in range(10):
		var rarity = _roll_trait_rarity()
		var candidate = _pick_random_trait_by_rarity(rarity, existing_names)
		if candidate != null:
			return candidate
			
	# Fallback: Pick any available unpicked trait from any rarity
	for r in [
		TraitData.Rarity.TRASH,
		TraitData.Rarity.MORTAL,
		TraitData.Rarity.SPIRIT,
		TraitData.Rarity.EARTH,
		TraitData.Rarity.HEAVEN,
		TraitData.Rarity.IMMORTAL,
		TraitData.Rarity.DIVINE,
		TraitData.Rarity.SUPREME
	]:
		var fallback_candidate = _pick_random_trait_by_rarity(r, existing_names)
		if fallback_candidate != null:
			return fallback_candidate
			
	return null

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

func _pick_random_trait_by_rarity(rarity: TraitData.Rarity, exclude_names: Array[String]) -> TraitData:
	var pool = _get_traits_by_rarity(rarity)
	var available: Array[TraitData] = []
	for t in pool:
		if not exclude_names.has(t.trait_name):
			available.append(t)
			
	if available.is_empty():
		return null
		
	return available[randi() % available.size()]

func _get_traits_by_rarity(rarity: TraitData.Rarity) -> Array[TraitData]:
	var list: Array[TraitData] = []
	match rarity:
		TraitData.Rarity.TRASH:
			list.append(_create_trait("Thế Nhược", "[Phế Phẩm] Cơ thể ốm yếu.", rarity, {"physique_mod": -1}))
			list.append(_create_trait("Bạch Đinh", "[Phế Phẩm] Căn cốt bình thường, thiếu linh khí.", rarity, {"spiritual_power_mod": -1}))
			list.append(_create_trait("Mộc Đầu", "[Phế Phẩm] Ngộ tính kém cỏi.", rarity, {"aptitude_mod": -1}))
			list.append(_create_trait("Xui Xẻo", "[Phế Phẩm] Hay gặp vận xui.", rarity, {"fortune_mod": -1}))
		TraitData.Rarity.MORTAL:
			list.append(_create_trait("Bình Dung", "[Phàm Phẩm] Không có gì nổi bật.", rarity, {}))
			list.append(_create_trait("Cần Cù", "[Phàm Phẩm] Siêng năng bù thông minh.", rarity, {"aptitude_mod": 1}))
			list.append(_create_trait("Dẻo Dai", "[Phàm Phẩm] Thể lực bền bỉ hơn người.", rarity, {"physique_mod": 1}))
			list.append(_create_trait("Tâm Trí Trầm An", "[Phàm Phẩm] Hồn lực kiên định.", rarity, {"soul_power_mod": 1}))
		TraitData.Rarity.SPIRIT:
			list.append(_create_trait("Mộc Thể", "[Linh Phẩm] Hấp thụ linh khí hệ mộc tốt hơn.", rarity, {"spiritual_power_mod": 1}))
			list.append(_create_trait("Kim Cốt", "[Linh Phẩm] Xương cốt cứng cáp như kim loại.", rarity, {"physique_mod": 2}))
			list.append(_create_trait("Thanh Tâm", "[Linh Phẩm] Tâm trí thanh tĩnh, dễ tập trung.", rarity, {"soul_power_mod": 2}))
			list.append(_create_trait("Linh Đồng", "[Linh Phẩm] Sinh ra có mắt sáng, nhận biết linh khí.", rarity, {"aptitude_mod": 2}))
		TraitData.Rarity.EARTH:
			list.append(_create_trait("Hảo Vận", "[Địa Phẩm] Hay gặp may mắn nhỏ.", rarity, {"fortune_mod": 2}))
			list.append(_create_trait("Địa Linh Thể", "[Địa Phẩm] Thể chất hòa hợp với địa khí.", rarity, {"physique_mod": 3}))
			list.append(_create_trait("Thuần Nguyện Hồn", "[Địa Phẩm] Hồn lực tinh thuần.", rarity, {"soul_power_mod": 3}))
			list.append(_create_trait("Linh Tri", "[Địa Phẩm] Ngộ tính cao hơn hẳn người thường.", rarity, {"aptitude_mod": 3}))
		TraitData.Rarity.HEAVEN:
			list.append(_create_trait("Thiên Tài", "[Thiên Phẩm] Tốc độ tu luyện vượt trội.", rarity, {"aptitude_mod": 3, "spiritual_power_mod": 1}))
			list.append(_create_trait("Bát Hoang Thể", "[Thiên Phẩm] Sức mạnh thể chất ngang hàng hung thú.", rarity, {"physique_mod": 4}))
			list.append(_create_trait("Khí Vận Chi Tinh", "[Thiên Phẩm] Vận khí ngút trời.", rarity, {"fortune_mod": 4}))
			list.append(_create_trait("Vô Cực Hồn", "[Thiên Phẩm] Hồn phách vô cùng kiên cố.", rarity, {"soul_power_mod": 4}))
		TraitData.Rarity.IMMORTAL:
			list.append(_create_trait("Tiên Tư", "[Tiên Phẩm] Tư chất sánh ngang tiên nhân.", rarity, {"aptitude_mod": 5, "physique_mod": 2}))
			list.append(_create_trait("Cửu Chuyển Kim Thân", "[Tiên Phẩm] Thân thể bất hoại qua chín lần tôi luyện.", rarity, {"physique_mod": 6}))
			list.append(_create_trait("Tiên Linh Thể", "[Tiên Phẩm] Thể chất thuần khiết, linh khí tự hội tụ.", rarity, {"spiritual_power_mod": 6}))
		TraitData.Rarity.DIVINE:
			list.append(_create_trait("Thần Hồn", "[Thần Phẩm] Hồn phách ngưng tụ thành thực thể.", rarity, {"soul_power_mod": 8}))
			list.append(_create_trait("Thần Ma Lực", "[Thần Phẩm] Sức mạnh ngang tầm Thần Ma cổ đại.", rarity, {"physique_mod": 8}))
			list.append(_create_trait("Thần Quang Phủ Chiếu", "[Thần Phẩm] Vận may thần thánh che chở.", rarity, {"fortune_mod": 8}))
		TraitData.Rarity.SUPREME:
			list.append(_create_trait("Hỗn Độn Đạo Thể", "[Vô Thượng] Thể chất tối cao trong truyền thuyết.", rarity, {"physique_mod": 10, "spiritual_power_mod": 10}))
			list.append(_create_trait("Vạn Pháp Quy Nhất", "[Vô Thượng] Luyện thành vạn pháp, ngộ tính vô song.", rarity, {"aptitude_mod": 10, "soul_power_mod": 10}))
			list.append(_create_trait("Chủ Tể Khí Vận", "[Vô Thượng] Nắm giữ vận mệnh thiên địa.", rarity, {"fortune_mod": 10, "mystery_stat_mod": 10}))
	return list

func _create_trait(t_name: String, desc: String, rarity: TraitData.Rarity, mods: Dictionary) -> TraitData:
	var t = TraitData.new()
	t.trait_name = t_name
	t.description = desc
	t.rarity = rarity
	t.is_hidden = false
	t.physique_mod = mods.get("physique_mod", 0)
	t.spiritual_power_mod = mods.get("spiritual_power_mod", 0)
	t.soul_power_mod = mods.get("soul_power_mod", 0)
	t.fortune_mod = mods.get("fortune_mod", 0)
	t.aptitude_mod = mods.get("aptitude_mod", 0)
	t.mystery_stat_mod = mods.get("mystery_stat_mod", 0)
	return t

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

func _add_hidden_trait(trait_name: String, desc: String, stat_mod_name: String) -> void:
	var hidden_trait = TraitData.new()
	hidden_trait.trait_name = trait_name
	hidden_trait.description = desc
	hidden_trait.is_hidden = true
	hidden_trait.rarity = TraitData.Rarity.HIDDEN
	# Grant +5 modifier to the stat that triggered this hidden trait
	match stat_mod_name:
		"physique":
			hidden_trait.physique_mod = 5
		"spiritual_power":
			hidden_trait.spiritual_power_mod = 5
		"soul_power":
			hidden_trait.soul_power_mod = 5
		"fortune":
			hidden_trait.fortune_mod = 5
		"aptitude":
			hidden_trait.aptitude_mod = 5
		"mystery_stat":
			hidden_trait.mystery_stat_mod = 5
	current_traits.append(hidden_trait)

func apply_and_start_game() -> void:
	GameManager.start_new_game(GameManager.pending_char_name, GameManager.pending_char_gender)
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
	
	# Transition to gameplay
	GameManager.change_scene("res://features/gameplay/placeholder_gameplay.tscn")

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

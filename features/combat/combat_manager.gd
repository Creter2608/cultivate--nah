extends Node

signal combat_started
signal combat_ended(player_won: bool)
signal player_attacked(damage: int, is_crit: bool)
signal enemy_attacked(damage: int, is_crit: bool)

# Entities
var player_stats: CharacterStats = null
var enemy_stats: CharacterStats = null

# Timers
var player_attack_timer: Timer
var enemy_attack_timer: Timer

# Rhythm Game State
var has_4th_wall_active: bool = false
var current_rhythm_accuracy: float = 1.0 # 0.0 to 1.0 (0% to 100%)

var is_combat_active: bool = false

func _ready() -> void:
	# Create internal timers for auto-battler
	player_attack_timer = Timer.new()
	player_attack_timer.one_shot = false
	player_attack_timer.timeout.connect(_on_player_attack)
	add_child(player_attack_timer)
	
	enemy_attack_timer = Timer.new()
	enemy_attack_timer.one_shot = false
	enemy_attack_timer.timeout.connect(_on_enemy_attack)
	add_child(enemy_attack_timer)

## Initializes and starts combat between player and an enemy
func start_combat(p_stats: CharacterStats, e_stats: CharacterStats) -> void:
	player_stats = p_stats
	enemy_stats = e_stats
	
	# Set timer durations based on attack speed (Attack per second)
	# e.g., 2.0 attack speed = 0.5s timer
	player_attack_timer.wait_time = 1.0 / max(0.1, player_stats.attack_speed)
	enemy_attack_timer.wait_time = 1.0 / max(0.1, enemy_stats.attack_speed)
	
	is_combat_active = true
	combat_started.emit()
	
	player_attack_timer.start()
	enemy_attack_timer.start()
	print("Combat started! Player AS: %.2f | Enemy AS: %.2f" % [player_stats.attack_speed, enemy_stats.attack_speed])
	
	_check_4th_wall_skill()

func _on_player_attack() -> void:
	if not is_combat_active: return
	
	var damage = player_stats.physical_damage # Simplification for now
	var rhythm_multiplier = 1.0
	
	# Apply real-time rhythm buff/debuff
	if has_4th_wall_active:
		if current_rhythm_accuracy >= 0.5:
			# Buff: 50% = 1.0x damage, 100% = 2.0x damage
			rhythm_multiplier = 1.0 + ((current_rhythm_accuracy - 0.5) * 2.0)
		else:
			# Debuff: 0% = 0.1x damage, 50% = 1.0x damage
			rhythm_multiplier = 0.1 + (current_rhythm_accuracy * 1.8)
			
		damage = int(damage * rhythm_multiplier)
		
	# Basic armor mitigation
	var actual_damage = max(1, damage - enemy_stats.physical_armor)
	enemy_stats.current_hp -= actual_damage
	
	player_attacked.emit(actual_damage, false)
	print("Player attacks for %d damage (Rhythm Acc: %.0f%%). Enemy HP: %d" % [actual_damage, current_rhythm_accuracy * 100, enemy_stats.current_hp])
	
	if enemy_stats.current_hp <= 0:
		_end_combat(true)

func _on_enemy_attack() -> void:
	if not is_combat_active: return
	
	var damage = enemy_stats.physical_damage
	var actual_damage = max(1, damage - player_stats.physical_armor)
	player_stats.current_hp -= actual_damage
	
	enemy_attacked.emit(actual_damage, false)
	print("Enemy attacks for %d damage. Player HP: %d" % [actual_damage, player_stats.current_hp])
	
	if player_stats.current_hp <= 0:
		_end_combat(false)

func _end_combat(player_won: bool) -> void:
	is_combat_active = false
	player_attack_timer.stop()
	enemy_attack_timer.stop()
	
	combat_ended.emit(player_won)
	if player_won:
		print("Combat ended. Player VICTORIOUS!")
	else:
		print("Combat ended. Player DEFEATED!")

## ---- 4TH WALL RHYTHM GAME LOGIC ----

func _check_4th_wall_skill() -> void:
	has_4th_wall_active = false
	current_rhythm_accuracy = 1.0
	
	for t_data in player_stats.traits:
		if t_data.trait_name == "Bức Tường Thứ 4":
			has_4th_wall_active = true
			break
	
	# In actual implementation, we also check GameManager.has_gamepass
	if has_4th_wall_active:
		print("4th Wall Skill detected! Preparing Osu-style Rhythm Minigame...")
		# Normally, we would instantiate a RhythmMinigame UI here.

## Called by the Rhythm UI continuously to update the real-time accuracy (0.0 to 1.0)
func update_rhythm_accuracy(accuracy: float) -> void:
	if not is_combat_active or not has_4th_wall_active: return
	current_rhythm_accuracy = clamp(accuracy, 0.0, 1.0)

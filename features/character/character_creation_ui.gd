extends Control

const CharacterCreation = preload("res://features/character/character_creation.gd")
var logic: Node

# UI Refs
@onready var lbl_rolls = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/LblRolls
@onready var btn_roll_all = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollAll
@onready var btn_roll_physique = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollPhysique
@onready var btn_roll_spiritual = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollSpiritual
@onready var btn_roll_soul = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollSoul
@onready var btn_roll_fortune = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollFortune
@onready var btn_roll_aptitude = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollAptitude
@onready var btn_roll_mystery = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollMystery
@onready var btn_roll_traits = $VBoxContainer/ContentSplit/PanelLeft/VBoxContainer/BtnRollTraits
@onready var btn_start = $VBoxContainer/BtnStart

@onready var lbl_stats = $VBoxContainer/ContentSplit/PanelRight/VBoxContainer/LblStats
@onready var lbl_traits = $VBoxContainer/ContentSplit/PanelRight/VBoxContainer/LblTraits
@onready var lbl_background = $VBoxContainer/ContentSplit/PanelRight/VBoxContainer/LblBackground

func _ready() -> void:
	logic = CharacterCreation.new()
	add_child(logic)
	
	logic.stats_rolled.connect(_update_ui)
	logic.traits_rolled.connect(_update_ui)
	logic.creation_finished.connect(_on_creation_finished)
	
	# Connect buttons
	btn_roll_all.pressed.connect(func(): logic.roll_all_stats())
	btn_roll_physique.pressed.connect(func(): logic.roll_single_stat("physique"))
	btn_roll_spiritual.pressed.connect(func(): logic.roll_single_stat("spiritual_power"))
	btn_roll_soul.pressed.connect(func(): logic.roll_single_stat("soul_power"))
	btn_roll_fortune.pressed.connect(func(): logic.roll_single_stat("fortune"))
	btn_roll_aptitude.pressed.connect(func(): logic.roll_single_stat("aptitude"))
	btn_roll_mystery.pressed.connect(func(): logic.roll_single_stat("mystery_stat"))
	btn_roll_traits.pressed.connect(func(): logic.roll_traits_only())
	
	btn_start.pressed.connect(func(): logic.apply_and_start_game())
	
	_update_ui()

func _update_ui() -> void:
	lbl_rolls.text = "Free Rolls: %d | Ad Rolls: %d" % [logic.free_rolls, logic.ad_rolls]
	
	# Stats
	var s = logic.current_stats
	lbl_stats.text = "--- CHỈ SỐ ---\n"
	lbl_stats.text += "Thể phách: %d\n" % s["physique"]
	lbl_stats.text += "Linh lực: %d\n" % s["spiritual_power"]
	lbl_stats.text += "Hồn lực: %d\n" % s["soul_power"]
	lbl_stats.text += "Khí vận: %d\n" % s["fortune"]
	lbl_stats.text += "Tư chất: %d\n" % s["aptitude"]
	lbl_stats.text += "Bí ẩn: %d\n" % s["mystery_stat"]
	
	# Traits
	lbl_traits.text = "\n--- MỆNH CÁCH ---\n"
	for trait_data in logic.current_traits:
		if trait_data.is_hidden:
			lbl_traits.text += "[ẨN] %s: %s\n" % [trait_data.trait_name, trait_data.description]
		else:
			lbl_traits.text += "[Rarity: %d] %s: %s\n" % [trait_data.rarity, trait_data.trait_name, trait_data.description]
			
	var fortune_bonus = (s["fortune"] - 5) * 2
	var sign_str = "+" if fortune_bonus >= 0 else ""
	lbl_background.text = "\n--- GIA CẢNH ---\n?? (Khí vận đang tác động: %s%d%%)\n(Sẽ đổ khi vào game)" % [sign_str, fortune_bonus]

func _on_creation_finished() -> void:
	var player = GameManager.player_stats
	lbl_background.text = "\n--- GIA CẢNH ---\n[%d] %s" % [player.background_rarity, player.background_name]
	
	btn_roll_all.disabled = true
	btn_roll_physique.disabled = true
	btn_roll_spiritual.disabled = true
	btn_roll_soul.disabled = true
	btn_roll_fortune.disabled = true
	btn_roll_aptitude.disabled = true
	btn_roll_mystery.disabled = true
	btn_roll_traits.disabled = true
	btn_start.disabled = true
	
	print("Game is ready. You can transition to the actual game scene now.")

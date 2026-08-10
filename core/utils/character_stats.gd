class_name CharacterStats
extends Resource

enum BackgroundRarity { ORPHAN = 0, NORMAL = 1, GOOD = 2, VERY_GOOD = 3, SUPER_GOOD = 4 }

# ==========================================
# CORE STATS
# ==========================================
## Physique: scales HP, physical damage, and physical armor. Increases body refinement learning speed.
@export var physique: int = 10
## Spiritual Power: scales MP, magic damage, and magic armor. Increases spell and alchemy learning speed.
@export var spiritual_power: int = 10
## Soul Power: resists illusions and mind control, increases soul-based learning speed.
@export var soul_power: int = 10
## Fortune: success rate for probabilistic events, triggers rare encounters.
@export var fortune: int = 5
## Aptitude: learning ability and skill effectiveness.
@export var aptitude: int = 10
## Mystery Stat: unknown purpose.
@export var mystery_stat: int = 0

# ==========================================
# TRAITS / MỆNH CÁCH
# ==========================================
## List of TraitData resources applied to this character
@export var traits: Array[TraitData] = []

# ==========================================
# BACKGROUND / GIA CẢNH
# ==========================================
@export var background_rarity: BackgroundRarity = BackgroundRarity.NORMAL
@export var background_name: String = "Bình Phàm"

# ==========================================
# CURRENCIES
# ==========================================
@export var gold: int = 0
@export var silver: int = 0
@export var spirit_stones: int = 0
@export var law_fragments: int = 0

# ==========================================
# CULTIVATION & TIME
# ==========================================
# 0 = Mortal, 1 = Body Refinement, 2 = Qi Condensation, 3 = Foundation Establishment, etc.
@export var realm_level: int = 0 
@export var current_exp: int = 0
@export var max_exp: int = 100

@export var age: int = 0
@export var lifespan: int = 80 # Will be randomized on new game if mortal

# ==========================================
# DERIVED STATS
# ==========================================
var max_hp: int = 100
var current_hp: int = 100

var max_mp: int = 50
var current_mp: int = 50

var physical_damage: int = 10
var physical_armor: int = 5

var magic_damage: int = 10
var magic_armor: int = 5

var agility: int = 10
var attack_speed: float = 1.0 # Attacks per second

## Recalculates derived stats based on core stats and realm
func calculate_derived_stats():
	# Temporary formula (can be balanced later)
	max_hp = 100 + (physique * 10) + (realm_level * 50)
	physical_damage = (physique * 2)
	physical_armor = (physique * 1)
	agility = physique * 2 # Agility is derived from Physique
	
	max_mp = 50 + (spiritual_power * 10) + (realm_level * 50)
	magic_damage = (spiritual_power * 2)
	magic_armor = (spiritual_power * 1)
	
	# Attack speed calculation (e.g. base 1.0 + 0.01 per agility point)
	attack_speed = 1.0 + (agility * 0.01)
	
	# Ensure current HP and MP do not exceed maximums
	current_hp = clampi(current_hp, 0, max_hp)
	current_mp = clampi(current_mp, 0, max_mp)

## Converts data to Dictionary for saving
func to_dict() -> Dictionary:
	var traits_array = []
	for trait_data in traits:
		if trait_data != null:
			traits_array.append(trait_data.to_dict())
			
	return {
		"physique": physique,
		"spiritual_power": spiritual_power,
		"soul_power": soul_power,
		"fortune": fortune,
		"aptitude": aptitude,
		"mystery_stat": mystery_stat,
		"traits": traits_array,
		"background_rarity": background_rarity,
		"background_name": background_name,
		"gold": gold,
		"silver": silver,
		"spirit_stones": spirit_stones,
		"law_fragments": law_fragments,
		"realm_level": realm_level,
		"current_exp": current_exp,
		"max_exp": max_exp,
		"age": age,
		"lifespan": lifespan,
		"current_hp": current_hp,
		"current_mp": current_mp
	}

## Loads data from Dictionary
func from_dict(data: Dictionary):
	physique = data.get("physique", physique)
	spiritual_power = data.get("spiritual_power", spiritual_power)
	soul_power = data.get("soul_power", soul_power)
	fortune = data.get("fortune", fortune)
	aptitude = data.get("aptitude", aptitude)
	mystery_stat = data.get("mystery_stat", mystery_stat)
	
	traits.clear()
	if data.has("traits"):
		for trait_dict in data["traits"]:
			var new_trait = TraitData.new()
			new_trait.from_dict(trait_dict)
			traits.append(new_trait)
			
	background_rarity = data.get("background_rarity", background_rarity)
	background_name = data.get("background_name", background_name)
	
	gold = data.get("gold", gold)
	silver = data.get("silver", silver)
	spirit_stones = data.get("spirit_stones", spirit_stones)
	law_fragments = data.get("law_fragments", law_fragments)
	
	realm_level = data.get("realm_level", realm_level)
	current_exp = data.get("current_exp", current_exp)
	max_exp = data.get("max_exp", max_exp)
	
	age = data.get("age", age)
	lifespan = data.get("lifespan", lifespan)
	
	calculate_derived_stats()
	current_hp = data.get("current_hp", max_hp)
	current_mp = data.get("current_mp", max_mp)

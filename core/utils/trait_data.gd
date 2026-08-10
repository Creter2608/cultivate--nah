class_name TraitData
extends Resource

enum Rarity { TRASH = 0, MORTAL = 1, SPIRIT = 2, EARTH = 3, HEAVEN = 4, IMMORTAL = 5, DIVINE = 6, SUPREME = 7, HIDDEN = 8 }

## The name of the trait (Mệnh cách)
@export var trait_name: String = ""

## Description of the trait
@export_multiline var description: String = ""

## Is this a hidden trait? (Mệnh cách ẩn)
@export var is_hidden: bool = false

## Rarity level of the trait
@export var rarity: Rarity = Rarity.MORTAL

# Stat modifiers (additive). For example, +5 physique.
@export var physique_mod: int = 0
@export var spiritual_power_mod: int = 0
@export var soul_power_mod: int = 0
@export var fortune_mod: int = 0
@export var aptitude_mod: int = 0
@export var mystery_stat_mod: int = 0

func to_dict() -> Dictionary:
	return {
		"trait_name": trait_name,
		"description": description,
		"is_hidden": is_hidden,
		"rarity": rarity,
		"physique_mod": physique_mod,
		"spiritual_power_mod": spiritual_power_mod,
		"soul_power_mod": soul_power_mod,
		"fortune_mod": fortune_mod,
		"aptitude_mod": aptitude_mod,
		"mystery_stat_mod": mystery_stat_mod
	}

func from_dict(data: Dictionary) -> void:
	trait_name = data.get("trait_name", trait_name)
	description = data.get("description", description)
	is_hidden = data.get("is_hidden", is_hidden)
	rarity = data.get("rarity", rarity)
	
	physique_mod = data.get("physique_mod", physique_mod)
	spiritual_power_mod = data.get("spiritual_power_mod", spiritual_power_mod)
	soul_power_mod = data.get("soul_power_mod", soul_power_mod)
	fortune_mod = data.get("fortune_mod", fortune_mod)
	aptitude_mod = data.get("aptitude_mod", aptitude_mod)
	mystery_stat_mod = data.get("mystery_stat_mod", mystery_stat_mod)

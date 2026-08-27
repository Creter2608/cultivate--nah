class_name ItemData
extends Resource

enum ItemType { CONSUMABLE, MATERIAL, MANUAL, EQUIPMENT, STORAGE }
enum Rarity { TRASH = 0, MORTAL = 1, SPIRIT = 2, EARTH = 3, HEAVEN = 4, IMMORTAL = 5, DIVINE = 6, SUPREME = 7 }

@export var id: String = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.MORTAL
@export var max_stack: int = 99

# Stats (For equipment or consumables)
@export var physique_bonus: int = 0
@export var spiritual_power_bonus: int = 0
@export var soul_power_bonus: int = 0
@export var hp_heal: int = 0

# Requirements
@export var required_realm_level: int = 0

# Storage (For STORAGE type items like Backpack, Storage Ring)
@export var bonus_inventory_slots: int = 0

## Checks if the character satisfies the realm level requirements to use or equip this item
func can_use(character_stats: CharacterStats) -> bool:
	if character_stats == null:
		return false
	return character_stats.realm_level >= required_realm_level

func to_dict() -> Dictionary:
	return {
		"id": id,
		"item_name": item_name,
		"description": description,
		"item_type": item_type,
		"rarity": rarity,
		"max_stack": max_stack,
		"physique_bonus": physique_bonus,
		"spiritual_power_bonus": spiritual_power_bonus,
		"soul_power_bonus": soul_power_bonus,
		"hp_heal": hp_heal,
		"required_realm_level": required_realm_level,
		"bonus_inventory_slots": bonus_inventory_slots
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", id)
	item_name = data.get("item_name", item_name)
	description = data.get("description", description)
	item_type = data.get("item_type", item_type)
	rarity = data.get("rarity", rarity)
	max_stack = data.get("max_stack", max_stack)
	
	physique_bonus = data.get("physique_bonus", physique_bonus)
	spiritual_power_bonus = data.get("spiritual_power_bonus", spiritual_power_bonus)
	soul_power_bonus = data.get("soul_power_bonus", soul_power_bonus)
	hp_heal = data.get("hp_heal", hp_heal)
	required_realm_level = data.get("required_realm_level", required_realm_level)
	
	bonus_inventory_slots = data.get("bonus_inventory_slots", bonus_inventory_slots)

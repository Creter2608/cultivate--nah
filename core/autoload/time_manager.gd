extends Node

signal time_advanced(ap_consumed: int)
signal season_advanced(new_season: int)
signal year_advanced(new_year: int)
signal age_increased(new_age: int)
signal player_died_of_old_age

const MAX_AP_PER_SEASON: int = 90
const SEASONS_PER_YEAR: int = 4

var current_year: int = 1
var current_season: int = 1 # 1: Spring, 2: Summer, 3: Autumn, 4: Winter
var current_ap: int = MAX_AP_PER_SEASON

## Consumes Action Points for an activity. Triggers season/year advancements if AP drops below 0.
func consume_ap(amount: int) -> void:
	if amount < 0:
		return
		
	current_ap -= amount
	time_advanced.emit(amount)
	print("Consumed %d AP. Remaining AP this season: %d" % [amount, current_ap])
	
	while current_ap <= 0:
		var overflow = abs(current_ap)
		_advance_season()
		current_ap -= overflow # Deduct overflow from the new season's AP

func _advance_season() -> void:
	current_ap = MAX_AP_PER_SEASON
	current_season += 1
	
	if current_season > SEASONS_PER_YEAR:
		current_season = 1
		_advance_year()
		
	season_advanced.emit(current_season)
	print("Advanced to season %d of year %d." % [current_season, current_year])

func _advance_year() -> void:
	current_year += 1
	year_advanced.emit(current_year)
	print("Advanced to year %d." % current_year)
	
	# Increase player age if GameManager exists and player_stats are loaded
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.player_stats != null:
			gm.player_stats.age += 1
			age_increased.emit(gm.player_stats.age)
			print("Player age increased to %d. Lifespan: %d" % [gm.player_stats.age, gm.player_stats.lifespan])
			
			if gm.player_stats.age >= gm.player_stats.lifespan:
				player_died_of_old_age.emit()
				print("GAME OVER: Player has died of old age (reached lifespan limit).")

## Serializes time state for saving
func to_dict() -> Dictionary:
	return {
		"current_year": current_year,
		"current_season": current_season,
		"current_ap": current_ap
	}

## Deserializes time state from save file
func from_dict(data: Dictionary) -> void:
	current_year = data.get("current_year", current_year)
	current_season = data.get("current_season", current_season)
	current_ap = data.get("current_ap", current_ap)

extends Node

var unlocked_levels = {
	"VIP Suite": true, 
	"Diagnostics": false,
	"Quarantine": false,
	"Cafeteria": false,
	"Courtyard": false
}

func unlock_level(level_name: String):
	if unlocked_levels.has(level_name):
		unlocked_levels[level_name] = true

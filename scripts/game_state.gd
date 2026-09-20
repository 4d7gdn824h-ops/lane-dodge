extends Node

const SAVE_PATH := "user://lane_dodge.cfg"
const SECTION := "progress"
const KEY_BEST := "best_score"

var best_score: int = 0


func _ready() -> void:
	_load_best()


func record_score(score: int) -> void:
	if score > best_score:
		best_score = score
		_save_best()


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_score = int(cfg.get_value(SECTION, KEY_BEST, 0))


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_BEST, best_score)
	cfg.save(SAVE_PATH)

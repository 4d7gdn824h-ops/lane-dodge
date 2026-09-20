extends Node

const SAVE_PATH := "user://lane_dodge.cfg"
const SECTION := "progress"
const KEY_BEST := "best_score"
const KEY_HINT := "hint_seen"

var best_score: int = 0
var hint_seen: bool = false


func _ready() -> void:
	_load()


func record_score(score: int) -> void:
	if score > best_score:
		best_score = score
		_save()


func mark_hint_seen() -> void:
	if hint_seen:
		return
	hint_seen = true
	_save()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_score = int(cfg.get_value(SECTION, KEY_BEST, 0))
	hint_seen = bool(cfg.get_value(SECTION, KEY_HINT, false))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_BEST, best_score)
	cfg.set_value(SECTION, KEY_HINT, hint_seen)
	cfg.save(SAVE_PATH)

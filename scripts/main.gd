extends Node2D

const VIEWPORT_W := 720.0
const PLAYER_Y := 1048.0
const SPAWN_Y := -56.0
const LANE_CENTERS: Array[float] = [180.0, 360.0, 540.0]

@onready var player: Area2D = $Player
@onready var hazards: Node2D = $Hazards
@onready var score_label: Label = $HUD/UI/TopBar/ScoreLabel
@onready var best_label: Label = $HUD/UI/TopBar/BestLabel
@onready var hint_label: Label = $HUD/UI/HintLabel
@onready var pause_overlay: Control = $HUD/UI/PauseOverlay
@onready var game_over_overlay: Control = $HUD/UI/GameOverOverlay
@onready var settings_overlay: Control = $HUD/UI/SettingsOverlay
@onready var final_score_label: Label = $HUD/UI/GameOverOverlay/Panel/VBox/FinalScore
@onready var final_best_label: Label = $HUD/UI/GameOverOverlay/Panel/VBox/FinalBest

var hazard_scene: PackedScene = preload("res://scenes/hazard.tscn")
var score: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.35
var playing: bool = true
var paused: bool = false
var guaranteed_open_lane: int = 1


func _ready() -> void:
	player.setup(LANE_CENTERS, 1)
	player.position.y = PLAYER_Y
	player.died.connect(_on_player_died)
	pause_overlay.visible = false
	game_over_overlay.visible = false
	settings_overlay.visible = false
	_update_hud()


func _process(delta: float) -> void:
	if not playing or paused:
		return
	elapsed += delta
	score = int(elapsed * 10.0)
	_update_hud()

	var interval := _spawn_interval()
	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_wave(_hazard_speed())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
			return
		if not _can_steer():
			return
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			player.move_left()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			player.move_right()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(get_viewport().get_mouse_position())
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)


func _handle_tap(screen_pos: Vector2) -> void:
	if not _can_steer():
		return
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if screen_pos.x < half:
		player.move_left()
	else:
		player.move_right()


func _can_steer() -> bool:
	return playing and not paused and not settings_overlay.visible


func _hazard_speed() -> float:
	return 300.0 + elapsed * 22.0


func _spawn_interval() -> float:
	return maxf(0.42, 1.12 - elapsed * 0.028)


func _spawn_wave(speed: float) -> void:
	var blocked := _pick_blocked_lanes()
	for lane_index in blocked:
		var hazard := hazard_scene.instantiate()
		hazard.position = Vector2(LANE_CENTERS[lane_index], SPAWN_Y)
		hazard.speed = speed
		hazards.add_child(hazard)


func _pick_blocked_lanes() -> Array[int]:
	var count := 1
	if elapsed > 7.0 and randf() < minf(0.72, 0.28 + elapsed * 0.02):
		count = 2

	# Keep a continuously reachable gap: the open lane shifts by at most one.
	if randf() < 0.6:
		var step := -1 if randf() < 0.5 else 1
		guaranteed_open_lane = clampi(guaranteed_open_lane + step, 0, 2)

	var blocked: Array[int] = []
	for lane_index in 3:
		if lane_index != guaranteed_open_lane:
			blocked.append(lane_index)

	if count == 1:
		blocked.shuffle()
		var single: Array[int] = [blocked[0]]
		return single
	return blocked


func _on_player_died() -> void:
	if not playing:
		return
	playing = false
	_set_world_frozen(true)
	GameState.record_score(score)
	final_score_label.text = "Score  %d" % score
	final_best_label.text = "Best  %d" % GameState.best_score
	game_over_overlay.visible = true
	hint_label.visible = false


func _toggle_pause() -> void:
	if not playing or settings_overlay.visible:
		return
	if paused:
		_resume()
	else:
		paused = true
		_set_world_frozen(true)
		pause_overlay.visible = true


func _resume() -> void:
	if not playing:
		return
	paused = false
	pause_overlay.visible = false
	settings_overlay.visible = false
	_set_world_frozen(false)


func _set_world_frozen(frozen: bool) -> void:
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	player.process_mode = mode
	hazards.process_mode = mode


func _update_hud() -> void:
	score_label.text = "Score  %d" % score
	best_label.text = "Best  %d" % GameState.best_score


func _on_pause_pressed() -> void:
	_toggle_pause()


func _on_resume_pressed() -> void:
	_resume()


func _on_settings_pressed() -> void:
	settings_overlay.visible = true


func _on_settings_back_pressed() -> void:
	settings_overlay.visible = false


func _on_restart_pressed() -> void:
	_set_world_frozen(false)
	get_tree().reload_current_scene()

extends SceneTree
## Poses the live main scene and writes five store-brief stills.
## Not used by gameplay. Run:
##   godot --path . -s res://tools/capture_store_stills.gd --resolution 720x1280

const OUT_DIR := "res://docs/screenshots"
const LANE_X: Array[float] = [180.0, 360.0, 540.0]
const PLAYER_Y := 1048.0

var _hazard_scene: PackedScene = preload("res://scenes/hazard.tscn")
var _main: Node2D
var _out_dir: String


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(720, 1280))
	_out_dir = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(_out_dir)

	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	root.add_child(_main)
	await process_frame
	await process_frame
	_halt_gameplay()

	await _pose_title()
	await _save("01_title_start.png")

	await _pose_mid_run()
	await _save("02_mid_run.png")

	await _pose_near_miss()
	await _save("03_near_miss.png")

	await _pose_game_over()
	await _save("04_game_over_best.png")

	await _pose_pause()
	await _save("05_pause_settings.png")

	print("STORE_STILLS_OK %s" % _out_dir)
	quit(0)


func _halt_gameplay() -> void:
	_main.playing = false
	_main.set_process(false)
	_main.set_process_unhandled_input(false)
	_main.set_process_input(false)
	_clear_hazards()
	if _main.player:
		_main.player.set_process(false)


func _clear_hazards() -> void:
	for child in _main.hazards.get_children():
		child.queue_free()


func _add_hazard(lane: int, y: float) -> void:
	var hazard: Area2D = _hazard_scene.instantiate()
	hazard.position = Vector2(LANE_X[lane], y)
	hazard.speed = 0.0
	hazard.set_process(false)
	_main.hazards.add_child(hazard)


func _place_player(lane: int) -> void:
	_main.player.lane = lane
	_main.player.position = Vector2(LANE_X[lane], PLAYER_Y)
	_main.player.target_x = LANE_X[lane]


func _reset_overlays() -> void:
	_main.pause_overlay.visible = false
	_main.game_over_overlay.visible = false
	_main.settings_overlay.visible = false
	_main.get_node("HUD/UI/TopBar").visible = true
	_main.hint_label.visible = false
	_main.hint_label.modulate.a = 0.0


func _pose_title() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(1)
	_main.get_node("HUD/UI/TopBar").visible = false
	_main.hint_label.visible = true
	_main.hint_label.modulate.a = 1.0
	_main.hint_label.text = "Tap left or right"
	await process_frame


func _pose_mid_run() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(0)
	_add_hazard(1, 420.0)
	_add_hazard(2, 220.0)
	_main.score = 48
	_main.score_label.text = "Score  48"
	_main.best_label.text = "Best  96"
	await process_frame


func _pose_near_miss() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(1)
	_add_hazard(0, PLAYER_Y + 70.0)
	_add_hazard(2, 360.0)
	_main.score = 72
	_main.score_label.text = "Score  72"
	_main.best_label.text = "Best  96"
	await process_frame


func _pose_game_over() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(2)
	_add_hazard(2, PLAYER_Y - 10.0)
	_main.score = 86
	_main.score_label.text = "Score  86"
	_main.best_label.text = "Best  124"
	_main.final_score_label.text = "Score  86"
	_main.final_best_label.text = "Best  124"
	_main.game_over_overlay.visible = true
	_main.hint_label.visible = false
	await process_frame


func _pose_pause() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(1)
	_add_hazard(0, 300.0)
	_main.score = 36
	_main.score_label.text = "Score  36"
	_main.best_label.text = "Best  96"
	_main.pause_overlay.visible = true
	await process_frame


func _save(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null:
		push_error("STORE_STILLS_FAIL no viewport image for %s" % filename)
		quit(1)
		return
	var path := _out_dir.path_join(filename)
	var err := image.save_png(path)
	if err != OK:
		push_error("STORE_STILLS_FAIL save %s (%s)" % [path, err])
		quit(1)
		return
	print("Wrote %s" % path)

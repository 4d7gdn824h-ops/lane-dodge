extends SceneTree
## Poses the live main scene and writes store-brief stills.
## Default 720×1280:
##   godot --path . -s res://tools/capture_store_stills.gd --resolution 720x1280
## App Store Connect 6.7″ (1290×2796):
##   godot --path . -s res://tools/capture_store_stills.gd --resolution 1290x2796 -- --asc67

const OUT_DIR_DEFAULT := "res://docs/screenshots"
const OUT_DIR_ASC67 := "res://docs/screenshots/asc-67"
const LANE_X: Array[float] = [180.0, 360.0, 540.0]
const PLAYER_Y := 1048.0
const BASE_W := 720.0
const BASE_H := 1280.0
const ASC_W := 1290
const ASC_H := 2796

var _hazard_scene: PackedScene = preload("res://scenes/hazard.tscn")
var _main: Node2D
var _out_dir: String
var _asc67: bool = false
var _world_h: float = BASE_H
var _player_y: float = PLAYER_Y
var _target: Viewport


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_asc67 = "--asc67" in OS.get_cmdline_user_args()
	if _asc67:
		await _setup_viewport(ASC_W, ASC_H)
		_out_dir = ProjectSettings.globalize_path(OUT_DIR_ASC67)
	else:
		await _setup_viewport(720, 1280)
		_out_dir = ProjectSettings.globalize_path(OUT_DIR_DEFAULT)
	DirAccess.make_dir_recursive_absolute(_out_dir)

	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	_target = root
	if _asc67:
		var holder := SubViewportContainer.new()
		holder.stretch = true
		holder.size = Vector2(ASC_W, ASC_H)
		var sv := SubViewport.new()
		sv.size = Vector2i(ASC_W, ASC_H)
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sv.transparent_bg = false
		sv.handle_input_locally = false
		holder.add_child(sv)
		root.add_child(holder)
		sv.add_child(_main)
		_target = sv
	else:
		root.add_child(_main)
	await process_frame
	await process_frame
	_halt_gameplay()
	if _asc67:
		_layout_for_asc()

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


func _setup_viewport(width: int, height: int) -> void:
	var win := root as Window
	win.size = Vector2i(width, height)
	win.content_scale_size = Vector2i(width, height)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	win.mode = Window.MODE_WINDOWED
	await process_frame
	await process_frame


func _halt_gameplay() -> void:
	_main.playing = false
	_main.set_process(false)
	_main.set_process_unhandled_input(false)
	_main.set_process_input(false)
	_clear_hazards()
	if _main.player:
		_main.player.set_process(false)


func _layout_for_asc() -> void:
	var scale := float(ASC_W) / BASE_W
	_world_h = float(ASC_H) / scale
	_player_y = PLAYER_Y / BASE_H * _world_h
	_main.scale = Vector2(scale, scale)
	_main.position = Vector2.ZERO
	_extend_playfield(_world_h)
	_apply_safe_hud()


func _extend_playfield(local_h: float) -> void:
	_main.get_node("Background").offset_bottom = local_h
	for lane_name in ["Lane0", "Lane1", "Lane2", "Divider0", "Divider1", "EdgeL", "EdgeR"]:
		(_main.get_node("Lanes/%s" % lane_name) as ColorRect).offset_bottom = local_h


func _apply_safe_hud() -> void:
	# Center ~80% safe area on 1290×2796: 129–1161 x, 280–2516 y.
	var top_bar: Control = _main.get_node("HUD/UI/TopBar")
	top_bar.offset_left = 129.0
	top_bar.offset_right = -129.0
	top_bar.offset_top = 300.0
	top_bar.offset_bottom = 400.0
	_main.score_label.add_theme_font_size_override("font_size", 44)
	_main.best_label.add_theme_font_size_override("font_size", 40)
	_main.get_node("HUD/UI/TopBar/PauseButton").add_theme_font_size_override("font_size", 36)

	var hint: Label = _main.hint_label
	hint.offset_top = -360.0
	hint.offset_bottom = -300.0
	hint.add_theme_font_size_override("font_size", 40)

	_main.final_score_label.add_theme_font_size_override("font_size", 40)
	_main.final_best_label.add_theme_font_size_override("font_size", 34)
	_main.get_node("HUD/UI/GameOverOverlay/Panel/VBox/Title").add_theme_font_size_override("font_size", 52)
	_main.get_node("HUD/UI/PauseOverlay/Panel/VBox/Title").add_theme_font_size_override("font_size", 48)


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
	_main.player.position = Vector2(LANE_X[lane], _player_y)
	_main.player.target_x = LANE_X[lane]


func _y(base_y: float) -> float:
	return base_y / BASE_H * _world_h


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
	_add_hazard(1, _y(420.0))
	_add_hazard(2, _y(220.0))
	_main.score = 48
	_main.score_label.text = "Score  48"
	_main.best_label.text = "Best  96"
	await process_frame


func _pose_near_miss() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(1)
	_add_hazard(0, _player_y + 90.0)
	_add_hazard(2, _y(360.0))
	_main.score = 72
	_main.score_label.text = "Score  72"
	_main.best_label.text = "Best  96"
	await process_frame


func _pose_game_over() -> void:
	_clear_hazards()
	_reset_overlays()
	_place_player(2)
	_add_hazard(2, _player_y - 12.0)
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
	_add_hazard(0, _y(300.0))
	_main.score = 36
	_main.score_label.text = "Score  36"
	_main.best_label.text = "Best  96"
	_main.pause_overlay.visible = true
	await process_frame


func _save(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _target.get_texture().get_image()
	if image == null:
		push_error("STORE_STILLS_FAIL no viewport image for %s" % filename)
		quit(1)
		return
	print("Viewport capture %s %dx%d" % [filename, image.get_width(), image.get_height()])
	var path := _out_dir.path_join(filename)
	var err := image.save_png(path)
	if err != OK:
		push_error("STORE_STILLS_FAIL save %s (%s)" % [path, err])
		quit(1)
		return
	print("Wrote %s" % path)

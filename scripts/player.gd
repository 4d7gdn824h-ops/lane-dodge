extends Area2D

signal died

const LANE_COUNT := 3

var lane: int = 1
var lane_xs: Array[float] = []
var target_x: float = 360.0
var slide_speed: float = 16.0
var alive: bool = true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func setup(xs: Array[float], start_lane: int = 1) -> void:
	lane_xs = xs
	lane = clampi(start_lane, 0, LANE_COUNT - 1)
	if lane_xs.is_empty():
		return
	position.x = lane_xs[lane]
	target_x = position.x


func move_left() -> void:
	if not alive or lane_xs.is_empty():
		return
	lane = maxi(lane - 1, 0)
	target_x = lane_xs[lane]


func move_right() -> void:
	if not alive or lane_xs.is_empty():
		return
	lane = mini(lane + 1, LANE_COUNT - 1)
	target_x = lane_xs[lane]


func _process(delta: float) -> void:
	if lane_xs.is_empty():
		return
	position.x = lerpf(position.x, target_x, minf(1.0, slide_speed * delta))


func _on_area_entered(_area: Area2D) -> void:
	if not alive:
		return
	alive = false
	died.emit()

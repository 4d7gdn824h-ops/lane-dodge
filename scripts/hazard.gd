extends Area2D

var speed: float = 360.0


func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > 1400.0:
		queue_free()

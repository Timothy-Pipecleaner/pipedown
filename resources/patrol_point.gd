extends Resource
class_name PatrolPoint

@export var position: Vector2
@export var pause: bool

func _init(position: Vector2 = Vector2.ZERO, pause: bool = false):
	self.position = position
	self.pause = pause

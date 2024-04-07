@tool
extends CharacterBody2D
class_name Enemy

@export_category("Patrol") 
@export var patrol_points: Array[PatrolPoint]
@export var patrol_speed: float
@export var patrol_pause_time: float = 1.0
@onready var initial_position: Vector2 = position
var patrol_index: int = 0
var patrol_paused: bool = false
var patrol_reverse: bool = false

func patrol() -> Vector2:
	if patrol_paused: return Vector2.ZERO
	var patrol_point = patrol_points[patrol_index].position + initial_position
	if position.distance_to(patrol_point) > 10.0: 
		return position.direction_to(patrol_point) * patrol_speed
	else:
		patrol_index = get_next_index()
		patrol_pause()
	return Vector2.ZERO

func patrol_pause() -> void:
	patrol_paused = true
	await get_tree().create_timer(patrol_pause_time).timeout
	patrol_paused = false

func reset_patrol() -> void:
	var sorted_points = patrol_points.duplicate()
	sorted_points.sort_custom(
		func(a: PatrolPoint, b: PatrolPoint):
			return position.distance_to(a.position) < position.distance_to(b.position) 
	)
	patrol_index = patrol_points.find(sorted_points[0])

func get_next_index() -> int:
	if patrol_reverse:
		if patrol_index - 1 < 0:
			patrol_reverse = false
			return patrol_index + 1
		else:
			return patrol_index - 1
	else:
		if patrol_index + 1 >= len(patrol_points):
			patrol_reverse = true
			return patrol_index - 1
		else:
			return patrol_index + 1

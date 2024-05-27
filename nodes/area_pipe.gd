@tool
extends Area2D
class_name AreaPipe

@export var pipe_name: String
@export var spawn_point: Vector2:
	set(value):
		if(Engine.is_editor_hint()):
			queue_redraw()
		spawn_point = value

var has_stepped_away = true
signal pipe_entered(pipe_name: String)

func _enter_tree() -> void:
	if(Engine.is_editor_hint()): return
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(node: Node2D) -> void:
	if(Engine.is_editor_hint()): return
	if has_stepped_away:
		pipe_entered.emit(pipe_name)

func on_body_exited(node: Node2D) -> void:
	if(Engine.is_editor_hint()): return
	if !has_stepped_away:
		has_stepped_away = true

func _draw():
	if(!Engine.is_editor_hint()): return
	draw_circle(spawn_point, 13, Color.WHITE)	
	draw_circle(spawn_point, 12, Color(Color.BLUE_VIOLET, 0.75))

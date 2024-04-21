extends Area2D
class_name AreaPipe

@export var pipe_name: String
var has_stepped_away = true
signal pipe_entered(pipe_name: String)

func _enter_tree() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)

func on_body_entered(node: Node2D) -> void:
	if has_stepped_away:
		pipe_entered.emit(pipe_name)

func on_body_exited(node: Node2D) -> void:
	if !has_stepped_away:
		has_stepped_away = true

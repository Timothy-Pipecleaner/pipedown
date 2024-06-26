extends Node2D
class_name Room

@export var room_name: String
var pipes: Dictionary
var transition_ready = false

signal room_exited(room_name: String, pipe_name: String)

func _notification(what):
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		for child in get_children():
			if child.has_signal("pipe_entered"):
				child.connect("pipe_entered", on_pipe_entered)
				pipes[child.pipe_name] = child

func on_pipe_entered(pipe_name: String):
	room_exited.emit(room_name, pipe_name)

func place(node: Node2D, pipe_name: String):
	node.position = to_local(pipes[pipe_name].to_global(pipes[pipe_name].spawn_point))
	add_child(node)

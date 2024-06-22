extends Area2D
class_name Interactable

signal interacted(interactor: Node2D, direction: Vector2)
signal highlight_changed(highlighted: bool)

func interact(interactor: Node2D = null, direction: Vector2 = Vector2.UP):
	interacted.emit(interactor, direction)

func highlight(enable : bool):
	highlight_changed.emit(enable)

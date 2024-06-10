extends Area2D
class_name Interactable

signal interacted
signal highlight_changed(highlighted: bool)

func interact():
	interacted.emit()

func highlight(enable : bool):
	highlight_changed.emit(enable)

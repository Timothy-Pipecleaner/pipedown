extends Area2D
class_name Interactor

var current_interactable : Interactable

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func interact():
	if current_interactable == null:
		return
	
	current_interactable.interact()

func _on_area_entered(area: Area2D):
	if area is Interactable:
		swap_interactable(area)

func _on_area_exited(area: Area2D):
	if area is Interactable == false:
		return
		
	if area == current_interactable:
		swap_interactable(null)

func swap_interactable(new_interactable):
	if current_interactable != null:
		current_interactable.highlight(false)
	
	current_interactable = new_interactable
	
	if current_interactable != null:
		current_interactable.highlight(true)

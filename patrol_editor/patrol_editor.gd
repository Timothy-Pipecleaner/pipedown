@tool
extends EditorPlugin

var snap_toggle: CheckButton
var snapping = false

var patrol: Patrol = null
var is_dragging = false
var index: int = -1

const HANDLE_SIZE := 15.0

func _enter_tree():
	snap_toggle = CheckButton.new()
	snap_toggle.text = "Snap Patrol Points"
	snap_toggle.toggled.connect(on_snap_toggled)
	
func _handles(object):
	if object is Patrol:
		return true
		
	if object is Node2D:
		var node = object as Node2D
		for child in node.get_children():
			if child is Patrol:
				return true
	return false
	
func _edit(object):
	if object is Patrol:
		patrol = object
		
	if object is Node2D:
		var node = object as Node2D
		for child in node.get_children():
			if child is Patrol:
				patrol = child

	if object == null:
		patrol.draw.disconnect(on_patrol_draw)
		patrol.queue_redraw()
		patrol = null
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
	
	if patrol != null:
		patrol.draw.connect(on_patrol_draw)
		patrol.queue_redraw()
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)		
		

func _forward_canvas_gui_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouse
		if is_dragging:
			if mouse_event.is_released():
				is_dragging = false
				get_undo_redo().add_do_method(patrol, "queue_redraw")
				get_undo_redo().add_do_property(patrol, "patrol_points", patrol.patrol_points.duplicate())
				get_undo_redo().commit_action()
			return true;
		for i in range(0, len(patrol.patrol_points)):
			if patrol.get_local_mouse_position().distance_to(patrol.patrol_points[i]) < HANDLE_SIZE:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_LEFT:
						get_undo_redo().create_action("Change Patrol Positions")
						get_undo_redo().add_undo_method(patrol, "queue_redraw")
						get_undo_redo().add_undo_property(patrol, "patrol_points", patrol.patrol_points.duplicate())
						is_dragging = true;
						index = i
					if event.button_index == MOUSE_BUTTON_RIGHT:
						patrol.patrol_points.remove_at(i)
						patrol.queue_redraw()
					return true
		if !is_dragging && event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
			patrol.patrol_points.append(patrol.get_local_mouse_position())
			patrol.queue_redraw()
			return true
	if event is InputEventMouseMotion:
		patrol.queue_redraw()
		if is_dragging:
			if snapping:
				if patrol.get_local_mouse_position().distance_to(Vector2.ZERO) < 15.0:
					patrol.patrol_points[index] = Vector2.ZERO
					return true
				var x_snapped = false
				var y_snapped = false
				for i in range(0, len(patrol.patrol_points)):
					if i == index: continue
					if !x_snapped && abs(patrol.get_local_mouse_position().x - patrol.patrol_points[i].x) < 100:
						patrol.patrol_points[index].x = patrol.patrol_points[i].x
						if !y_snapped: patrol.patrol_points[index].y = patrol.get_local_mouse_position().y
						patrol.queue_redraw()
						x_snapped = true
					if !y_snapped && abs(patrol.get_local_mouse_position().y - patrol.patrol_points[i].y) < 100:
						if !x_snapped: patrol.patrol_points[index].x = patrol.get_local_mouse_position().x 
						patrol.patrol_points[index].y = patrol.patrol_points[i].y
						patrol.queue_redraw()
						y_snapped = true
				if x_snapped or y_snapped:
					return true
			patrol.patrol_points[index] = patrol.get_local_mouse_position()
	return false

func on_patrol_draw():
	for i in range(0, len(patrol.patrol_points)):
		if i == 0: continue
		patrol.draw_dashed_line(patrol.patrol_points[i], patrol.patrol_points[i - 1], Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)
		
	for point in patrol.patrol_points:
		if patrol.get_local_mouse_position().distance_to(point) < 15.0:
			patrol.draw_circle(point, 16.0, Color.DEEP_SKY_BLUE)
		else:
			patrol.draw_circle(point, HANDLE_SIZE, Color.WHITE)

func on_snap_toggled(state: bool):
	snapping = state

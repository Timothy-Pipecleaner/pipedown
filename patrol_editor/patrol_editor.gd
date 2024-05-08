@tool
extends EditorPlugin

var snap_toggle: CheckButton
var snapping = false

var enemy: Enemy = null
var is_dragging = false
var index: int = -1

const HANDLE_SIZE := 15.0
const HANDLE_HIGHLIGHT_SIZE := 16.0

func _enter_tree():
	snap_toggle = CheckButton.new()
	snap_toggle.text = "Snap Patrol Points"
	snap_toggle.toggled.connect(on_snap_toggled)
	
func _handles(object):
	if object is Enemy:
		return true
	return false
	
func _edit(object):
	if object is Enemy:
		enemy = object

	if object == null:
		enemy.draw.disconnect(on_patrol_draw)
		enemy.queue_redraw()
		enemy = null
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
	
	if enemy != null:
		enemy.draw.connect(on_patrol_draw)
		enemy.queue_redraw()
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)		

func _forward_canvas_gui_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouse
		if is_dragging:
			if mouse_event.is_released():
				is_dragging = false
				get_undo_redo().add_do_method(enemy, "queue_redraw")
				get_undo_redo().add_do_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
				get_undo_redo().commit_action()
			return true;
		for i in range(0, len(enemy.patrol_points)):
			if enemy.get_local_mouse_position().distance_to(enemy.patrol_points[i].position) < HANDLE_SIZE:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_LEFT:
						get_undo_redo().create_action("Change Patrol Positions")
						get_undo_redo().add_undo_method(enemy, "queue_redraw")
						get_undo_redo().add_undo_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
						is_dragging = true;
						index = i
					if event.button_index == MOUSE_BUTTON_RIGHT:
						enemy.patrol_points.remove_at(i)
						enemy.queue_redraw()
					return true
		if !is_dragging && event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
			enemy.patrol_points.append(PatrolPoint.new(enemy.get_local_mouse_position()))
			enemy.queue_redraw()
			return true
	if event is InputEventMouseMotion:
		enemy.queue_redraw()
		if is_dragging:
			if snapping:
				if enemy.get_local_mouse_position().distance_to(Vector2.ZERO) < 15.0:
					enemy.patrol_points[index].position = Vector2.ZERO
					return true
				var x_snapped = false
				var y_snapped = false
				for i in range(0, len(enemy.patrol_points)):
					if i == index: continue
					if !x_snapped && abs(enemy.get_local_mouse_position().x - enemy.patrol_points[i].position.x) < 100:
						enemy.patrol_points[index].position.x = enemy.patrol_points[i].position.x
						if !y_snapped: enemy.patrol_points[index].position.y = enemy.get_local_mouse_position().y
						enemy.queue_redraw()
						x_snapped = true
					if !y_snapped && abs(enemy.get_local_mouse_position().y - enemy.patrol_points[i].position.y) < 100:
						if !x_snapped: enemy.patrol_points[index].position.x = enemy.get_local_mouse_position().x 
						enemy.patrol_points[index].position.y = enemy.patrol_points[i].position.y
						enemy.queue_redraw()
						y_snapped = true
				if x_snapped or y_snapped:
					return true
			enemy.patrol_points[index].position = enemy.get_local_mouse_position()
	return false

func on_patrol_draw():
	for i in range(0, len(enemy.patrol_points)):
		if i == 0: continue
		enemy.draw_dashed_line(enemy.patrol_points[i].position, enemy.patrol_points[i - 1].position, Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)
	
	if enemy.patrol_loop and len(enemy.patrol_points) > 2:
		enemy.draw_dashed_line(enemy.patrol_points[0].position, enemy.patrol_points[-1].position, Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)		
	
	for point in enemy.patrol_points:
		if point.pause:
			if enemy.get_local_mouse_position().distance_to(point.position) < 15.0:
				enemy.draw_rect(Rect2(point.position + Vector2(-HANDLE_HIGHLIGHT_SIZE, -HANDLE_HIGHLIGHT_SIZE), Vector2(HANDLE_HIGHLIGHT_SIZE * 2, HANDLE_HIGHLIGHT_SIZE * 2)), Color.DEEP_SKY_BLUE)
			else:
				enemy.draw_rect(Rect2(point.position + Vector2(-HANDLE_SIZE, -HANDLE_SIZE), Vector2(HANDLE_SIZE * 2, HANDLE_SIZE * 2)), Color.RED)
		else:
			if enemy.get_local_mouse_position().distance_to(point.position) < 15.0:
				enemy.draw_circle(point.position, 16.0, Color.DEEP_SKY_BLUE)
			else:
				enemy.draw_circle(point.position, HANDLE_SIZE, Color.GREEN)

func on_snap_toggled(state: bool):
	snapping = state

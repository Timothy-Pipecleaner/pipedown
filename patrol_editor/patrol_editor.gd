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
		if enemy == object:
			return
			
		if enemy != null and enemy != object:
			enemy.draw.disconnect(on_patrol_draw)
			enemy.queue_redraw()
		
		if enemy == null:
			add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
			
		enemy = object

	if object == null:
		enemy.draw.disconnect(on_patrol_draw)
		enemy.queue_redraw()
		enemy = null
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
	
	if enemy != null:
		enemy.draw.connect(on_patrol_draw)
		enemy.queue_redraw()
		

func _forward_canvas_gui_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouse
		if is_dragging:
			if mouse_event.is_released():
				is_dragging = false
				get_undo_redo().add_do_method(enemy, "queue_redraw")
				get_undo_redo().add_do_property(enemy.patrol_points[index], "position", enemy.patrol_points[index].position)
				get_undo_redo().commit_action()
			return true;
		for i in range(0, len(enemy.patrol_points)):
			if enemy.get_local_mouse_position().distance_to(enemy.patrol_points[i].position) < HANDLE_SIZE:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_LEFT:
						get_undo_redo().create_action("Change Patrol Positions")
						get_undo_redo().add_undo_method(enemy, "queue_redraw")
						get_undo_redo().add_undo_property(enemy.patrol_points[i], "position", enemy.patrol_points[i].position)
						is_dragging = true;
						index = i
					if event.button_index == MOUSE_BUTTON_RIGHT:
						remove_patrol_point_at(i)
					return true
			if i != 0:
				var close_pos = get_closet_position_to_mouse(enemy.patrol_points[i].position, enemy.patrol_points[i - 1].position)
				if valid_split_point(close_pos, enemy.patrol_points[i].position, enemy.patrol_points[i - 1].position):
					if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
						add_patrol_point_at(i, close_pos)
						return true
			else:
				var close_pos = get_closet_position_to_mouse(enemy.patrol_points[0].position, enemy.patrol_points[-1].position)
				if valid_split_point(close_pos, enemy.patrol_points[i].position, enemy.patrol_points[-1].position):
					if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
						add_patrol_point(close_pos, true)
						return true
	
		if !is_dragging && event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
			add_patrol_point(enemy.get_local_mouse_position())
			return true

	if event is InputEventMouseMotion:
		enemy.queue_redraw()
		if is_dragging:
			if snapping:
				if enemy.get_local_mouse_position().distance_to(Vector2.ZERO) < HANDLE_SIZE:
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
		var close_pos = get_closet_position_to_mouse(enemy.patrol_points[i].position, enemy.patrol_points[i - 1].position)
		if valid_split_point(close_pos, enemy.patrol_points[i].position, enemy.patrol_points[i - 1].position):
			enemy.draw_circle(get_closet_position_to_mouse(close_pos, enemy.patrol_points[i - 1].position), HANDLE_SIZE, Color.YELLOW)
	if enemy.patrol_loop and len(enemy.patrol_points) > 2:
		enemy.draw_dashed_line(enemy.patrol_points[0].position, enemy.patrol_points[-1].position, Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)
		var close_pos = get_closet_position_to_mouse(enemy.patrol_points[0].position, enemy.patrol_points[-1].position)
		if valid_split_point(close_pos, enemy.patrol_points[0].position, enemy.patrol_points[-1].position):
			enemy.draw_circle(get_closet_position_to_mouse(close_pos, enemy.patrol_points[-1].position), HANDLE_SIZE, Color.YELLOW)
	
	for point in enemy.patrol_points:
		if point.pause:
			if enemy.get_local_mouse_position().distance_to(point.position) < HANDLE_SIZE:
				enemy.draw_rect(Rect2(point.position + Vector2(-HANDLE_HIGHLIGHT_SIZE, -HANDLE_HIGHLIGHT_SIZE), Vector2(HANDLE_HIGHLIGHT_SIZE * 2, HANDLE_HIGHLIGHT_SIZE * 2)), Color.DEEP_SKY_BLUE)
			else:
				enemy.draw_rect(Rect2(point.position + Vector2(-HANDLE_SIZE, -HANDLE_SIZE), Vector2(HANDLE_SIZE * 2, HANDLE_SIZE * 2)), Color.RED)
		else:
			if enemy.get_local_mouse_position().distance_to(point.position) < HANDLE_SIZE:
				enemy.draw_circle(point.position, HANDLE_HIGHLIGHT_SIZE, Color.DEEP_SKY_BLUE)
			else:
				enemy.draw_circle(point.position, HANDLE_SIZE, Color.GREEN)

func on_snap_toggled(state: bool):
	snapping = state

func add_patrol_point(point: Vector2, grab_point: bool = false):
	get_undo_redo().create_action("Add Patrol Point")
	get_undo_redo().add_undo_method(enemy, "queue_redraw")
	get_undo_redo().add_undo_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
			
	enemy.patrol_points.append(PatrolPoint.new(point))
	enemy.queue_redraw()
	get_undo_redo().add_do_method(enemy, "queue_redraw")
	get_undo_redo().add_do_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
	get_undo_redo().commit_action()
	if grab_point:
		is_dragging = true;
		self.index = index
		get_undo_redo().create_action("Change Patrol Positions")
		get_undo_redo().add_undo_method(enemy, "queue_redraw")
		get_undo_redo().add_undo_property(enemy.patrol_points[index], "position", enemy.patrol_points[index].position)
	

func add_patrol_point_at(index: int, point: Vector2):
	get_undo_redo().create_action("Add Patrol Point")
	get_undo_redo().add_undo_method(enemy, "queue_redraw")
	get_undo_redo().add_undo_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
	enemy.patrol_points.insert(index, PatrolPoint.new(point))
	enemy.queue_redraw()
	get_undo_redo().add_do_method(enemy, "queue_redraw")
	get_undo_redo().add_do_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
	get_undo_redo().commit_action()
	is_dragging = true
	self.index = index
	get_undo_redo().create_action("Change Patrol Positions")
	get_undo_redo().add_undo_method(enemy, "queue_redraw")
	get_undo_redo().add_undo_property(enemy.patrol_points[index], "position", enemy.patrol_points[index].position)
	

func remove_patrol_point_at(index: int):
	get_undo_redo().create_action("Remove Patrol Point")
	get_undo_redo().add_undo_method(enemy, "queue_redraw")
	get_undo_redo().add_undo_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
	
	enemy.patrol_points.remove_at(index)
	enemy.queue_redraw()
	
	get_undo_redo().add_do_method(enemy, "queue_redraw")
	get_undo_redo().add_do_property(enemy, "patrol_points", enemy.patrol_points.duplicate())
	get_undo_redo().commit_action()

func get_closet_position_to_mouse(a: Vector2, b: Vector2) -> Vector2:
	var direction = (b - a).normalized()
	var local_mouse_pos := enemy.get_local_mouse_position() - a
	var distance := direction.dot(local_mouse_pos)

	return a + (distance * direction)

func valid_split_point(point: Vector2, a: Vector2, b: Vector2) -> bool:
	var distance_to_a = point.distance_to(a)
	var distance_to_b = point.distance_to(b)
	var distance_a_to_b = a.distance_to(b)
	return ((point - enemy.get_local_mouse_position()).length() < HANDLE_SIZE
			and distance_to_a < distance_a_to_b
			and distance_to_b < distance_a_to_b
			and enemy.get_local_mouse_position().distance_to(a) > HANDLE_SIZE
			and enemy.get_local_mouse_position().distance_to(b) > HANDLE_SIZE)

@tool
extends EditorPlugin

var snap_toggle: CheckButton
var snapping = false

var edited_object: Node2D = null
var property: String = ""

var is_dragging = false
var index: int = -1

const HANDLE_SIZE := 15.0
const HANDLE_HIGHLIGHT_SIZE := 16.0

func _enter_tree():
	snap_toggle = CheckButton.new()
	snap_toggle.text = "Snap Patrol Points"
	snap_toggle.toggled.connect(on_snap_toggled)
	
func _handles(object):
	if object is Node2D:
		var properties = object.get_property_list()
		for property in properties:
			if property["hint"] and property["hint"] == 23:
				if property["hint_string"].get_slice(":", 1) == "PatrolPoint":
					self.property = property["name"]
					
					return true
	return false
	
func _edit(object):
	if object != null:
		if edited_object == object:
			return
				
		if edited_object != null and edited_object != object:
			edited_object.draw.disconnect(on_patrol_draw)
			edited_object.queue_redraw()
			
		if edited_object == null:
			add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
				
		edited_object = object

	if object == null:
		edited_object.draw.disconnect(on_patrol_draw)
		edited_object.queue_redraw()
		edited_object = null
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_toggle)
	
	if edited_object != null:
		edited_object.draw.connect(on_patrol_draw)
		edited_object.queue_redraw()
		

func _forward_canvas_gui_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouse
		if is_dragging:
			if mouse_event.is_released():
				is_dragging = false
				get_undo_redo().add_do_method(edited_object, "queue_redraw")
				get_undo_redo().add_do_property(edited_object.get(property)[index], "position", edited_object.get(property)[index].position)
				get_undo_redo().commit_action()
			return true;
		for i in range(0, len(edited_object.get(property))):
			if edited_object.get_local_mouse_position().distance_to(edited_object.get(property)[i].position) < HANDLE_SIZE:
				if event.is_pressed():
					if event.button_index == MOUSE_BUTTON_LEFT:
						get_undo_redo().create_action("Change Patrol Positions")
						get_undo_redo().add_undo_method(edited_object, "queue_redraw")
						get_undo_redo().add_undo_property(edited_object.get(property)[i], "position", edited_object.get(property)[i].position)
						is_dragging = true;
						index = i
					if event.button_index == MOUSE_BUTTON_RIGHT:
						remove_patrol_point_at(i)
					return true
			if i != 0:
				var close_pos = get_closet_position_to_mouse(edited_object.get(property)[i].position, edited_object.get(property)[i - 1].position)
				if valid_split_point(close_pos, edited_object.get(property)[i].position, edited_object.get(property)[i - 1].position):
					if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
						add_patrol_point_at(i, close_pos)
						return true
			else:
				var close_pos = get_closet_position_to_mouse(edited_object.get(property)[0].position, edited_object.get(property)[-1].position)
				if valid_split_point(close_pos, edited_object.get(property)[i].position, edited_object.get(property)[-1].position):
					if event.is_pressed() && event.button_index == MOUSE_BUTTON_LEFT:
						add_patrol_point(close_pos, true)
						return true
	
		if !is_dragging && event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
			add_patrol_point(edited_object.get_local_mouse_position())
			return true

	if event is InputEventMouseMotion:
		edited_object.queue_redraw()
		if is_dragging:
			if snapping:
				if edited_object.get_local_mouse_position().distance_to(Vector2.ZERO) < HANDLE_SIZE:
					edited_object.get(property)[index].position = Vector2.ZERO
					return true
				var x_snapped = false
				var y_snapped = false
				for i in range(0, len(edited_object.get(property))):
					if i == index: continue
					if !x_snapped && abs(edited_object.get_local_mouse_position().x -edited_object.get(property)[i].position.x) < 100:
						edited_object.get(property)[index].position.x = edited_object.get(property)[i].position.x
						if !y_snapped: edited_object.get(property)[index].position.y = edited_object.get_local_mouse_position().y
						edited_object.queue_redraw()
						x_snapped = true
					if !y_snapped && abs(edited_object.get_local_mouse_position().y - edited_object.get(property)[i].position.y) < 100:
						if !x_snapped: edited_object.get(property)[index].position.x = edited_object.get_local_mouse_position().x 
						edited_object.get(property)[index].position.y = edited_object.get(property)[i].position.y
						edited_object.queue_redraw()
						y_snapped = true
				if x_snapped or y_snapped:
					return true
			edited_object.get(property)[index].position = edited_object.get_local_mouse_position()
	return false

func on_patrol_draw():
	for i in range(0, len(edited_object.get(property))):
		if i == 0: continue
		edited_object.draw_dashed_line(edited_object.get(property)[i].position, edited_object.get(property)[i - 1].position, Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)
		var close_pos = get_closet_position_to_mouse(edited_object.get(property)[i].position, edited_object.get(property)[i - 1].position)
		if valid_split_point(close_pos, edited_object.get(property)[i].position, edited_object.get(property)[i - 1].position):
			edited_object.draw_circle(get_closet_position_to_mouse(close_pos, edited_object.get(property)[i - 1].position), HANDLE_SIZE, Color.YELLOW)
	if edited_object.patrol_loop and len(edited_object.get(property)) > 2:
		edited_object.draw_dashed_line(edited_object.get(property)[0].position, edited_object.get(property)[-1].position, Color.WHITE, HANDLE_SIZE * (2.0/3.0), 50.0, true)
		var close_pos = get_closet_position_to_mouse(edited_object.get(property)[0].position, edited_object.get(property)[-1].position)
		if valid_split_point(close_pos, edited_object.get(property)[0].position, edited_object.get(property)[-1].position):
			edited_object.draw_circle(get_closet_position_to_mouse(close_pos, edited_object.get(property)[-1].position), HANDLE_SIZE, Color.YELLOW)
	
	for point in edited_object.get(property):
		if point.pause:
			if edited_object.get_local_mouse_position().distance_to(point.position) < HANDLE_SIZE:
				edited_object.draw_rect(Rect2(point.position + Vector2(-HANDLE_HIGHLIGHT_SIZE, -HANDLE_HIGHLIGHT_SIZE), Vector2(HANDLE_HIGHLIGHT_SIZE * 2, HANDLE_HIGHLIGHT_SIZE * 2)), Color.DEEP_SKY_BLUE)
			else:
				edited_object.draw_rect(Rect2(point.position + Vector2(-HANDLE_SIZE, -HANDLE_SIZE), Vector2(HANDLE_SIZE * 2, HANDLE_SIZE * 2)), Color.RED)
		else:
			if edited_object.get_local_mouse_position().distance_to(point.position) < HANDLE_SIZE:
				edited_object.draw_circle(point.position, HANDLE_HIGHLIGHT_SIZE, Color.DEEP_SKY_BLUE)
			else:
				edited_object.draw_circle(point.position, HANDLE_SIZE, Color.GREEN)

func on_snap_toggled(state: bool):
	snapping = state

func add_patrol_point(point: Vector2, grab_point: bool = false):
	get_undo_redo().create_action("Add Patrol Point")
	get_undo_redo().add_undo_method(edited_object, "queue_redraw")
	get_undo_redo().add_undo_property(edited_object, property, edited_object.get(property).duplicate())
			
	edited_object.get(property).append(PatrolPoint.new(point))
	edited_object.queue_redraw()
	get_undo_redo().add_do_method(edited_object, "queue_redraw")
	get_undo_redo().add_do_property(edited_object, property, edited_object.get(property).duplicate())
	get_undo_redo().commit_action()
	if grab_point:
		is_dragging = true;
		self.index = index
		get_undo_redo().create_action("Change Patrol Positions")
		get_undo_redo().add_undo_method(edited_object, "queue_redraw")
		get_undo_redo().add_undo_property(edited_object.get(property)[index], "position", edited_object.get(property)[index].position)
	

func add_patrol_point_at(index: int, point: Vector2):
	get_undo_redo().create_action("Add Patrol Point")
	get_undo_redo().add_undo_method(edited_object, "queue_redraw")
	get_undo_redo().add_undo_property(edited_object, property, edited_object.get(property).duplicate())
	edited_object.get(property).insert(index, PatrolPoint.new(point))
	edited_object.queue_redraw()
	get_undo_redo().add_do_method(edited_object, "queue_redraw")
	get_undo_redo().add_do_property(edited_object, property, edited_object.get(property).duplicate())
	get_undo_redo().commit_action()
	is_dragging = true
	self.index = index
	get_undo_redo().create_action("Change Patrol Positions")
	get_undo_redo().add_undo_method(edited_object, "queue_redraw")
	get_undo_redo().add_undo_property(edited_object.get(property)[index], "position", edited_object.get(property)[index].position)
	

func remove_patrol_point_at(index: int):
	get_undo_redo().create_action("Remove Patrol Point")
	get_undo_redo().add_undo_method(edited_object, "queue_redraw")
	get_undo_redo().add_undo_property(edited_object, property, edited_object.get(property).duplicate())
	
	edited_object.get(property).remove_at(index)
	edited_object.queue_redraw()
	
	get_undo_redo().add_do_method(edited_object, "queue_redraw")
	get_undo_redo().add_do_property(edited_object, property, edited_object.get(property).duplicate())
	get_undo_redo().commit_action()

func get_closet_position_to_mouse(a: Vector2, b: Vector2) -> Vector2:
	var direction = (b - a).normalized()
	var local_mouse_pos := edited_object.get_local_mouse_position() - a
	var distance := direction.dot(local_mouse_pos)

	return a + (distance * direction)

func valid_split_point(point: Vector2, a: Vector2, b: Vector2) -> bool:
	var distance_to_a = point.distance_to(a)
	var distance_to_b = point.distance_to(b)
	var distance_a_to_b = a.distance_to(b)
	return ((point - edited_object.get_local_mouse_position()).length() < HANDLE_SIZE
			and distance_to_a < distance_a_to_b
			and distance_to_b < distance_a_to_b
			and edited_object.get_local_mouse_position().distance_to(a) > HANDLE_SIZE
			and edited_object.get_local_mouse_position().distance_to(b) > HANDLE_SIZE)

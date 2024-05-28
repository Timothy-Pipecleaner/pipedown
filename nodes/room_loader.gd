extends Node2D
class_name RoomLoader

@export var room_map: RoomMap

func load_next_room(old_room: String, pipe_name: String = '') -> Dictionary:
	var room_info: RoomMapItem = room_map.get_map_item(old_room)
	if room_info == null:
		return {}
	var pipe_info: RoomMapPipe = room_info.get_pipe_data(pipe_name)
	if pipe_info == null:
		return {}
	var next_room_info: RoomMapItem = room_map.get_map_item(pipe_info.next_scene_name)
	if next_room_info == null:
		return {}
	var next_room = load(next_room_info.room_scene).instantiate()
	return {
		'room': next_room, 
		'pipe_name': pipe_info.next_pipe_name,
	}
	
func load_room(room_name: String) -> Room:
	var room_info: RoomMapItem = room_map.get_map_item(room_name)
	if room_info == null:
		return null
	var room = load(room_info.room_scene).instantiate()
	return room

extends Resource
class_name RoomMapItem

@export var room_name: String
@export_file('*.tscn') var room_scene: String
@export var pipes: Array[RoomMapPipe]

func get_pipe_data(pipe_name: String) -> RoomMapPipe:
	var matching_pipes = pipes.filter(func(x: RoomMapPipe): return x.pipe_name == pipe_name)	
	if len(matching_pipes) == 0: 
		return null
	return matching_pipes[0]

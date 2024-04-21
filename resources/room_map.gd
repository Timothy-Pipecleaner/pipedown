extends Resource
class_name RoomMap

@export var items: Array[RoomMapItem]

func get_map_item(room_name: String):
	var matching_items = items.filter(func(x: RoomMapItem): return x.room_name == room_name)
	if len(matching_items) == 0: 
		return null
	return matching_items[0]

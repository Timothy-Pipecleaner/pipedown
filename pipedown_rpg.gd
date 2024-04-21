@tool
extends EditorPlugin


func _enable_plugin():
	add_custom_type("PatrolPoint", "Resource", preload("res://addons/pipedown_rpg/resources/patrol_point.gd"), preload("res://icon.svg"))
	add_custom_type("Room", "Node2D", preload("./nodes/room.gd"), null)
	add_custom_type("AreaPipe", "Area", preload("./nodes/area_pipe.gd"), null)
	add_custom_type("RoomLoader", "Node2D", preload("./nodes/room_loader.gd"), null)
	EditorInterface.set_plugin_enabled("pipedown_rpg/patrol_editor", true)

func _disable_plugin():
	remove_custom_type("PatrolPoint")
	remove_custom_type("Room")
	remove_custom_type("AreaPipe")
	remove_custom_type("RoomLoader")
	EditorInterface.set_plugin_enabled("pipedown_rpg/patrol_editor", false)
	
func _enter_tree():
	# Initialization of the plugin goes here.
	pass

func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

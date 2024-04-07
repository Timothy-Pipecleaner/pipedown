@tool
extends EditorPlugin


func _enable_plugin():
	EditorInterface.set_plugin_enabled("pipedown_rpg/patrol_editor", true)

func _disable_plugin():
	EditorInterface.set_plugin_enabled("pipedown_rpg/patrol_editor", false)
	
func _enter_tree():
	# Initialization of the plugin goes here.
	pass

func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

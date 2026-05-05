extends Control

func _on_return_pressed():
	# This sends the player back to the Main Menu.
	get_tree().change_scene_to_file("res://main_menu.tscn")

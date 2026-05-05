extends Control

func _on_return_pressed():
	# This deletes the settings menu entirely.
	# Whatever menu was behind it will instantly be visible again!
	queue_free()

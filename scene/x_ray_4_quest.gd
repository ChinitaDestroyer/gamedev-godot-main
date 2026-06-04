extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Type the EXACT name of Note 2's quest inside the quotes
		Global.complete_quest("Reach X-ray 4 room")
		queue_free() # Deletes the trigger so it only fires once

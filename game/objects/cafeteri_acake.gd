extends StaticBody3D

func interact() -> void:
	print("you ate me")
	queue_free()

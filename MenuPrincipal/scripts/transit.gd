extends CanvasLayer

var new_path: NodePath

func fade(path):
	new_path = path
	$anima.play("fade")
	pass

func mudar_cena():
	get_tree().change_scene(new_path)
	


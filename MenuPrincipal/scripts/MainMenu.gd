extends Node



func _on_btn_start_pressed() -> void:
	TRANSIT.fade("res://Levels/Level1.tscn")
	$Audio/sfx.stop()


func _on_btn_quit_pressed() -> void:
	get_tree().quit()

extends Node

func _on_btn_menu_pressed() -> void:
	TRANSIT.fade("res://MenuPrincipal/MainMenu.tscn")


func _on_Walktalk_body_entered(body: Node) -> void:
	TRANSIT.fade("res://Levels/Level2.tscn")

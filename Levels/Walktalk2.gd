extends Area2D

func _ready():
	$AnimatedSprite.play("idle")

func _on_Walktalk_body_entered(body: Node) -> void:
	TRANSIT.fade("res://Levels/Level3.tscn")




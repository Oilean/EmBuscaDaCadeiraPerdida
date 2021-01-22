extends Area2D

const SPEED = 500

onready var killTimer = $KillTimer
onready var sprite = $Sprite

export var damage = 1

var velocity = Vector2.ZERO
var direction = 1
var enemies = ["Bat", "GreenSnake", "Minotaur", "PinkBat", "AxeSkeleton", "Snake", "SwordSkeleton"]

func _ready():
	killTimer.start()

func _physics_process(delta):
	velocity.x = SPEED * delta * 2 * direction
	translate(velocity)

#direção da animação da bala
func bullet_direction(dir):
	direction = dir
	if dir >= 0:
		$Sprite.flip_h == false
	else:
		$Sprite.flip_h == true

# Signal Functions
# após x tempo a bala desaparece
func _on_KillTimer_timeout():
	queue_free()
# destroi a bala e inicia a função de morte do inimigo
func _on_Bullet_body_entered(body):
	queue_free()
# verifica se o corpo que colidiu é um inimigo para chamar a função de morte do inimigo
func _on_Area2D_body_entered(body):
	for i in enemies:
		if i in body.name:
			body.death()
	queue_free()

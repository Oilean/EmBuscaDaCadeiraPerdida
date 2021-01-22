extends KinematicBody2D

onready var animatedSprite = $AnimatedSprite
onready var collisionShape = $CollisionShape2D
onready var attackAreaCS = $AttackArea/CollisionShape2D
onready var rightWall = $RightWall
onready var leftWall = $LeftWall
onready var floorRight = $FloorRight
onready var floorLeft = $FloorLeft
onready var platformDetector = $PlatformDetector
onready var timer = $Timer
onready var player = Utils.get_main_node().get_node("Player")

var speed = 80
var initial_health = 6
var damage = 2
var follow_range = 100 # distância que poderá seguir jogador
var change_direction_ease = 1 # faz com que inimigo tenha um pequeno delay na hora de mudar de direção
var direction_smooth = 1 # suaviza a mudança de direção
var velocity = Vector2.ZERO
var is_following_player = false
var direction = 1
var in_attack_range = false
var player_distance : float
var current_health : int
var is_dead = false

func _ready():
	current_health = initial_health

func _physics_process(delta):
	if not is_dead:
		animation()
		player_distance = player.get_position().x - get_position().x # pega a distância entre personagem e jogador
		direction_smooth += (direction - direction_smooth) * delta * change_direction_ease 
		velocity.x = 1 * direction_smooth
		# altera o lado em que a sprite está olhando
		if velocity.x > 0:
			animatedSprite.flip_h = true
			if sign(attackAreaCS.position.x) < 0:
				attackAreaCS.position.x *= -1
		else:
			animatedSprite.flip_h = false
			if sign(attackAreaCS.position.x) > 0:
				attackAreaCS.position.x *= -1
		# verifica se jogador está dentro da distância para poder segui-lo
		if abs(player_distance) < follow_range:
			is_following_player = true
		else: 
			is_following_player = false
		# determina posição relativa ao jogador para segui-lo
		if is_following_player:
			if player_distance < 0:
				direction = -1
				# se possuir um buraco no caminho entre personagem e jogador, personagem irá parar de seguir o jogador
				if not floorRight.is_colliding():
					is_following_player = false
				if not floorLeft.is_colliding():
					is_following_player = false
			else:
				direction = 1
				if not floorRight.is_colliding():
					is_following_player = false
				if not floorLeft.is_colliding():
					is_following_player = false
		else:
			direction_smooth = direction
		# raycast da parede direita
		if rightWall.is_colliding():
			var collision_object = rightWall.get_collider()
			if not collision_object.is_in_group(Constants.PLAYER_GROUP):
				if not is_following_player:
					direction = -1
		# raycast da parede esquerda
		if leftWall.is_colliding():
			var collision_object = leftWall.get_collider()
			if not collision_object.is_in_group(Constants.PLAYER_GROUP):
				if not is_following_player:
					direction = 1
		# verifica se há um buraco a direita para retornar
		if not is_following_player:
			if not floorRight.is_colliding():
				direction = -1
		# verifica se há um buraco a esquerda para retornar		
		if not is_following_player:
			if not floorLeft.is_colliding():
				direction = 1
		
		velocity.x *= speed
		
		velocity.y += Constants.GRAVITY * delta
		#snap vector
		var snap_vector = Vector2.DOWN * Constants.FLOOR_DETECT_DISTANCE if velocity.y == 0 else Vector2.ZERO
		var is_on_platform = platformDetector.is_colliding()
		
		velocity = move_and_slide_with_snap(
			velocity, snap_vector, Constants.FLOOR_NORMAL, not is_on_platform, Constants.MAX_SLIDES, Constants.FLOOR_MAX_ANGLE, false
		)

func death():
	current_health -= 1
	if current_health <= 0:
		is_dead = true
#		collisionShape.disabled = true
#		attackAreaCS.disabled = true
		animatedSprite.play("death")
		$Audio/AudioStreamPlayer.play()
		velocity = Vector2.ZERO
		timer.start()



# Animation Functions
func _attack():
	if not is_dead:
		if in_attack_range:
			player.hit(damage, direction)

func animation():
	if velocity.x != 0:
		animatedSprite.play("run")
	elif velocity.x == 0:
		animatedSprite.play("idle")

# Signal Functions
func _on_AttackArea_body_entered(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = true
		_attack()

func _on_AttackArea_body_exited(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = false

func _on_Timer_timeout():
	queue_free()




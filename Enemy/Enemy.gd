extends KinematicBody2D

onready var animatedSprite = $AnimatedSprite
onready var attackArea = $AttackArea
onready var rightWall = $RightWall
onready var leftWall = $LeftWall
onready var floorRight = $FloorRight
onready var floorLeft = $FloorLeft
onready var platformDetector = $PlatformDetector
onready var timer = $Timer
onready var player = Utils.get_main_node().get_node("Player")

export var speed : int
export var jump_force : int
export var initial_health : int
export var damage : int
export var launch_power : int # quanto é jogado para trás caso seja acertado
export var recovery_time : int # tempo de recuperação após ser atacado
export var follow_range: int # distância que poderá seguir jogador
export var change_direction_ease : int # faz com que inimigo tenha um pequeno delay na hora de mudar de direção
export var direction_smooth : int # suaviza a mudança de direção

var velocity = Vector2.ZERO
var launch = 1
var is_recovering = false
var recovery_counter = 0
var is_following_player = false
var direction = 1
var in_attack_range = false
var player_distance : float
var current_health : int
var is_dead = false

func _ready():
	current_health = initial_health

func _physics_process(delta):
	if not is_recovering:
		player_distance = player.get_position().x - get_position().x # pega a distância entre personagem e jogador
		direction_smooth += (direction - direction_smooth) * delta * change_direction_ease 
		velocity.x = 1 * direction_smooth
		# altera o lado em que a sprite está olhando
		if velocity.x > 0:
			animatedSprite.flip_h = true
		else:
			animatedSprite.flip_h = false
		# verifica se jogador está dentro da distância para poder segui-lo
		if abs(player_distance) < follow_range:
			is_following_player = true
		else: 
			is_following_player = false
		# determina posição relativa ao jogador para segui-lo
		if is_following_player:
			if player_distance < 0:
				direction = -1
			else:
				direction = 1
		else:
			direction_smooth = direction
		# raycast da parede direita
		if rightWall.is_colliding():
			var collision_object = rightWall.get_collider()
			if not collision_object.is_in_group(Constants.PLAYER_GROUP):
				if not is_following_player:
					direction = -1
				else:
					if not collision_object.is_in_group(Constants.ENEMY_GROUP):
						jump()
		# raycast da parede esquerda
		if leftWall.is_colliding():
			var collision_object = leftWall.get_collider()
			if not collision_object.is_in_group(Constants.PLAYER_GROUP):
				if not is_following_player:
					direction = 1
				else:
					if not collision_object.is_in_group(Constants.ENEMY_GROUP):
						jump()
		# verifica se há um buraco a direita para retornar
		if not is_following_player:
			if not floorRight.is_colliding():
				direction = -1
		# verifica se há um buraco a esquerda para retornar		
		if not is_following_player:
			if not floorLeft.is_colliding():
				direction = 1
		# attack
		if in_attack_range:
			animatedSprite.play("attack")
		
		velocity.x *= speed
	
	else:
		# se estiver se recuperando de um ataque
		recovery_counter += delta # verifica quanto tempo está se recuperando
		velocity.x = launch 
		launch += (0 - launch) * delta # reduz o knockback aos poucos
		# verifica se está se recuperando a mais tempo que o programado
		if recovery_counter >= recovery_time:
			recovery_counter = 0
			velocity.x = 0
			is_recovering = false
	
	velocity.y += Constants.GRAVITY * delta
	#snap vector
	var snap_vector = Vector2.DOWN * Constants.FLOOR_DETECT_DISTANCE if velocity.y == 0 else Vector2.ZERO
	var is_on_platform = platformDetector.is_colliding()
	
	velocity = move_and_slide_with_snap(
		velocity, snap_vector, Constants.FLOOR_NORMAL, not is_on_platform, Constants.MAX_SLIDES, Constants.FLOOR_MAX_ANGLE, false
	)
# apenas usar se personagem puder pular
func jump():
	if is_on_floor():
		velocity.y = jump_force

func hit(damage, attack_direction):
	current_health -= damage
	velocity.x = -launch_power
	launch = launch_power * attack_direction
	recovery_counter = 0
	is_recovering = true
	
	if current_health <= 0:
		death()

func death():
	animatedSprite.play("death")
	velocity = Vector2.ZERO
	timer.start()
	queue_free()


# Animation Functions
func attack():
	if in_attack_range:
		player.hit(damage, direction)
		animatedSprite.play("attack")


# Signal Functions
func _on_AttackArea_body_entered(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = true
		attack()

func _on_AttackArea_body_exited(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = false


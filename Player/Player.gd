extends KinematicBody2D

export var speed = 200
export var jump_force = -270
export var launch_power = 120
export var recovery_time = 0.5

onready var animatedSprite = $AnimatedSprite
onready var shadowSprite = $ShadowSprite
onready var endOfGun = $EndOfGun
onready var collisionShape = $CollisionShape2D
onready var platform_detector = $PlatformDetector

const BULLET = preload("res://Player/Bullet/Bullet.tscn")

var velocity = Vector2()
var gravity = 1000
var launch = 1
var direction = 1
var is_recovering = false
var recovery_count = 0
var is_climb: bool
var is_attacking = false
var is_dead = false
var stats = PlayerStats

func _ready():
	stats.connect("no_health", self, "queue_free")

func _physics_process(delta):
	if not is_dead:
		animation()
		# calculo de velocidade x e y
		# gravidade na direção vertical
		velocity.y += gravity * delta
		
		if not is_recovering:
			# pega força do input de direção horizontal
			var horizontal_direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
			# determinar a direção do personagem e atualiza seu ponto de vista
			if horizontal_direction > 0:
				direction = 1
				animatedSprite.flip_h = false
				if sign(endOfGun.position.x) < 0:
					endOfGun.position.x *= -1
			elif horizontal_direction < 0:
				direction = -1
				animatedSprite.flip_h = true
				if sign(endOfGun.position.x) > 0:
					endOfGun.position.x *= -1
					
			velocity.x = horizontal_direction * speed
			
			$up.cast_to = Vector2(velocity.x / 8, 0)
			$dw.cast_to = Vector2(velocity.x / 8, 0)
			
			# realiza a ação de pulo se estiver no chão
			if Input.is_action_just_pressed("jump"):
				if is_on_floor() or is_climb:
					velocity.y = jump_force
			
		else:
			# se estiver se recuperando de dano
			recovery_count += delta
			velocity.x = launch
			launch += (0 - launch) * delta
			
			if recovery_count >= recovery_time:
				velocity.x = 0
				recovery_count = 0
				is_recovering = false
		
		var snap_vector = Vector2.DOWN * Constants.FLOOR_DETECT_DISTANCE if velocity.y == 0 else Vector2.ZERO
		var is_on_platform = platform_detector.is_colliding()
		
		velocity = move_and_slide_with_snap(
			velocity, snap_vector, Constants.FLOOR_NORMAL, not is_on_platform, Constants.MAX_SLIDES, Constants.FLOOR_MAX_ANGLE, false
		)
		
		animation()
		climb()
		
		if not is_climb:
			if Input.is_action_just_pressed("attack"):
				shoot()

# agarrar em uma ledge
func climb():
	is_climb = ($dw.is_colliding() == true and $up.is_colliding() == false)
	if is_climb:
		velocity.y = 0
		gravity = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y += jump_force
	else:
		velocity.y = velocity.y
		gravity = 500

func shoot():
	var bulletInstace = BULLET.instance() #instancia a bala
	bulletInstace.bullet_direction(sign(endOfGun.position.x))
	
	get_parent().add_child(bulletInstace) 
	bulletInstace.position = endOfGun.global_position

func hit(damage, attack_direction):
	stats.health -= damage
	velocity.y = -launch_power 
	launch = launch_power * attack_direction
	
	recovery_count = 0
	is_recovering = true
	
	if stats.health <= 0:
		is_dead = true
		death()

func death():
	print("Player has died! Game Over!")
	hide()
	#voltar pra tela inicial caso personagem morra
	#get_tree().change_scene("Nomedatela.tscn")

# Animation Functions
func animation():
	if is_climb:
		animatedSprite.play("ledgegrab")
		
	else:
		if Input.is_action_just_pressed("attack"):
			is_attacking = true
			animatedSprite.play("attack")
			$Audio/AudioStreamPlayer.play()
		else:
			if is_on_floor():
				if velocity.x != 0:
					animatedSprite.play("run")
				if velocity.x == 0:
					animatedSprite.play("idle")
				shadowSprite.visible = true
			
			else:
				if Input.is_action_pressed("jump"):
					animatedSprite.play("jump")
				
				if velocity.y <= 85 and velocity.y >= -85:
					animatedSprite.play("midair")
				elif velocity.y > 86:
					animatedSprite.play("landing")
				shadowSprite.hide()





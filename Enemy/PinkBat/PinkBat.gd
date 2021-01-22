extends KinematicBody2D

onready var playerDetectionZone = $PlayerDetectionZone
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animatedSprite = $AnimatedSprite
onready var collisionShape = $CollisionShape2D
onready var attackAreaCS = $AttackArea/CollisionShape2D
onready var timer = $Timer
onready var player = Utils.get_main_node().get_node("Player")

const WANDER_POSITION = 2

enum{
	IDLE,
	WANDER,
	CHASE
}

var initial_health = 6
var current_health : int
var damage = 1
var follow_range = 100 # distância que poderá seguir jogador
var change_direction_ease = 1 # faz com que inimigo tenha um pequeno delay na hora de mudar de direção
var direction_smooth = 1 # suaviza a mudança de direção
var state = CHASE
var direction = 1
var is_dead = false
var velocity = Vector2.ZERO
var speed = 100
var acceleration = 500
var in_attack_range = false

func _ready():
	current_health = initial_health
	state = pick_state([IDLE, WANDER])

func _physics_process(delta):
	if not is_dead:
		animation()
		match state:
			IDLE:
				velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)
				seek_player()
				
				if wanderController.time_left() == 0:
					update_wander()
			
			WANDER:
				seek_player()
				
				if wanderController.time_left() == 0:
					update_wander()
				
				accelerate_towards_point(wanderController.target_position, delta)
				
				if global_position.distance_to(wanderController.target_position) <= WANDER_POSITION:
					update_wander()
			
			CHASE:
				var player = playerDetectionZone.player
				if player != null:
					accelerate_towards_point(player.global_position, delta)
				else:
					state = IDLE
		
		if softCollision.is_colliding():
			velocity += softCollision.get_push_vector() * delta * 2000
		
		velocity = move_and_slide(velocity)

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func update_wander():
	state = pick_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 2))

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * speed, acceleration * delta)

func pick_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func death():
	current_health -= 1
	if current_health <= 0:
		is_dead = true
#		collisionShape.disabled = true
#		attackAreaCS.disabled = true
		animatedSprite.play("death")
		velocity = Vector2.ZERO
		timer.start()


# Animation Functions
func attack():
	if not is_dead:
		if in_attack_range:
			player.hit(damage, direction)

func animation():
	if velocity.x > 0: 
		animatedSprite.flip_h = false
		if sign(attackAreaCS.position.x) < 0:
			attackAreaCS.position.x *= -1
	if velocity.x < 0: 
		animatedSprite.flip_h = true
		if sign(attackAreaCS.position.x) > 0:
			attackAreaCS.position.x *= -1
	
	animatedSprite.play("run")


# Signal Funtions
func _on_AttackArea_body_entered(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = true
		attack()

func _on_AttackArea_body_exited(body):
	if body.is_in_group(Constants.PLAYER_GROUP):
		in_attack_range = false


func _on_Timer_timeout():
	queue_free()

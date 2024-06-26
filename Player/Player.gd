extends CharacterBody2D

@export var MAX_SPEED = 120
@export var ROLL_SPEED = 180
@export var ACCELERATION = 3500
@export var FRICTION = 1500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var roll_vector = Vector2.DOWN
var stats = PlayerStats

const PlayerHurtSound = preload("res://player_hurt_sound.tscn")

@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var hurtbox = $Hurtbox

# Called when the node enters the scene tree for the first time.
func _ready():
	stats.connect("no_health", Callable(self, "queue_free"))
	animation_tree.active = true

func _process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state(delta)
		ATTACK:
			attack_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		animation_tree.set("parameters/Idle/blend_position", input_vector)
		animation_tree.set("parameters/Run/blend_position", input_vector)
		animation_tree.set("parameters/Attack/blend_position", input_vector)
		animation_tree.set("parameters/Roll/blend_position", input_vector)
		animation_state.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animation_state.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, delta * FRICTION)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK
	
func roll_state(delta):
	velocity = ROLL_SPEED * roll_vector
	animation_state.travel("Roll")
	move_and_slide()
	
func attack_state(delta):
	velocity = Vector2.ZERO
	animation_state.travel("Attack")
	
func attack_animation_finished():
	state = MOVE
	
func roll_animation_finished():
	state = MOVE


func _on_hurtbox_area_entered(area):
	stats.health -= 1
	hurtbox.start_invincibility(0.5)
	hurtbox.create_hit_effect()
	var player_hurt_sound = PlayerHurtSound.instantiate()
	get_tree().current_scene.add_child(player_hurt_sound)

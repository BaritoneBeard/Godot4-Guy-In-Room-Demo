class_name Player
extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -400.0

var state = null : set = set_state, get = get_state
var previous_state = null
var states = {}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimationPlayer

func _apply_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
		
func _handle_move_input():
	# Handle Jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("ui_down") and not is_on_floor():
		velocity.y = -JUMP_VELOCITY
		
func _apply_movement():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction == -1:
		get_node("AnimatedSprite2D").flip_h = true
	elif direction == 1:
		get_node("AnimatedSprite2D").flip_h = false
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
		

func _ready():
	add_state('idle')
	add_state('run')
	add_state('jump')
	add_state('fall')
	call_deferred('set_state', states.idle)
	
	
func _state_logic(delta):
	_handle_move_input()
	_apply_gravity(delta)
	_apply_movement()
	
	
func _get_transition(delta):
	match state:
		states.idle:
			if !is_on_floor():
				if velocity.y < 0:
					return states.jump
				elif velocity.y > 0:
					return states.fall
			elif velocity.x != 0:
				return states.run
		states.run:
			print(velocity.x)
			if !is_on_floor():
				if velocity.y < 0:
					return states.jump
				elif velocity.y > 0:
					return states.fall
			elif velocity.x == 0:
				return states.idle
		states.jump:
			if is_on_floor():
				return states.idle
			elif velocity.y >= 0:
				return states.fall
		states.fall:
			if is_on_floor():
				return states.idle
			elif velocity.y < 0:
				return states.jump
				
	return null
				
				
func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			anim.play('Idle')
		states.run:
			anim.play('Run')
		states.jump:
			anim.play('Jump')
		states.fall:
			anim.play('Fall')
	

func _exit_state(old_state, new_state):
	pass


func _physics_process(delta):
	if state != null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)
			

func get_state():
	return state
		
		
func set_state(new_state):
	previous_state = state
	state = new_state
	
	if previous_state != null:
		_exit_state(previous_state, new_state)
	if new_state != null:
		_enter_state(new_state, previous_state)
	
	
func add_state(state_name):
	states[state_name] = states.size()
	

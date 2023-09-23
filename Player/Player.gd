class_name Player
extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const WALL_JUMP_VELOCITY = Vector2(SPEED/2, JUMP_VELOCITY)

var state = null : set = set_state, get = get_state
var previous_state = null
var states = {}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.5
var wall_direction = 1
var move_direction

@onready var anim = $AnimationPlayer
@onready var label = $Label
@onready var sprite = get_node("AnimatedSprite2D")

@onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
@onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts

@onready var wall_slide_cooldown = $WallSlideCooldown
@onready var wall_slide_sticky_timer = $WallSlideStickyTimer

func _apply_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
func _cap_gravity_wall_slide():
	# adjust
	var max_velocity = 150 if !Input.is_action_pressed('ui_down') else 400
	velocity.y = min(velocity.y, max_velocity)
	
func _handle_wall_slide_sticking():
	if move_direction != 0 && move_direction != wall_direction:
		if wall_slide_sticky_timer.is_stopped():
			wall_slide_sticky_timer.start()
		else:
			wall_slide_sticky_timer.stop()
	
func _jump():
	velocity.y = JUMP_VELOCITY
	
func _fast_fall():
	velocity.y = -JUMP_VELOCITY
	
func _wall_jump():
	var wall_jump_velocity = WALL_JUMP_VELOCITY
	wall_jump_velocity.x *= -wall_direction
	velocity = wall_jump_velocity

func _on_WallSlideStickTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)	
	
func _handle_move_input():
	# Handle Jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		_jump()
		
	if Input.is_action_just_pressed("ui_down") and not is_on_floor():
		_fast_fall()
		
func _update_move_direction():
	move_direction = Input.get_axis("ui_left", "ui_right")		

func _apply_movement():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	

	if move_direction == -1:
		sprite.flip_h = true
	elif move_direction == 1:
		sprite.flip_h = false
		
	if move_direction:
		velocity.x = move_direction * SPEED
		
	elif previous_state != states.wall_slide && previous_state != states.jump:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if state == states.wall_slide:
		if Input.is_action_just_pressed('ui_up'):
			sprite.flip_h = !sprite.flip_h
			_wall_jump()
			set_state(states.jump)
			
		
	
	move_and_slide()
	
func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall(left_wall_raycasts)
	var is_near_wall_right = _check_is_valid_wall(right_wall_raycasts)
	
	if is_near_wall_left && is_near_wall_right:
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int(is_near_wall_right)
	
func _check_is_valid_wall(wall_raycasts):
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if dot > PI * 0.35 && dot < PI * 0.55:
				return true
	return false

func _ready():
	add_state('idle')
	add_state('run')
	add_state('jump')
	add_state('fall')
	add_state('wall_slide')
	call_deferred('set_state', states.idle)
	
	
func _state_logic(delta):
	_update_move_direction()
	_update_wall_direction()
	if state != states.wall_slide:
		_handle_move_input()
	_apply_gravity(delta)
	if state == states.wall_slide:
		_cap_gravity_wall_slide()
		_handle_wall_slide_sticking()
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
			if !is_on_floor():
				if velocity.y < 0:
					return states.jump
				elif velocity.y > 0:
					return states.fall
			elif velocity.x == 0:
				return states.idle
		states.jump:
			if wall_direction != 0 && wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif is_on_floor():
				return states.idle
			elif velocity.y >= 0:
				return states.fall
		states.fall:
			if wall_direction != 0:
				return states.wall_slide
			elif is_on_floor():
				return states.idle
			elif velocity.y < 0:
				return states.jump
		states.wall_slide:
			if is_on_floor():
				return states.idle
			elif wall_direction == 0:
				return states.fall
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
		states.wall_slide:
			anim.play('WallSlide')
	

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			wall_slide_cooldown.start()


func _physics_process(delta):
	label.text = str(states.keys()[state])
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
	

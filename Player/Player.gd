class_name Player
extends CharacterBody2D

# No idea if this is true V
const UNIT_SIZE = 32
const SPEED = (15 * UNIT_SIZE)
const DASH_VELOCITY = SPEED
# TODO: These next two need refactors
const JUMP_VELOCITY = -(12 * UNIT_SIZE)
const WALL_JUMP_VELOCITY = Vector2(SPEED,JUMP_VELOCITY)

var state = null : set = set_state, get = get_state
var previous_state = null
var states = {}
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") 
var wall_direction = 1
var move_direction
var face_direction = 1
var dashed = false

var max_jump_velocity
var min_jump_velocity 
var max_jump_height = 2.25 * UNIT_SIZE
var min_jump_height = 0.8 * UNIT_SIZE
var jump_duration = 0.3

@onready var anim = $AnimationPlayer
@onready var label = $Label
@onready var sprite = get_node("AnimatedSprite2D")

@onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
@onready var right_wall_raycasts = $WallRaycasts/RightWallRaycasts

@onready var wall_slide_cooldown = $WallSlideCooldown
@onready var wall_slide_sticky_timer = $WallSlideStickyTimer
@onready var dash_cooldown = $DashTimer

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
			
func _handle_dash():
	var old_speed = velocity.x
	if dash_cooldown.is_stopped() && dashed == false:
		set_state(states.dashing)
		dash_cooldown.start()
		velocity.x += (face_direction*DASH_VELOCITY)
		await dash_cooldown.timeout 
		_slow(velocity.x, old_speed, DASH_VELOCITY)
		
		
func _get_h_weight():
	if is_on_floor():
		return 0.2
	else:
		if move_direction == 0:
			return 0.02
		elif move_direction == sign(velocity.x) && abs(velocity.x) > SPEED:
			return 0.0
		else:
			return 0.1
	
func _slow(from = velocity.x, to = 0, rate = SPEED):
	velocity.x = move_toward(from, to, rate)
	
func _jump():
	velocity.y =max_jump_velocity
	
func _fast_fall():
	velocity.y = -JUMP_VELOCITY
	
func _wall_jump():
	var wall_jump_velocity = WALL_JUMP_VELOCITY
	wall_jump_velocity.x *= -wall_direction
	velocity = wall_jump_velocity
	face_direction *= -1

func _on_WallSlideStickTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)	
	
func _handle_move_input():
	# Handle Jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		_jump()
		
	# Different y values indicate a minimum jump height
	if Input.is_action_just_released('ui_up') && velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity
		
	if Input.is_action_just_pressed("ui_down") and not is_on_floor():
		_fast_fall()
		
	# Not working right now, fix it later
	if Input.is_action_just_pressed('ui_select'):
		_handle_dash()
		
		
func _update_move_direction():
	move_direction = Input.get_axis("ui_left", "ui_right")
	if move_direction != 0:
		face_direction = move_direction		

func _apply_movement():
	
	if move_direction == -1:
		sprite.flip_h = true
	elif move_direction == 1:
		sprite.flip_h = false
		
	velocity.x = lerp(velocity.x, SPEED*move_direction, _get_h_weight())
	print(velocity.x)
	
	if abs(int(velocity.x)) <= UNIT_SIZE:
		velocity.x = 0
	
	if is_on_floor():
		dashed = false
	
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
	add_state('dashing')
	call_deferred('set_state', states.idle)
	
	gravity = 2 * max_jump_height / pow(jump_duration, 2)
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
	
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
			if wall_direction != 0 && wall_slide_cooldown.is_stopped():
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
		states.dashing:
			if is_on_floor():
				if velocity.x == 0:
					return states.idle
				else:
					return states.run
			elif dash_cooldown.is_stopped():
				if velocity.y < 0:
					return states.jump
				else:
					if wall_direction == 0:
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
			dashed = false
			anim.play('WallSlide')
		states.dashing:
			dashed = true
	

func _exit_state(old_state, new_state):
	print('old_state:', states.keys()[old_state])
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
	

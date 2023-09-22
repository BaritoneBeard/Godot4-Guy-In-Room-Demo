extends 'res://FSM.gd'

@export var player: CharacterBody2D

func _ready():
	print(player.name)
	add_state('idle')
	add_state('run')
	add_state('jump')
	add_state('fall')
	call_deferred('set_state', states.idle)
	
	
func _state_logic(delta):
	player._handle_move_input()
	player._apply_gravity(delta)
	player._apply_movement()
	
func _get_transition(delta):
	match state:
		states.idle:
			if !player.is_on_floor():
				if player.velocity.y < 0:
					return states.jump
				elif player.velocity.y > 0:
					return states.fall
				elif player.velocity.x != 0:
					return states.run
		states.run:
			if !player.is_on_floor():
				if player.velocity.y < 0:
					return states.jump
				elif player.velocity.y > 0:
					return states.fall
				elif player.velocity.x == 0:
					return states.idle
		states.jump:
			if player.is_on_floor():
				return states.idle
			elif player.velocity.y >= 0:
				return states.fall
		states.fall:
			if player.is_on_floor():
				return states.idle
			elif player.velocity.y < 0:
				return states.jump
				
	return null
				
func _enter_state(new_state, old_state):
	print(player)
#	match new_state:
#		states.idle:
#			player.anim.play('Idle')
#		states.run:
#			player.anim.play('Run')
#		states.jump:
#			player.anim.play('Jump')
#		states.fall:
#			player.anim.play('Fall')
	

func _exit_state(old_state, new_state):
	pass


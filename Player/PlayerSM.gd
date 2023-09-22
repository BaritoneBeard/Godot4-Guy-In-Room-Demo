extends 'res://FSM.gd'

@onready var player_node = get_parent()


func _ready():
	print(player_node.name)
	add_state('idle')
	add_state('run')
	add_state('jump')
	add_state('fall')
	call_deferred('set_state', states.idle)
	
	
func _state_logic(delta):
	player_node._handle_move_input()
	player_node._apply_gravity(delta)
	player_node._apply_movement()
	
func _get_transition(delta):
	match state:
		states.idle:
			if !player_node.is_on_floor():
				if player_node.velocity.y < 0:
					return states.jump
				elif player_node.velocity.y > 0:
					return states.fall
				elif player_node.velocity.x != 0:
					return states.run
		states.run:
			if !player_node.is_on_floor():
				if player_node.velocity.y < 0:
					return states.jump
				elif player_node.velocity.y > 0:
					return states.fall
				elif player_node.velocity.x == 0:
					return states.idle
		states.jump:
			if player_node.is_on_floor():
				return states.idle
			elif player_node.velocity.y >= 0:
				return states.fall
		states.fall:
			if player_node.is_on_floor():
				return states.idle
			elif player_node.velocity.y < 0:
				return states.jump
				
	return null
				
func _enter_state(new_state, old_state):
	print(player_node)
	match new_state:
		states.idle:
			player_node.anim.play('Idle')
		states.run:
			player_node.anim.play('Run')
		states.jump:
			player_node.anim.play('Jump')
		states.fall:
			player_node.anim.play('Fall')
	

func _exit_state(old_state, new_state):
	pass


extends Button

@export var action: String = "ui_up"

func _init():
	toggle_mode = true
	
	
func _ready():
	set_process_unhandled_input(false)
	update_key_text()
	
	
func _toggled(button_pressed):
	set_process_unhandled_input(button_pressed)
	if button_pressed:
		text = "..."
		release_focus()
	else:
		update_key_text()
		grab_focus()
		
		
func _unhandled_input(event):
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	button_pressed = false
	
	
func update_key_text():
	text = "%s" % InputMap.action_get_events(action)[0].as_text()
 

func _process(delta):
	if Input.is_action_just_pressed('quit') || Input.is_action_just_pressed('start'):
		_on_done_pressed()
		

func _on_done_pressed():
	get_tree().change_scene_to_file('res://man_in_room_demo.tscn')

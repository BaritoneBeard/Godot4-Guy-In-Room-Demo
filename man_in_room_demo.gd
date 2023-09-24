extends Node2D

func _process(delta):
	if Input.is_action_just_pressed('start'):
		_on_start_pressed()
	if Input.is_action_just_pressed('quit'):
		_on_quit_pressed()

func _on_start_pressed():
	get_tree().change_scene_to_file('res://world.tscn')


func _on_quit_pressed():
	get_tree().quit()

extends Node2D

static var has_name_changed := false
@onready var player_name = $PlayerName
@onready var start_game_button = $StartGameButton
@onready var high_score_button = $HighScoreButton
@onready var quit_button = $QuitButton

var current_focus = 0

func _ready():
	start_game_button.grab_focus()
	if has_name_changed:
		player_name.text = Save.player_name
	
func _input(event):
	if event.is_action_pressed("MoveLeft"): focus_left()
	elif event.is_action_pressed("MoveRight"): focus_right()
	#
	if event.is_action_pressed("Launch"): press_button()
	if event.is_action_pressed("Cancel"): quit_button.grab_focus()
	if event.is_action_pressed("ToggleMode"): change_name()
	
func change_name():
	player_name.grab_focus()

func press_button():
	if player_name.has_focus():
		if player_name.text != "":
			_on_player_name_text_changed(player_name.text)
		start_game_button.grab_focus()
	elif quit_button.has_focus():
		_on_quit_button_pressed()
	elif high_score_button.has_focus():
		_on_high_score_button_pressed()
	else:
		_on_button_pressed()

func focus_left():
	if start_game_button.has_focus():
		quit_button.grab_focus()
	elif high_score_button.has_focus():
		start_game_button.grab_focus()

func focus_right():
	if start_game_button.has_focus():
		high_score_button.grab_focus()
	elif quit_button.has_focus():
		start_game_button.grab_focus()

func focus_name():
	player_name.grab_focus()

func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_button_pressed():
	get_tree().quit()


func _on_high_score_button_pressed():
	Globals.light_score = 0
	Globals.shadows_score = 0
	Globals.balance_score = 0
	get_tree().change_scene_to_file("res://scenes/high_score.tscn")


func _on_player_name_text_changed(new_text):
	Save.player_name = new_text
	has_name_changed = true


func _on_player_name_text_submitted(new_text):
	_on_player_name_text_changed(new_text)
	start_game_button.grab_focus()

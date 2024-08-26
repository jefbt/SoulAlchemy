extends Node2D

@onready var light_score_label = $Labels/LightScoreLabel
@onready var shadows_score_label = $Labels/ShadowsScoreLabel
@onready var balance_score_label = $Labels/BalanceScoreLabel
@onready var play_again_button = $Buttons/PlayAgainButton
@onready var main_menu_button = $Buttons/MainMenuButton
@onready var high_name = $Labels/HighName
@onready var high_light = $Labels/HighLight
@onready var high_shadows = $Labels/HighShadows
@onready var high_balance = $Labels/HighBalance
@onready var player_name_label = $Labels/PlayerNameLabel
@onready var audio_stream_player = $AudioStreamPlayer
@onready var toggle_sound = $ToggleSound

var toggle_sound_button : Button

func update_score(light_score: int, shadows_score: int, balance_score: int):
	light_score_label.text = str(light_score)
	shadows_score_label.text = str(shadows_score)
	balance_score_label.text = str(balance_score)
	player_name_label.text = Save.player_name
	high_name.text = ""
	high_light.text = ""
	high_shadows.text = ""
	high_balance.text = ""
	for entry in Save.high_score_table.values():
		var _name = str(entry[3])
		var light = str(entry[0])
		var shadows = str(entry[1])
		var balance = str(entry[2])
		high_name.text += _name + "\n"
		high_light.text += light + "\n"
		high_shadows.text += shadows + "\n"
		high_balance.text += balance + "\n"

func _ready():
	toggle_sound_button = toggle_sound.get_child(0) as Button
	play_again_button.grab_focus()
	update_score(Globals.light_score, Globals.shadows_score, Globals.balance_score)
	audio_stream_player.play(Globals.music_highscore)

func _on_main_menu_button_pressed():
	Globals.music_highscore = audio_stream_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_play_again_button_pressed():
	Globals.music_highscore = audio_stream_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func press_button():
	if main_menu_button.has_focus():
		_on_main_menu_button_pressed()
	elif play_again_button.has_focus():
		_on_play_again_button_pressed()

func focus_left():
	if main_menu_button.has_focus():
		toggle_sound_button.grab_focus()
	elif play_again_button.has_focus():
		main_menu_button.grab_focus()
	
func focus_right():
	if main_menu_button.has_focus():
		play_again_button.grab_focus()
	elif toggle_sound_button.has_focus():
		main_menu_button.grab_focus()
	
func _input(event):
	if event.is_action_pressed("MoveLeft"): focus_left()
	elif event.is_action_pressed("MoveRight"): focus_right()
	#
	if event.is_action_pressed("Launch"): press_button()
	if event.is_action_pressed("Cancel"): main_menu_button.grab_focus()
	if event.is_action_pressed("ToggleMode"): play_again_button.grab_focus()

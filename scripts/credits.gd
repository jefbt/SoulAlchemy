extends Node2D
@onready var audio_stream_player = $AudioStreamPlayer
@onready var quit_button = $QuitButton

func _ready():
	audio_stream_player.play(Globals.music_credits)
	quit_button.grab_focus()

func _on_quit_button_pressed():
	Globals.music_credits = audio_stream_player.get_playback_position()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("Launch"):
		_on_quit_button_pressed()

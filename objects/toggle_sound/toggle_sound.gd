extends Node2D

@onready var music_off = $MusicOff
@onready var music_on = $MusicOn

# Called when the node enters the scene tree for the first time.
func _ready():
	set_sound(Globals.sound_muted)

func toggle():
	set_sound(!Globals.sound_muted)

func set_sound(muted: bool):
	Globals.sound_muted = muted
	music_off.visible = Globals.sound_muted
	music_on.visible = !Globals.sound_muted
	AudioServer.set_bus_mute(0, Globals.sound_muted)

func _on_button_pressed():
	toggle()

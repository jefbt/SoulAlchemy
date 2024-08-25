extends Node2D

@onready var light_score_label = $Labels/LightScoreLabel
@onready var shadows_score_label = $Labels/ShadowsScoreLabel
@onready var balance_score_label = $Labels/BalanceScoreLabel
@onready var high_score_label = $Labels/HighScoreLabel

func update_score(light_score: int, shadows_score: int, balance_score: int):
	light_score_label.text = "Light Score: " + str(light_score)
	shadows_score_label.text = "Shadows Score: " + str(shadows_score)
	balance_score_label.text = "Balance Score: " + str(balance_score)

	var hs_text = ""
	for entry in Save.high_score_table.values():
		var _name = entry[3]
		var light = entry[0]
		var shadows = entry[1]
		var balance = entry[2]
		hs_text += _name + ": Light = " + str(light)
		hs_text += " | Shadows = " + str(shadows)
		hs_text += " | Balance = " + str(balance)
		hs_text += "\n"
	high_score_label.text = hs_text

func _ready():
	update_score(Globals.light_score, Globals.shadows_score, Globals.balance_score)

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_play_again_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

extends Node2D

@onready var light_score_label = $LightScoreLabel
@onready var shadows_score_label = $ShadowsScoreLabel
@onready var balance_score_label = $BalanceScoreLabel

func update_score(light_score: int, shadows_score: int, balance_score: int):
	light_score_label.text = "Light Score: " + str(light_score)
	shadows_score_label.text = "Shadows Score: " + str(shadows_score)
	balance_score_label.text = "Balance Score: " + str(balance_score)

func _ready():
	update_score(Globals.light_score, Globals.shadows_score, Globals.balance_score)

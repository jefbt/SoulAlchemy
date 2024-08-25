extends Node

var save_path := "user://highscore.sv"
var player_name := "Noname"

var high_score_table : Dictionary = {
	1: [ 100, 100, 100, "Saitama"],
	2: [ 90, 90, 90, "Jesus"],
	3: [ 80, 80, 80, "Dr. Victor"],
	4: [ 70, 70, 70, "Drumont"],
	5: [ 60, 60, 60, "Myself"],
	6: [ 50, 50, 50, "H3l3n3"],
	7: [ 40, 40, 40, "The Seventh son of the seventh son"],
	8: [ 30, 30, 30, "Wolf to the mooon"],
	9: [ 20, 20, 20, "Pig"],
	10: [ 10, 10, 10, "Last of us"],
}

func check_score(light_score: int, shadows_score: int, balance_score: int):
	var keys = high_score_table.keys()
	for n in keys:
		var score = high_score_table[n][2]
		if balance_score > score:
			for j in range(keys.back(), n, -1):
				high_score_table[j] = high_score_table[j - 1]
			var new_score = [light_score, shadows_score, balance_score, player_name]
			high_score_table[n] = new_score
			update_highscore()
			break

func update_highscore():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(high_score_table)
	
func load_highscore():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score_table = file.get_var()

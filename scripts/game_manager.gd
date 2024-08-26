class_name GameManager
extends Node

# TODO find out about showing ads on android version (and maybe web version)
# TODO add a can't launch animation to the object
# TODO add different sound effects for each element, 
	# like a swoosh for fire, ping for metal etc

enum Mode { Light = 0, Shadows = 1 }
enum MoveDirection { Left = -1, Right = 1 }

const SOUL_OBJECT = preload("res://objects/soul_object/soul_object.tscn")
@onready var soul_objects = $"SoulObjects"
@onready var mode_node = $UI/UIPosition/Mode
@onready var light = $UI/Light
@onready var shadows = $UI/Shadows
@onready var mode_shadows = $UI/ModeShadows
@onready var mode_light = $UI/ModeLight
@onready var auto_launch_off = $UI/AutoLaunchOff
@onready var auto_launch_on = $UI/AutoLaunchOn
@onready var score_light = $UI/Score/ScoreLight
@onready var score_shadows = $UI/Score/ScoreShadows
@onready var multiplier = $UI/Score/Multiplier
@onready var score_balance = $UI/Score/Balance/ScoreBalance

@onready var music_light = $Audio/MusicLight
@onready var music_shadows = $Audio/MusicShadows
@onready var pop_sfx = $Audio/PopSFX
@onready var quit_sfx = $Audio/QuitSFX
@onready var turn_off_auto_launch_sfx = $Audio/TurnOffAutoLaunchSFX
@onready var turn_on_auto_launch_sfx_2 = $Audio/TurnOnAutoLaunchSFX2
@onready var toggle_mode_sfx = $Audio/ToggleModeSFX
@onready var cannot_launch_sfx = $Audio/CannotLaunchSFX
@onready var toggle_sound = $UI/Icons/ToggleSound

@onready var target_sprite_0 = $Target/TargetSprite0
@onready var target_sprite_1 = $Target/TargetSprite1
@onready var target_sprite_2 = $Target/TargetSprite2
@onready var target_sprite_3 = $Target/TargetSprite3
@onready var target_sprite_4 = $Target/TargetSprite4

@onready var multi_timer = $UI/Score/Multiplier/MultiTimer

@export var grid_size : float = 65.0
@export var grid_count_x : int = 5
@export var grid_count_y : int = 7
@export var falling_move_duration = 0.5
@export var launch_speed = 128
@export var max_queue = 3
@export var base_score = 1.0
@export var score_multiplier_increment = 0.25
@export var max_score_multiplier = 3.0

@export var drop_symbols: Array[Node2D]
var targets : Array[Sprite2D]

var falling_objects : Dictionary
var queue_objects : Array[SoulObject]
var launched_objects = { 0: null, 1: null, 2: null, 3: null, 4: null }
var selected_object : SoulObject
var launch_lane : int = -1
var starting_launch_lane = 2

var falling_start_x = 0.0
var falling_start_y = 0.0
var launch_y = 0
var queue_vector = Vector2(1, 0)
var queue_start = Vector2(215, 225.5)
var input_modifier := false
var auto_launch := false

var drop := 0
var reseting_drop := false
var drop_reset_time := 0.25
var next_drop_reset := -1.0
var drop_reset_count := 0

var balance_score := 0
var light_score := 0
var shadows_score := 0
var score_multiplier := 1.0
var reduce_multiplier_time := -1.0
var reduce_delta := 0.0
var reset_delta := false
var is_game_over := false

var toggle_sound_button : Button

const REDUCE_MULTIPLIER_DURATION = 6.0

static var mode : Mode = Mode.Light
static var bottom_line : float = 0.0

# built-in functions
func _ready():
	is_game_over = false
	Globals.light_score = 0
	Globals.shadows_score = 0
	Globals.balance_score = 0
	var size_x = grid_size * grid_count_x
	var size_y = grid_size * grid_count_y
	falling_start_x = -size_x / 2.0 + grid_size / 2
	falling_start_y = -size_y / 2.0 - grid_size
	launch_y = size_y / 2.0 - grid_size
	bottom_line = launch_y
	targets = [
		target_sprite_0,
		target_sprite_1,
		target_sprite_2,
		target_sprite_3,
		target_sprite_4,
	]
	change_mode(mode)
	set_auto_launch(auto_launch)
	add_falling_line()
	start_queue()
	update_drop_symbols()
	score_update()
	update_target_sprite()
	Save.load_highscore()

func _process(delta):
	if is_game_over: return
	input_modifier = Input.is_action_pressed("LaunchLaneTrigger")
	check_drop_reseting()
	check_score_multiplier(delta)
# end built-int

# management
func trigger_game_over(_soul_object: SoulObject = null):
	Globals.light_score = light_score
	Globals.shadows_score = shadows_score
	Globals.balance_score = balance_score
	Save.check_score(light_score, shadows_score, balance_score)
	quit_sfx.play()
	is_game_over = true
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/high_score.tscn")

func change_mode(new_mode: Mode):
	self.mode = new_mode
	if self.mode == Mode.Light:
		mode_light.visible = true
		mode_shadows.visible = false
		shadows.visible = false
		light.visible = true
		Globals.music_shadows = music_shadows.get_playback_position()
		music_shadows.stop()
		music_light.play(Globals.music_light)
	else:
		mode_light.visible = false
		mode_shadows.visible = true
		shadows.visible = true
		light.visible = false
		Globals.music_light = music_light.get_playback_position()
		music_light.stop()
		music_shadows.play(Globals.music_shadows)
	update_target_sprite()

func toggle_mode():
	if is_game_over: return
	toggle_mode_sfx.play()
	if mode == Mode.Light: change_mode(Mode.Shadows)
	else: change_mode(Mode.Light)
# end management

# QUEUE region
func start_queue():
	launch_lane = starting_launch_lane
	for n in max_queue: 
		var so = SOUL_OBJECT.instantiate()
		so.game_manager = self
		add_queue(so as SoulObject, false)
	queue_to_lane()
	set_auto_launch(false)

func add_queue(soul_object: SoulObject, update : bool = true):
	if soul_object == null: return
	if queue_objects.size() >= max_queue:
		while queue_objects.size() > max_queue:
			queue_objects.pop_back()
		return
	if queue_objects.has(soul_object): return
	soul_object.type = SoulObject.Type.Queue
	queue_objects.append(soul_object)
	soul_objects.add_child(soul_object)
	if update: update_queue()

func remove_queue(soul_object: SoulObject, update : bool = true):
	queue_objects.erase(soul_object)
	if update: update_queue()

func queue_to_lane():
	if selected_object != null: return
	if queue_objects == null or queue_objects.size() == 0: return
	selected_object = queue_objects.pop_front() as SoulObject
	selected_object.lane = launch_lane
	var so = SOUL_OBJECT.instantiate()
	so.game_manager = self
	add_queue(so as SoulObject, false)
	update_selected()
	update_queue()

func update_queue():
	if queue_objects == null or queue_objects.size() == 0: return
	for n in queue_objects.size():
		var qo = queue_objects[n]
		qo.position = queue_start + ((queue_vector * n) * grid_size)
# end QUEUE

# SELECTION region
func update_selected():
	update_target_sprite()
	if selected_object == null: return
	selected_object.position.y = launch_y + grid_size
	selected_object.position.x = selected_object.lane * grid_size + falling_start_x

func move_selected(direction):
	if is_game_over: return
	if selected_object == null: return
	var lane = selected_object.lane + int(direction)
	if lane < 0: lane = 0
	if lane >= grid_count_x: lane = grid_count_x - 1
	selected_object.lane = lane
	update_selected()
# end SELECTION

# FALLING region
func update_drop_symbols():
	for n in drop:
		var node = drop_symbols[n] as Node2D
		node.visible = true
	for m in drop_symbols.size() - drop:
		var i = drop + m
		var node = drop_symbols[i] as Node2D
		node.visible = false

func reset_drop():
	move_falling()
	drop = 0
	update_drop_symbols()

func check_drop_reseting():
	if reseting_drop:
		if next_drop_reset <= 0.0:
			next_drop_reset = Time.get_ticks_usec() + drop_reset_time + 0.5
			return
		if Time.get_ticks_usec() >= next_drop_reset:
			next_drop_reset = Time.get_ticks_usec() + drop_reset_time
			var node = drop_symbols[drop_reset_count] as Node2D
			node.visible = false
			drop_reset_count += 1
		if drop_reset_count >= drop_symbols.size():
			drop_reset_count = 0
			next_drop_reset = -1.0
			reset_drop()
			reseting_drop = false

func check_needs_falling():
	if reseting_drop: return
	drop += 1
	if drop >= drop_symbols.size() + 1:
		reseting_drop = true
	else:
		update_drop_symbols()

func clean_up_falling():
	for row in falling_objects.keys():
		var is_null = true
		for lane in falling_objects[row].values():
			if lane != null:
				is_null = false
				break
		if is_null:
			falling_objects.erase(row)

func move_falling():
	clean_up_falling()
	add_falling_line()
	for row in falling_objects.keys():
		for lane in falling_objects[row].keys():
			if falling_objects[row][lane] != null:
				falling_objects[row][lane].move(grid_size, falling_move_duration)

func add_falling_line():
	var line = {}
	var b_line = null
	var row = -1
	var topmost_position = falling_start_y
	for key in falling_objects.keys():
		if row < key: 
			row = key
			for fo in falling_objects[key].values():
				if fo != null:
					topmost_position = fo.position.y - grid_size
	if falling_objects.keys().has(row):
		b_line = falling_objects[row]
	row += 1
	if topmost_position > falling_start_y:
		topmost_position = falling_start_y - grid_size
	if falling_objects.size() == 0:
		row = 0
	for lane in grid_count_x: line[lane] = null
	for lane in grid_count_x:
		var new_obj = SOUL_OBJECT.instantiate()
		soul_objects.add_child(new_obj)
		new_obj.game_manager = self
		new_obj.type = SoulObject.Type.Falling
		new_obj.lane = lane
		new_obj.row = row
		new_obj.check_function = check_clash
		new_obj.position.x = lane * grid_size + falling_start_x
		new_obj.position.y = topmost_position
		new_obj.next_object = topmost_position + grid_size
		if lane > 0: new_obj.left = line[lane - 1]
		if b_line != null:
			new_obj.bottom = b_line[lane]
			if b_line[lane] != null:
				b_line[lane].top = new_obj
		line[lane] = new_obj
	falling_objects[row] = line
	for lane in grid_count_x:
		if lane < grid_count_x - 1:
			line[lane].right = line[lane + 1]
# end FALLING

# LAUCH region
func launch_selected():
	if is_game_over: return
	if selected_object == null: return
	if launched_objects[selected_object.lane] != null:
		cannot_launch_sfx.play()
		return
	launch_obj(selected_object)
	launch_lane = selected_object.lane
	selected_object = null
	queue_to_lane()

func launch_obj(obj: SoulObject):
	if obj == null: return
	if launched_objects[obj.lane] != null: return
	obj.type = SoulObject.Type.Launch
	obj.check_function = check_clash
	obj.position.x = obj.lane * grid_size + falling_start_x
	obj.position.y = launch_y
	obj.move(launch_speed)
	obj.launch_sfx.play()
	launched_objects[obj.lane] = obj
	check_needs_falling()

func add_launch(lane: int):
	if launched_objects[lane] != null: return
	if lane < 0: lane = 0
	if lane >= grid_count_x: lane = grid_count_x - 1
	var new_obj = SOUL_OBJECT.instantiate()
	new_obj.game_manager = self
	new_obj.lane = lane
	soul_objects.add_child(new_obj)
	launch_obj(new_obj)

func mode_direction():
	if mode == Mode.Light: return 1
	else: return -1

func check_clash(falling: SoulObject, launch: SoulObject):
	var direction = mode_direction()
	var wanted = int(falling.element) - direction
	if wanted < 0: wanted = SoulObject.Element.size() - 1
	if wanted >= SoulObject.Element.size(): wanted = 0
	var passed = int(launch.element) == wanted
	#passed = true # TODO remove this
	if passed: match_elements(falling, launch)
	else: wrong_elements(falling, launch)

func find_extra_match(soul_obj: SoulObject, element) -> int:
	if soul_obj == null or soul_obj.counted: return 0
	if not (soul_obj is SoulObject): return 0
	if soul_obj.element != element: return 0
	soul_obj.counted = true
	var count = 0
	if soul_obj.left != null and not soul_obj.left.counted:
		count += find_extra_match(soul_obj.left, element)
	if soul_obj.right != null and not soul_obj.right.counted:
		count += find_extra_match(soul_obj.right, element)
	if soul_obj.top != null and not soul_obj.top.counted:
		count += find_extra_match(soul_obj.top, element)
	if soul_obj.bottom != null and not soul_obj.bottom.counted:
		count += find_extra_match(soul_obj.bottom, element)
	soul_obj.dismiss()
	return count + 1

func match_elements(falling: SoulObject, launch: SoulObject):
	var extra = find_extra_match(falling, falling.element)
	var extra_multi = 1.0 + float(extra) / 5.0
	var extra_score = int(float(extra) * extra_multi)
	score(extra_score + 1)
	pop_sfx.play()
	falling.dismiss()
	launch.dismiss()
	
func wrong_elements(falling: SoulObject, launch: SoulObject):
	launched_objects[launch.lane] = null
	launch.launched = false
	launch.type = SoulObject.Type.Falling
	launch.position.y = falling.next_object
	launch.next_object = launch.position.y + grid_size
	launch.grid_size = grid_size
	var row = falling.row - 1
	if !falling_objects.keys().has(row):
		falling_objects[row] = {}
		for n in grid_count_x:
			falling_objects[row][n] = null
	falling_objects[row][launch.lane] = launch
	falling.bottom = launch
	launch.top = falling
	launch.row = row
	for lane in falling_objects[row].keys():
		if falling_objects[row][lane] == null: continue
		if lane > 0:
			falling_objects[row][lane].left = falling_objects[row][lane - 1]
		if lane < grid_count_x - 1:
			falling_objects[row][lane].right = falling_objects[row][lane + 1]
	if launch.position.y >= bottom_line:
		launch.hit_bottom()
	wrong()
	launch.wrong_sfx.play()
# end LAUNCH

# extra
func update_target_sprite():
	for ts in targets:
		var tar = ts as Sprite2D
		if tar != null:
			tar.visible = false
	if selected_object != null:
		var direction = mode_direction()
		var wanted = int(selected_object.element) + direction
		if wanted < 0: wanted = SoulObject.Element.size() - 1
		if wanted >= SoulObject.Element.size(): wanted = 0
		var color = selected_object.element_color[wanted]
		var tar = targets[wanted] as Sprite2D
		if tar != null:
			tar.modulate = color
			tar.visible = true

func free_soul_objects():
	for qo in queue_objects:
		if qo != null: qo.queue_free()
	for lo in launched_objects.values():
		if lo != null and lo is SoulObject: lo.queue_free()
	for fo in falling_objects.values():
		if fo == null: continue
		if fo is Array:
			for ofo in fo: if ofo != null: ofo.queue_free()
		elif fo is Dictionary:
			for ofo in fo.values(): if ofo != null: ofo.queue_free()
		else:
			fo.queue_free()
	falling_objects.clear()
	launched_objects.clear()
	queue_objects.clear()
	if selected_object != null: selected_object.queue_free()
	launched_objects = { 0: null, 1: null, 2: null, 3: null, 4: null }

func score_update():
	score_light.text = str(light_score)
	score_shadows.text = str(shadows_score)
	multiplier.text = str(int(score_multiplier))
	score_balance.text = str(balance_score)

func calc_balance_score():
	# TODO balance score is not getting the desired results
	var diff = float(abs(light_score - shadows_score))
	var best = float(max(light_score, shadows_score))
	var worst = float(min(light_score, shadows_score))
	var scoring = 0.0
	if diff == 0:
		scoring = 2.0 * worst + best
	else:
		scoring = 1.0/float(diff) * float(diff)
		scoring = (scoring * worst) + best
	balance_score = int(scoring)

func score(objects_count: int = 1):
	reduce_delta = 0.0
	reset_delta = true
	for n in objects_count:
		if mode == Mode.Light:
			light_score += int(base_score * score_multiplier)
		else:
			shadows_score += int(base_score * score_multiplier)
		calc_balance_score()
		score_multiplier += score_multiplier_increment
		if score_multiplier > max_score_multiplier: score_multiplier = max_score_multiplier
	score_update()

func set_auto_launch(enable : bool):
	if enable: turn_on_auto_launch_sfx_2.play()
	else: turn_off_auto_launch_sfx.play()
	auto_launch = enable
	auto_launch_off.visible = !auto_launch
	auto_launch_on.visible = auto_launch

func toggle_auto_launch():
	if is_game_over: return
	set_auto_launch(!auto_launch)

func wrong():
	reduce_delta += 0.12
	check_score_multiplier(0.0)
	score_update()

func check_score_multiplier(delta):
	if score_multiplier < 2.0 or reset_delta:
		multi_timer.scale.x = 1.0
		multi_timer.visible = false
		reduce_delta = 0.0
		reset_delta = false
		return
	multi_timer.visible = true
	reduce_delta += delta / REDUCE_MULTIPLIER_DURATION
	multi_timer.scale.x = 1.0 - reduce_delta
	if reduce_delta >= 1.0:
		reduce_delta = 0.0
		score_multiplier = 1.0
	score_update()
# end extra

# input events
func handle_lane_input(lane: int, modifier: bool = false):
	if is_game_over: return
	if selected_object == null: return
	selected_object.lane = lane
	if auto_launch != modifier:
		launch_selected()
	else:
		update_selected()

func handle_move_input(direction: int):
	move_selected(direction)
	
func toggle_audio():
	toggle_sound.toggle()

func _input(event):
	if is_game_over: return
	for n in grid_count_x:
		if event.is_action_pressed("Lane" + str(n)): handle_lane_input(n, input_modifier)
	#
	if event.is_action_pressed("MoveLeft"): handle_move_input(-1)
	elif event.is_action_pressed("MoveRight"): handle_move_input(1)
	#
	if event.is_action_pressed("Launch"): launch_selected()
	if event.is_action_pressed("ToggleAutoLaunch"): toggle_auto_launch()
	if event.is_action_pressed("ToggleMode"): toggle_mode()
	if event.is_action_pressed("Cancel"): _on_give_up_pressed()
	if event.is_action_pressed("ToggleAudio"): toggle_audio()
	
	# TODO: remove these later
	if event.is_action_pressed("DebugPlus"):
		score(1)
	if event.is_action_pressed("DebugMinus"):
		toggle_mode()
		score(1)

# signals
func _on_add_falling_pressed():
	add_falling_line()

func _on_move_pressed():
	move_falling()

func _on_launch_pressed():
	launch_selected()

func _on_move_left_pressed():
	move_selected(MoveDirection.Left)

func _on_move_right_pressed():
	move_selected(MoveDirection.Right)

func _on_lane_0_pressed():
	handle_lane_input(0)

func _on_lane_1_pressed():
	handle_lane_input(1)

func _on_lane_2_pressed():
	handle_lane_input(2)

func _on_lane_3_pressed():
	handle_lane_input(3)

func _on_lane_4_pressed():
	handle_lane_input(4)

func _on_toggle_pressed():
	toggle_auto_launch()

func _on_mode_pressed():
	toggle_mode()

func _on_give_up_pressed():
	trigger_game_over(null)

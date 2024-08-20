class_name SoulObject
extends Area2D

enum Element { Water = 0, Metal = 1, Earth = 2, Fire = 3, Wood = 4 }
enum Type { Queue = 0, Falling = 1, Launch = -1 }

const ACCELERATION = 500.0
@onready var sprite = $Sprite
@onready var sprite_light = $SpriteLight
@onready var sprite_shadows = $SpriteShadows

@onready var top_conn = $Connections/TopConn
@onready var bottom_conn = $Connections/BottomConn
@onready var left_conn = $Connections/LeftConn
@onready var right_conn = $Connections/RightConn

@onready var label_row = $Connections/LabelRow
@onready var label_lane = $Connections/LabelLane

@export var debug = false
@export var element_color: Array[Color] = [
	Color.hex(0x5DE2E7FF),
	Color.hex(0xCECECEFF),
	Color.hex(0x8D6F64FF),
	Color.hex(0xFF5601FF),
	Color.hex(0xBFD641FF),
]
@export var element : Element:
	set(value):
		element = value
		sprite.animation = str(int(element))
		sprite.modulate = element_color[int(value)]
@export var type : Type = Type.Queue
@export var is_random_element : bool = true

var lane : int = -1
var row : int = -1
var is_falling := false
var launched := false
var delta_move := 0.0
var move_duration := 0.5
var start_y := 0.0
var next_y := 0.0
var next_object := 0.0
var launch_speed := 50.0
var check_function : Callable
var top : SoulObject = null
var left : SoulObject = null
var right : SoulObject = null
var bottom : SoulObject = null
var grid_size := 0.0
var game_manager: GameManager = null
var counted := false

func _ready():
	if is_random_element:
		var element_index = randi() % Element.size()
		element = Element.values()[element_index]

func _process(delta):
	sprite_light.visible = game_manager.mode == GameManager.Mode.Light
	sprite_shadows.visible = game_manager.mode == GameManager.Mode.Shadows
	if is_falling:
		delta_move += delta / move_duration
		position.y = lerpf(start_y, next_y, delta_move)
		if delta_move >= 1:
			is_falling = false
			position.y = next_y
		if position.y >= GameManager.bottom_line:
			hit_bottom()
	elif launched:
		position.y -= launch_speed * delta
		launch_speed += delta * ACCELERATION
		if position.y < -400: dismiss()
	if debug:
		top_conn.visible = top != null
		bottom_conn.visible = bottom != null
		left_conn.visible = left != null
		right_conn.visible = right != null
		label_row.text = str(row)
		label_lane.text = str(lane)
	else:
		top_conn.visible = false
		bottom_conn.visible = false
		left_conn.visible = false
		right_conn.visible = false
		label_row.text = ""
		label_lane.text = ""

func _on_area_entered(area):
	if type != Type.Launch: return
	var other = area as SoulObject
	if other == null or other.type != Type.Falling: return
	if other.lane != lane: return
	check_function.call(other, self)

# move_amount is speed for launched, and grid size for falling
func move(move_amount: float, duration: float = 0):
	if type == Type.Falling:
		is_falling = true
		delta_move = 0.0
		move_duration = duration
		if move_duration <= 0: move_duration = 0.001
		start_y = position.y
		next_y = position.y + move_amount
		next_object = next_y + move_amount
	elif type == Type.Launch:
		launch_speed = move_amount
		launched = true

func dismiss():
	queue_free()

func hit_bottom():
	if game_manager != null:
		game_manager.trigger_game_over(self)
	else:
		print("No GameMamanger set. 'hit_bottom()' did nothing")

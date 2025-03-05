class_name Pawn
extends Node2D

@export var pawn_name: String
@export var moveable: bool = true
@export var max_speed: float = 1.0
@export_enum("BLUE", "RED", "NEUTRAL") var camp: String = "NEUTRAL"
@export_enum("CHARACTER", "BUILDING", "RESOURCE", "MONSTER") var type: String = "CHARACTER"
@export_enum("上路", "打野", "中路", "辅助", "下路") var lane: String

@onready var button = $Button
var move_speed : float

var map : KohMap
var dragging = false
var dragged = false
var drag_start = Vector2()
var drag_start_position = Vector2()

var map_rect 
var tile_size
var map_size

@onready var camp_color_flag := $CampColor
@onready var name_label := $Name
@onready var sprite := $Sprite
@onready var popup_panel := $PopupPanel

@onready var body_shape := $BodyArea
@onready var detect_shape := $DetectArea

var npc : NPC
var hp : int = 100
var visible_to_blue : bool = true

const PAWN_SCENE = preload("res://scenes/simulator/pawn.tscn")

static func create_pawn(map: KohMap, npc: NPC, name: String, camp: String, lane: String, type: String) -> Pawn:
	var pawn = PAWN_SCENE.instantiate()
	pawn.npc = npc
	pawn.pawn_name = name
	pawn.camp = camp
	pawn.lane = lane
	pawn.type = type
	pawn.hp = 100
	pawn.map = map

	if type == "CHARACTER":
		pawn.moveable = true
	else:
		pawn.moveable = false

	return pawn

func _ready() -> void:

	map = get_parent().get_parent()

	if not map.is_node_ready():
		await map.ready

	map_rect = map.ground_layer.get_used_rect()
	tile_size = map.ground_layer.tile_set.tile_size
	map_size = map_rect.size * tile_size
	
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_button_pressed)

	move_speed = max_speed * scale.x

	match camp:
		"BLUE":
			camp_color_flag.color = Color.BLUE
		"RED":
			camp_color_flag.color = Color.RED
		"NEUTRAL":
			camp_color_flag.color = Color.GRAY

	match type:
		"CHARACTER":
			moveable = true
			# pawn_name = lane
			if camp == "RED":
				visible_to_blue = false
		"BUILDING":
			moveable = false
			name_label.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.2
		"RESOURCE":
			moveable = false
			name_label.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.2
		"MONSTER":
			moveable = false
			name_label.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.2

	name_label.text = pawn_name

func _show():
	name_label.text = pawn_name

func _on_button_down():
	if moveable:
		if not dragging:
			drag_start_position = position
		dragging = true
		drag_start = get_global_mouse_position() - position
		dragged = false

func _on_button_up():
	dragging = false
	if get_global_mouse_position().distance_to(drag_start_position) > 1:
		dragged = true
	else:
		dragged = false

func _process(_delta):
	if dragging:
		var new_pos = get_global_mouse_position() - drag_start
		
		new_pos.x = clamp(new_pos.x, 0, map_size.x * map.scale.x)
		new_pos.y = clamp(new_pos.y, 0, map_size.y * map.scale.y)
		position = new_pos
		
		# 如果移动距离超过阈值，标记为已拖动
		if position.distance_to(drag_start_position) > 1:
			dragged = true

	if camp == "RED" and not visible_to_blue:
		sprite.modulate.a = 0.5
		camp_color_flag.modulate.a = 0.5

func random_move():
	if dragging:
		return

	# 生成随机方向
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# 计算随机移动距离
	var random_distance = randf_range(0, move_speed)
	
	# 计算新位置
	var random_x = position.x + random_direction.x * random_distance
	var random_y = position.y + random_direction.y * random_distance
	
	# 确保位置在地图范围内
	random_x = clamp(random_x, 0, map_size.x * map.scale.x)
	random_y = clamp(random_y, 0, map_size.y * map.scale.y)
	
	# 设置新位置
	position = Vector2(random_x, random_y)


func _on_button_pressed():
	if not dragged:
		popup_panel.visible = true

func is_alive():
	return hp > 0


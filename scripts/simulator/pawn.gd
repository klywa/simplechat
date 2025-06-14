class_name Pawn
extends Node2D

@export var pawn_name: String
@export var moveable: bool = true
@export var max_speed: float = 100
@export_enum("BLUE", "RED", "NEUTRAL") var camp: String = "NEUTRAL"
@export_enum("CHARACTER", "BUILDING", "RESOURCE", "MONSTER", "MINION") var type: String = "CHARACTER"
@export_enum("上路", "打野", "中路", "辅助", "下路") var lane: String

@onready var button = $Button
var move_speed : float

var simulator : KoHSimulator
var map : KohMap
var dragging = false
var dragged = false
var drag_start = Vector2()
var drag_start_position = Vector2()

# 添加变量控制虚线显示
var show_target_line : bool = false
# 添加变量记录拖动悬停的目标
var hover_target : Pawn = null
# 添加变量控制检测区域圆形的显示
var show_detect_shape : bool = false

var map_rect 
var tile_size
var map_size

# 添加平滑移动所需的变量
var is_moving : bool = false
var move_start_position : Vector2 = Vector2()
var move_target_position : Vector2 = Vector2()
var move_progress : float = 0.0
# var move_duration : float = 0.5  # 移动持续时间为1秒

# var is_on_lane : bool = false

var kill_number : int = 0
var death_number : int = 0
var assist_number : int = 0

var move_target : Pawn = null
var force_move : bool = false
var under_command : bool = false
var command_game_index : int = 0

@onready var move_target_label := $MoveTarget

@onready var camp_color_flag := $CampColor
@onready var shield_flag := $ShieldFlag
@onready var lane_flag := $LaneFlag
@onready var name_label := $Name
@onready var sprite := $Sprite
@onready var popup_panel := $PopupPanel
@onready var minion_sprite := $MinionSprite

@onready var body_shape := $BodyArea
@onready var detect_shape := $DetectArea
@onready var detect_shape_collision_shape := $DetectArea/CollisionShape2D

@onready var health_bar := $HealthBar
@onready var hero_icon := $HeroIcon
@onready var hero_avatar := $HeroIcon/Avatar

@onready var move_target_dropdown := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer4/TargetDropdown
@onready var kill_target_dropdown := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/KillTarget
@onready var assist_dropdown := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Assist
@onready var submit_kill_button := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/KillSubmit

@onready var hp_editor := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/HP
@onready var money_editor := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Money
@onready var level_editor := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Level
@onready var nearby_text := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/NearbyText

@onready var revive_button := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ReviveButton

@onready var popup_panel_title := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/Title

@onready var skill_editor := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Skill
@onready var kda_info := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/KDA



var npc : NPC
var hp : int = 100
var level : int = 1
var money : int = 0
var revive_count_down : int = 0
var visible_to_blue : bool = true
var nearby_pawns : Array[Pawn] = []
var is_on_lane : bool = false
var tower_nearby_last_frame : bool = false

var origin_color

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

	simulator = get_parent().get_parent().get_parent()
	map = get_parent().get_parent()


	if not map.is_node_ready():
		await map.ready

	map_rect = map.ground_layer.get_used_rect()
	tile_size = map.ground_layer.tile_set.tile_size
	map_size = map_rect.size * tile_size
	
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_button_pressed)
	
	# 添加鼠标悬停和离开事件
	button.mouse_entered.connect(_on_button_mouse_entered)
	button.mouse_exited.connect(_on_button_mouse_exited)

	hp_editor.text_submitted.connect(_on_hp_editor_changed)
	level_editor.text_submitted.connect(_on_level_editor_changed)
	money_editor.text_submitted.connect(_on_money_editor_changed)
	skill_editor.text_submitted.connect(_on_skill_editor_changed)

	revive_button.pressed.connect(_on_revive_button_pressed)

	submit_kill_button.pressed.connect(_on_submit_kill_button_pressed)

	move_target_dropdown.item_selected.connect(_on_target_dropdown_item_selected)
	
	# 连接检测区域的信号
	detect_shape.area_entered.connect(_on_detect_area_entered)
	detect_shape.area_exited.connect(_on_detect_area_exited)

	move_speed = max_speed * scale.x

	match camp:
		"BLUE":
			camp_color_flag.color = Color.BLUE
			if npc == GameManager.player:
				hero_icon.color = Color.GREEN
				hero_icon.scale = Vector2(1.2, 1.2)
			else:
				hero_icon.color = Color.BLUE
		"RED":
			camp_color_flag.color = Color.RED
			hero_icon.color = Color.RED
		"NEUTRAL":
			camp_color_flag.color = Color.GRAY

	match type:
		"CHARACTER":
			moveable = true
			# pawn_name = lane
			if camp == "RED":
				visible_to_blue = false
			camp_color_flag.visible = false
			minion_sprite.visible = false
		"MINION":
			moveable = true
			minion_sprite.visible = true
			name_label.visible = false
			hero_icon.visible = false
			camp_color_flag.modulate.a = 0.5
			minion_sprite.modulate.a = 0.5
		"BUILDING":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			minion_sprite.visible = false
			camp_color_flag.modulate.a = 0.5
			health_bar.modulate.a = 0.0
		"RESOURCE":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			minion_sprite.visible = false
			camp_color_flag.modulate.a = 0.2
			health_bar.modulate.a = 0.0
		"MONSTER":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			minion_sprite.visible = false
			camp_color_flag.modulate.a = 0.2
			health_bar.modulate.a = 0.0
	name_label.text = pawn_name

func _show():
	name_label.text = pawn_name
	set_hero_avatar()

func load_npc(npc: NPC):
	self.npc = npc
	npc.pawn = self
	pawn_name = npc.hero_name
	lane = npc.hero_lane

	if npc == GameManager.player:
		hero_icon.color = Color.GREEN
		hero_icon.scale = Vector2(1.2, 1.2)
	else:
		match camp:
			"BLUE":
				hero_icon.color = Color.BLUE
			"RED":
				hero_icon.color = Color.RED
			"NEUTRAL":
				hero_icon.color = Color.GRAY
		hero_icon.scale = Vector2(1.0, 1.0)

	_show()

func init_pawn(pawn_info: Dictionary):
	var npc_name = pawn_info.get("npc_name", "")
	if type == "CHARACTER":
		if npc_name in GameManager.simulator.chat.members:
			npc = GameManager.simulator.chat.members[npc_name]
			load_npc(npc)
		elif npc_name in GameManager.simulator.chat.opponent_members:
			npc = GameManager.simulator.chat.opponent_members[npc_name]
			load_npc(npc)
		else:
			print("npc_name: ", npc_name, " not found")
	pawn_name = pawn_info.get("pawn_name", "")
	# print("pawn_name: ", pawn_name, " pawn_info: ", pawn_info.get("pawn_name", ""))
	camp = pawn_info.get("camp", "NEUTRAL")
	lane = pawn_info.get("lane", "")
	type = pawn_info.get("type", "CHARACTER")
	hp = pawn_info.get("hp", 100)
	level = pawn_info.get("level", 1)
	money = pawn_info.get("money", 0)
	kill_number = pawn_info.get("kill_number", 0)
	death_number = pawn_info.get("death_number", 0)
	assist_number = pawn_info.get("assist_number", 0)
	set_hero_avatar()
	global_position = Vector2(pawn_info.get("position_x", 0), pawn_info.get("position_y", 0))
	
func get_pawn_info() -> Dictionary:
	var n_name : String
	if npc != null:
		n_name = npc.npc_name
	else:
		n_name = "无"
	
	return {
		"npc_name": n_name,
		"pawn_name": pawn_name,
		"camp": camp,
		"lane": lane,
		"type": type,
		"hp": hp,
		"level": level,
		"money": money,
		"kill_number": kill_number,
		"death_number": death_number,
		"assist_number": assist_number,
		"position_x": global_position.x,
		"position_y": global_position.y,
		"move_target_name": move_target.get_unique_name() if move_target != null else "",
		"under_command": under_command,
	}

func set_pawn_info(pawn_info: Dictionary, tween_time = 0):
	if tween_time > 0 and pawn_info.get("hp", 100) > 0:
		var tween = create_tween()
		tween.tween_property(self, "hp", pawn_info.get("hp", 100), tween_time)
		tween.parallel().tween_property(self, "global_position", Vector2(pawn_info.get("position_x", 0), pawn_info.get("position_y", 0)), tween_time)
	else:
		hp = pawn_info.get("hp", 100)
		global_position = Vector2(pawn_info.get("position_x", 0), pawn_info.get("position_y", 0))
	level = pawn_info.get("level", 1)
	money = pawn_info.get("money", 0)
	kill_number = pawn_info.get("kill_number", 0)
	death_number = pawn_info.get("death_number", 0)
	assist_number = pawn_info.get("assist_number", 0)

	if type in ["BUILDING"]:
		if hp <= 0:
			camp_color_flag.color = Color.BLACK
		else:
			camp_color_flag.color = Color.BLUE if camp == "BLUE" else Color.RED

	var move_target_name = pawn_info.get("move_target_name", "")
	if move_target_name != "":
		for pawn in simulator.name_pawn_dict.values():
			if pawn.get_unique_name() == move_target_name:
				move_target = pawn
				break

	under_command = pawn_info.get("under_command", false)

func set_hero_avatar():
	# 尝试根据pawn_name加载英雄头像
	var avatar_path = "res://assets/avatars/hero_avatar/%s.webp" % pawn_name
	var avatar_path_2 = "res://assets/avatars/hero_avatar/%s.jpg" % pawn_name
	var default_path = "res://assets/avatars/hero_avatar/默认.webp"
	
	# 检查文件是否存在
	print("avatar_path: ", avatar_path)
	if FileAccess.file_exists(avatar_path):
		var texture = load(avatar_path)
		if texture:
			hero_avatar.texture = texture
	elif FileAccess.file_exists(avatar_path_2):
		var texture = load(avatar_path_2)
		if texture:
			hero_avatar.texture = texture
	else:
		# 如果找不到对应头像，使用默认头像
		print("default_path: ", default_path)
		var texture = load(default_path)
		if texture:
			hero_avatar.texture = texture
	
	# 缩放头像至96*96大小
	if hero_avatar.texture:
		var image = hero_avatar.texture.get_image()
		image.resize(96, 96)
		var new_texture = ImageTexture.create_from_image(image)
		hero_avatar.texture = new_texture

func _on_button_down():
	print("pawn_name: ", pawn_name, " corrdinate: ", get_corrdinate())
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
		
		# 如果有悬停目标，则设置为移动目标并恢复原位置
		if hover_target != null:
			move_target = hover_target
			force_move = true
			# 停止当前的平滑移动
			is_moving = false
			position = drag_start_position
			print("%s设置移动目标为%s" % [pawn_name, hover_target.pawn_name])
		else:
			# 如果没有悬停目标，则重新选择移动目标
			reselect_move_target()
			
		# 清除悬停目标
		hover_target = null
	else:
		dragged = false
	
	# 确保松开鼠标后虚线消失（除非鼠标悬停在按钮上）
	if not button.is_hovered():
		show_target_line = false
	queue_redraw()  # 触发重绘以更新显示

func get_command_name_string():
	if type == "CHARACTER":
		if camp == "BLUE":
			return "我方"+ pawn_name
		else:
			return "地方" + pawn_name
	else:
		return pawn_name

func _process(delta):

	if dragging:
		var new_pos = get_global_mouse_position() - drag_start
		
		new_pos.x = clamp(new_pos.x, 0, map_size.x * map.scale.x)
		new_pos.y = clamp(new_pos.y, 0, map_size.y * map.scale.y)
		position = new_pos
		
		# 如果移动距离超过阈值，标记为已拖动
		if position.distance_to(drag_start_position) > 1:
			dragged = true
			
		# 在拖动过程中检查是否悬停在其他pawn上
		hover_target = null
		for pawn in simulator.name_pawn_dict.values():
			if pawn != self and pawn.is_alive():
				var distance = get_global_mouse_position().distance_to(pawn.position)
				if distance < 50:  # 与_on_button_up中的阈值保持一致
					hover_target = pawn
					break
	
	# 处理平滑移动
	if is_moving:
		move_progress += delta / GameManager.main_view.simulation_delay
		if move_progress >= 1.0:
			# 移动完成
			position = move_target_position
			is_moving = false
		else:
			# 线性插值计算当前位置
			position = move_start_position.lerp(move_target_position, move_progress)

	if move_target == null or not move_target.is_alive():
		reselect_move_target()

	# 根据可见性状态更新显示
	if camp == "RED":
		if visible_to_blue:
			hero_icon.modulate.a = 1.0
			minion_sprite.modulate.a = 1.0
			camp_color_flag.modulate.a = 1.0
		else:
			hero_icon.modulate.a = 0.5
			minion_sprite.modulate.a = 0.5
			camp_color_flag.modulate.a = 0.5

	health_bar.value = hp
	move_target_label.text = move_target.get_unique_name() if move_target != null else ""

	if is_attackable():
		shield_flag.visible = false
	else:
		shield_flag.visible = true
		
	if is_on_lane:
		lane_flag.visible = true
	else:
		lane_flag.visible = false

	# 如果正在拖动且有悬停目标，或者有移动目标且显示目标线，则触发重绘
	# if (dragging and hover_target != null) or (show_target_line and move_target != null):
	queue_redraw()

func random_move():
	if dragging or is_moving:
		return

	# 生成随机方向
	var random_direction
	if move_target != null:
		# 如果有目标，朝目标方向移动
		var direction_to_target = (move_target.position - position).normalized()
		random_direction = direction_to_target
	else:
		# 如果没有目标或目标已死亡，随机移动
		random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		reselect_move_target()
	
	# 计算随机移动距离
	var random_distance = randf_range(move_speed * 0.5, move_speed)
	
	# 计算新位置
	var random_x = position.x + random_direction.x * random_distance
	var random_y = position.y + random_direction.y * random_distance
	
	# 确保位置在地图范围内
	random_x = clamp(random_x, 0, map_size.x * map.scale.x)
	random_y = clamp(random_y, 0, map_size.y * map.scale.y)
	
	# 设置移动参数
	move_start_position = position
	if type == "CHARACTER":
		move_target_position = Vector2(random_x, random_y)
	elif type == "MINION":
		match lane:
			"上路":
				if camp == "BLUE":
					move_target_position = restrict_move_angle(random_x, random_y, "x")
				else:
					move_target_position = restrict_move_angle(random_x, random_y, "y")
			"下路":
				if camp == "BLUE":
					move_target_position = restrict_move_angle(random_x, random_y, "y")
				else:
					move_target_position = restrict_move_angle(random_x, random_y, "x")
			"中路":
				move_target_position = Vector2(random_x, random_y)
	move_progress = 0.0
	is_moving = true

func restrict_move_angle(x, y, x_or_y: String):
	if x_or_y == "x":
		if abs(y) > 10:
			x = 0
	elif x_or_y == "y":
		if abs(x) > 10:
			y = 0
	return Vector2(x, y)

func has_friend_hero_nearby():
	for pawn in nearby_pawns:
		if pawn.type == "CHARACTER" and pawn.camp == camp:
			return true
	return false

func _on_button_pressed(force_open: bool = false):

	var npc_name = npc.npc_name if npc != null else "未知"
	var title_string = npc_name + " - " + pawn_name + "(" + lane + ")"
	title_string += " - 红方" if camp == "RED" else " - 蓝方"
	popup_panel_title.text = title_string

	if not dragged or not moveable or force_open:
		popup_panel.visible = true

		move_target_dropdown.clear()
		for p in simulator.name_pawn_dict.values():
			var unique_name = p.get_unique_name()
			move_target_dropdown.add_item(unique_name)
		
		# 选择当前的移动目标
		if move_target != null:
			var target_unique_name = move_target.get_unique_name()
			for i in range(move_target_dropdown.get_item_count()):
				if move_target_dropdown.get_item_text(i) == target_unique_name:
					move_target_dropdown.select(i)
					break

		kill_target_dropdown.clear()
		for p in simulator.name_pawn_dict.values():
			if p.camp != camp and p.is_attackable() and p.is_alive():
				var unique_name = p.get_unique_name()
				kill_target_dropdown.add_item(unique_name)
	
		for p in simulator.name_pawn_dict.values():
			if p.camp == camp and p.type == "CHARACTER" and p != self:
				var unique_name = p.get_unique_name()
				var found = false
				for i in range(assist_dropdown.get_item_count()):
					if assist_dropdown.get_item_text(i) == unique_name:
						found = true
						break
				
				if not found:
					assist_dropdown.add_item(unique_name)
	
		hp_editor.text = str(hp)
		level_editor.text = str(level)
		money_editor.text = str(money)
		if npc != null:
			skill_editor.text = str(npc.skill_level)
		else:
			skill_editor.text = "0"

		nearby_text.text = get_nearby_string()
		kda_info.text = "击杀：%d 死亡：%d 助攻：%d" % [kill_number, death_number, assist_number]

func is_alive():
	return hp > 0

func get_unique_name():
	if type == "CHARACTER":
		var prefix = "红" if camp == "RED" else "蓝"
		return prefix + "-" + pawn_name
	else:
		return pawn_name

# 当其他pawn进入检测区域时调用
func _on_detect_area_entered(area: Area2D) -> void:
	# 检查进入的区域是否是另一个pawn的body_shape
	if area.get_parent() is Pawn and area.name == "BodyArea":
		var other_pawn = area.get_parent() as Pawn
		if other_pawn != self and not nearby_pawns.has(other_pawn):
			nearby_pawns.append(other_pawn)
			# print("%s检测到%s进入范围" % [pawn_name, other_pawn.pawn_name])
			
			# 如果自己是RED阵营，且进入的pawn是BLUE阵营
			if camp == "RED" and other_pawn.camp == "BLUE":
				if not visible_to_blue:
					visible_to_blue = true
					# 更新可见性
					minion_sprite.modulate.a = 1.0
					camp_color_flag.modulate.a = 1.0
					# print("%s被BLUE阵营发现，变为可见" % pawn_name)

# 当其他pawn离开检测区域时调用
func _on_detect_area_exited(area: Area2D) -> void:
	# 检查离开的区域是否是另一个pawn的body_shape
	if area.get_parent() is Pawn and area.name == "BodyArea":
		var other_pawn = area.get_parent() as Pawn
		if nearby_pawns.has(other_pawn):
			nearby_pawns.erase(other_pawn)
			# print("%s检测到%s离开范围" % [pawn_name, other_pawn.pawn_name])
			
			# 如果自己是RED阵营，且离开的pawn是BLUE阵营
			if camp == "RED" and other_pawn.camp == "BLUE":
				# 检查nearby_pawns中是否还有其他BLUE阵营的pawn
				var has_blue_pawn = false
				for pawn in nearby_pawns:
					if pawn.camp == "BLUE":
						has_blue_pawn = true
						break
				
				# 如果没有其他BLUE阵营的pawn，则变为不可见
				if not has_blue_pawn:
					visible_to_blue = false
					# 立即更新可见性
					minion_sprite.modulate.a = 0.5
					camp_color_flag.modulate.a = 0.5
					# print("%s附近没有BLUE阵营单位，变为不可见" % pawn_name)

func send_message(message: String):
	simulator.chat.add_message(GameManager.system, message, {}, true, true)

func has_monster_nearby():
	for p in nearby_pawns:
		if p.type == "MONSTER" and p.is_alive():
			return true
	return false

func killed_by(pawn: Pawn, assist_pawns: Array = []):

	var max_money

	if pawn.type == "BUILDING" and assist_pawns.size() > 0:
		var random_index = randi() % assist_pawns.size()
		pawn = assist_pawns[random_index]
		assist_pawns.remove_at(random_index)

	match type:
		"CHARACTER":
			if level <= 3:
				max_money = 225
			elif level <= 7:
				max_money = 250
			elif level <= 15:
				max_money = 275
			elif level <= 20:
				max_money = 300
		"BUILDING":
			max_money = 200
		"MONSTER":
			max_money = 100
		"RESOURCE":
			max_money = 100
		"MINION":
			max_money = 200

	pawn.money += max_money
	for p in assist_pawns:
		p.money += max_money * 0.3

	if type == "BUILDING":
		for p in simulator.name_pawn_dict.values():
			if p.type == "CHARACTER" and p.camp != camp:
				p.money += randi() % max_money
			
	
	if type == "CHARACTER":
		death_number += 1
		pawn.kill_number += 1
	
		for p in assist_pawns:
			p.assist_number += 1

	hp = 0
	var msg = ""
	var self_name = ""
	if npc != null:
		self_name = npc.npc_name + "-" + pawn_name
	else:
		self_name = pawn_name
	if camp == "BLUE":
		if type in ["BUILDING", "MONSTER"]:
			self_name = pawn_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			self_name = "<我方-" + self_name + ">"
	elif camp == "RED":
		if type in ["BUILDING", "MONSTER"]:
			self_name = pawn_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			self_name = "<敌方-" + self_name + ">"
	elif camp == "NEUTRAL":
		self_name = pawn_name.replace("红方", "敌方").replace("蓝方", "我方")
	
	var killer_name = ""
	if pawn.npc != null:
		killer_name = pawn.npc.npc_name + "-" + pawn.pawn_name
	else:
		killer_name = pawn.pawn_name

	if pawn.camp == "BLUE":
		if pawn.type in ["BUILDING", "MONSTER"]:
			killer_name = killer_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			killer_name = "<我方-" + killer_name + ">"
	elif pawn.camp == "RED":
		if pawn.type in ["BUILDING", "MONSTER"]:
			killer_name = killer_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			killer_name = "<敌方-" + killer_name + ">"


	var assist_msg = ""

	if assist_pawns.size() > 0:
		assist_msg = "，参与助攻的有"
		var assist_names = []
		for p in assist_pawns:
			var tmp_name = ""
			if p.npc != null:
				tmp_name = p.npc.npc_name + "-" + p.pawn_name
			else:
				tmp_name = p.pawn_name
			if p.camp == "BLUE":
				tmp_name = "<我方-" + tmp_name + ">"
			else:
				tmp_name = "<敌方-" + tmp_name + ">"
			assist_names.append(tmp_name)
		assist_msg += "、".join(assist_names)
		assist_msg = assist_msg + "。"

	match type:
		"CHARACTER":
			match camp:
				"RED":
					msg = "%s击杀了%s%s（位置：%s）" % [killer_name, self_name, assist_msg, get_region()]
				"BLUE":
					msg = "%s被%s击杀%s（位置：%s）" % [self_name, killer_name, assist_msg, get_region()]
				"NEUTRAL":
					if pawn.camp == "RED":
						msg = "%s击杀了%s。" % [killer_name, self_name]
					else:
						msg = "%s击杀了%s。" % [killer_name, self_name]
		"BUILDING":
			match camp:
				"BLUE":
					msg = "%s被%s摧毁。" % [self_name, killer_name]
				"RED":
					msg = "%s摧毁了%s。" % [killer_name, self_name]
				"NEUTRAL":
					msg = "%s摧毁了%s。" % [killer_name, self_name]
		"MONSTER":
			match camp:
				"NEUTRAL":
					msg = "%s击杀了%s。" % [killer_name, self_name]
				"BLUE":
					msg = "%s被%s击杀。" % [self_name, killer_name]
				"RED":
					msg = "%s击杀了%s。" % [killer_name, self_name]

	die()
	send_message(msg)

func take_damage(damage: int):
	var origin_hp = hp
	hp -= damage
	if hp <= 0:
		die()
	
	if origin_hp >= 50 and hp < 50:
		if force_move and not (move_target in nearby_pawns):
			if hp < 30:
				reselect_move_target()
			else:
				pass
		else:
			reselect_move_target()

func heal(heal: int):
	var origin_hp = hp
	hp += heal
	if hp > 100 and type != "BUILDING":
		hp = 100
	
	if origin_hp < 100 and hp >= 100:
		if force_move and not (move_target in nearby_pawns):
			pass
		else:
			reselect_move_target()
	elif origin_hp == 100 and (move_target in nearby_pawns):
		reselect_move_target()

func reselect_move_target():

	if under_command:
		return

	force_move = false

	# select_move_target()
	# return

	move_target = null
	if type != "CHARACTER":
		return 
	
	# 如果血量大于50，选择非我方pawn作为目标，否则选择我方pawn作为目标
	if hp > 50:
		var potential_targets = []
		if lane == "辅助":
			for pawn in simulator.name_pawn_dict.values():
				if pawn.camp == camp and pawn.is_alive() and pawn.type == "CHARACTER" and pawn != self:
					potential_targets.append(pawn)
		else:
			for pawn in simulator.name_pawn_dict.values():
				if pawn.camp != camp and pawn.is_alive() and pawn.is_attackable() and pawn != self:
					potential_targets.append(pawn)
		
		move_target = select_target_by_distance(potential_targets)
	else:
		# 寻找我方的pawn
		var potential_targets = []
		for pawn in simulator.name_pawn_dict.values():
			if pawn.camp == camp and pawn.is_alive() and pawn != self:
				potential_targets.append(pawn)
		
		move_target = select_target_by_distance(potential_targets)
	
func select_target_by_distance(targets: Array):
	if targets.size() == 0:
		return null
		
	var weights = []
	var total_weight = 0.0
	
	# 调试信息
	# print("选择目标，当前位置：", position)
	
	# var debug_str = pawn_name + "距离："
	for target in targets:
		var distance = position.distance_to(target.position)
		# 距离越近，权重越大，使用更强的距离惩罚
		var weight = 1.0 / pow(max(distance/1000, 0.1), 2) # 使用三次方权重，更强调近距离目标
		weights.append(weight)
		total_weight += weight
		# debug_str += "目标:%s 距离:%.2f 权重:%.4f | " % [target.pawn_name, distance, weight]
	# print(debug_str + "总权重:%.4f" % total_weight)
	
	# 如果总权重为0（极端情况），直接选择最近的目标
	if total_weight <= 0.0001:
		var closest_target = targets[0]
		var min_distance = position.distance_to(closest_target.position)
		
		for target in targets:
			var distance = position.distance_to(target.position)
			if distance < min_distance:
				min_distance = distance
				closest_target = target
		
		# print("使用最近目标：", closest_target.pawn_name)
		return closest_target
	
	# 根据权重随机选择目标
	var random_value = randf() * total_weight
	var current_sum = 0.0
	
	for i in range(targets.size()):
		current_sum += weights[i]
		if random_value <= current_sum:
			# print("选择了目标：", targets[i].pawn_name)
			return targets[i]
	
	# 保险起见，如果没有选中任何目标，返回第一个
	# print("未选中任何目标，返回第一个")
	return targets[0] if targets.size() > 0 else null

func _on_submit_kill_button_pressed():
	var target_name = kill_target_dropdown.text
	
	var killed_pawn = simulator.name_pawn_dict.get(target_name, null)

	var assist_pawn_names = assist_dropdown.text.split(",")
	var assist_pawns = []
	for p_name in assist_pawn_names:
		var p = simulator.name_pawn_dict.get(p_name, null)
		if p != null:
			assist_pawns.append(p)

	if killed_pawn != null:
		killed_pawn.killed_by(self, assist_pawns)
		simulator.update_replay_info()

	popup_panel.visible = false

func _on_hp_editor_changed(value: String):
	hp = int(value)
	if hp <= 0:
		die()

func _on_level_editor_changed(value: String):
	level = int(value)

func _on_money_editor_changed(value: String):
	money = int(value)

func _on_skill_editor_changed(value: String):
	npc.skill_level = int(value)

func _on_revive_button_pressed():
	revive()
	popup_panel.visible = false

func _on_target_dropdown_item_selected(index: int):
	var target_name = move_target_dropdown.get_item_text(index)
	var target_pawn = simulator.name_pawn_dict.get(target_name, null)
	if target_pawn != null:
		move_target = target_pawn
		# 如果正在平滑移动，停止移动
		if is_moving:
			is_moving = false

func get_nearby_string():
	var status_string = "状态：" + get_self_status()
	var nearby_friend_string = "附近友方英雄："
	var nearby_enemy_string = "附近敌方英雄："
	var nearby_friend_building_string = "附近友方建筑物："
	var nearby_enemy_building_string = "附近敌方建筑物："
	var nearby_monster_string = "附近野怪："
	
	# 将附近pawns按类型加入对应string，逗号隔开
	for p in nearby_pawns:
		if p.type == "CHARACTER":
			if p.camp == camp:
				nearby_friend_string += p.pawn_name + "，"
			else:
				nearby_enemy_string += p.pawn_name + "，"
		elif p.type == "BUILDING":
			if p.camp == camp:
				nearby_friend_building_string += p.pawn_name + "，"
			else:
				nearby_enemy_building_string += p.pawn_name + "，"
		elif p.type == "MONSTER":
			nearby_monster_string += p.pawn_name + "，"
	
	# 移除末尾的逗号并添加句号
	nearby_friend_string = nearby_friend_string.rstrip("，") + "。"
	nearby_enemy_string = nearby_enemy_string.rstrip("，") + "。"
	nearby_friend_building_string = nearby_friend_building_string.rstrip("，") + "。"
	nearby_enemy_building_string = nearby_enemy_building_string.rstrip("，") + "。"
	nearby_monster_string = nearby_monster_string.rstrip("，") + "。"
	
	# 组合所有字符串
	var result = status_string + "\n" + nearby_friend_string + "\n" + nearby_enemy_string + "\n" + nearby_friend_building_string + "\n" + nearby_enemy_building_string + "\n" + nearby_monster_string
	return result
	

func set_init_move_target():
	var opposite_camp_string = "红方" if camp == "BLUE" else "蓝方"
	var camp_string = "红方" if camp == "RED" else "蓝方"

	match lane:
		"打野":
			# 获取自己方的红Buff和蓝Buff
			var blue_buff = simulator.name_poi_dict[camp_string + "蓝Buff"]
			var red_buff = simulator.name_poi_dict[camp_string + "红Buff"]
			
			# 计算到两个Buff的距离
			var distance_to_blue = position.distance_to(blue_buff.position)
			var distance_to_red = position.distance_to(red_buff.position)
			
			# 选择距离较近的Buff作为移动目标
			if distance_to_blue <= distance_to_red:
				move_target = blue_buff
			else:
				move_target = red_buff
		"辅助":
			reselect_move_target()
		_:
			# 寻找对方阵营中与自己相同位置的英雄作为移动目标
			var target_found = false
			for pawn in simulator.name_pawn_dict.values():
				if pawn.is_alive() and pawn.camp != camp and pawn.lane == lane and pawn.type == "CHARACTER":
					move_target = pawn
					target_found = true
					break
			
			# 如果没有找到对应位置的敌方英雄，则选择对方水晶或其他目标
			if not target_found:
				reselect_move_target()
		
func die():
	hp = 0
	if type == "CHARACTER":
		revive_count_down = 10
	elif type == "MONSTER":
		revive_count_down = 40

	# 停止当前的平滑移动
	is_moving = false

	match type:
		"CHARACTER":
			if camp == "RED":
				position = simulator.name_poi_dict["红方泉水"].position + Vector2(randf_range(-simulator.init_random_range, simulator.init_random_range), randf_range(-simulator.init_random_range, simulator.init_random_range))
				position.x = clamp(position.x, 0, map_size.x * map.scale.x)
				position.y = clamp(position.y, 0, map_size.y * map.scale.y)
			else:
				position = simulator.name_poi_dict["蓝方泉水"].position + Vector2(randf_range(-simulator.init_random_range, simulator.init_random_range), randf_range(-simulator.init_random_range, simulator.init_random_range))
				position.x = clamp(position.x, 0, map_size.x * map.scale.x)
				position.y = clamp(position.y, 0, map_size.y * map.scale.y)
		"BUILDING":
			# sprite.visible = false
			camp_color_flag.color = Color.BLACK
		"MONSTER":
			# sprite.modulate.a = 0.05
			camp_color_flag.color = Color.BLACK


func revive():
	hp = 100
	if type == "BUILDING":
		if pawn_name.contains("一塔"):
			hp += 50
		elif pawn_name.contains("二塔"):
			hp += 100
		elif pawn_name.contains("高地塔"):
			hp += 200
		elif pawn_name.contains("水晶"):
			hp += 100	
	# print(pawn_name, "复活后血量：", hp)	
	
	revive_count_down = 0
	match type:
		"BUILDING":
			# sprite.visible = true
			if camp == "RED":
				camp_color_flag.color = Color.RED
			else:
				camp_color_flag.color = Color.BLUE
		"MONSTER":
			# sprite.modulate.a = 0.2
			camp_color_flag.color = Color.GRAY
		"CHARACTER":
			reselect_move_target()
	
func get_near_by_pawns():
	var result = {
		"hero":{
			"BLUE": [],
			"RED": [],
		},
		"tower":{
			"BLUE": [],
			"RED": [],
		},
	}
	for p in nearby_pawns:
		if p.is_alive():
			if p.type == "CHARACTER":
				result["hero"][p.camp].append(p)
			elif p.type == "BUILDING":
				result["tower"][p.camp].append(p)
	return result

func get_region():
	var closest = null
	var min_distance = 100000
	for p in simulator.name_poi_dict.values():
		var distance = position.distance_to(p.position)
		if distance < min_distance:
			min_distance = distance
			closest = p
	if closest.type == "MONSTER":
		if closest.pawn_name.contains("Buff"):
			return closest.pawn_name.replace("红方", "敌方").replace("蓝方", "我方") + "野区"
		else:
			return closest.pawn_name + "区域"
	else:
		return closest.pawn_name.replace("红方", "敌方").replace("蓝方", "我方")

func get_health():

	if not is_alive():
		if type == "BUILDING":
			return "被摧毁"
		else:
			return "已阵亡"
	elif hp < 20:
		return "血量低"
	elif hp < 80:
		return "血量中等"
	elif hp < 100:
		return "血量健康"
	else:
		return "血量全满"

func get_kda():
	var kda = (kill_number + assist_number + 0.01) / (death_number + 0.01)
	var kda_string = "（击杀：" + str(kill_number) + "，助攻：" + str(assist_number) + "，死亡：" + str(death_number) + "）"
	if kda < 0.5:
		return "战绩很差" + kda_string
	elif kda < 2:
		return "战绩一般" + kda_string
	elif kda < 4:
		return "战绩不错" + kda_string
	else:
		return "战绩超神" + kda_string

func get_money():
	if type == "CHARACTER":
		return "当前经济：" + str(money)
	elif type == "BUILDING":
		return ""
	elif type == "MONSTER":
		return ""

func set_on_lane():

	if type != "CHARACTER":
		is_on_lane = false
		return

	var nearby_buildings = []
	for p in nearby_pawns:
		if p.type == "BUILDING" and p.is_attackable() and p.pawn_name.contains("塔"):
			nearby_buildings.append(p)
	
	# 如果附近有可攻击的建筑物，50%概率返回"正在和小兵交战"
	if nearby_buildings.size() > 0:
		if is_on_lane:
			# 如果有敌方英雄或建筑在附近，则不处于线上
			var enemy_nearby = false
			for p in nearby_pawns:
				if p.type in ["CHARACTER", "BUILDING"] and p.camp != camp:
					enemy_nearby = true
					break
			if enemy_nearby:
				if randf() < 0.5:
					is_on_lane = false
		elif not tower_nearby_last_frame:
			if randf() < 0.7 + (npc.skill_level / 10.0) * 0.3:
				is_on_lane = true
		else:
			if randf() < 0.2:
				is_on_lane = true
		tower_nearby_last_frame = true		
	else:
		if move_target.type == "BUILDING" and move_target.camp != camp:
			pass
		else:
			is_on_lane = false
		tower_nearby_last_frame = false


func get_on_lane():
	# 获取附近的建筑物
	if is_on_lane:
		return "附近有兵线"
	
	# 检查附近是否有中立单位（野怪）
	for p in nearby_pawns:
		if p.camp == "NEUTRAL":
			return "附近有野怪"

	# 默认返回空字符串
	return "附近没有兵线"

func get_corrdinate():
	# 假定map的左下角坐标为(-60.0, -60.0)，右上角坐标为(60.0, 60.0)，将自己相对于map的坐标映射到该坐标体系下，输出(x,y)
	var map_width = map_size.x * map.scale.x
	var map_height = map_size.y * map.scale.y
	
	# 将当前位置映射到[-60, 60]的范围
	var mapped_x = (position.x / map_width) * 120.0 - 60.0
	# 修改y轴映射，使其从下到上增加
	var mapped_y = 60.0 - (position.y / map_height) * 120.0

	if type == "BUILDING":
		mapped_x += randf_range(-0.5, 0.5)
		mapped_y += randf_range(-0.5, 0.5)
	
	return "(%.1f, %.1f)" % [mapped_x, mapped_y]
	


	

func is_attackable():
	if type == "BUILDING":
		match pawn_name:
			"红方泉水": return false
			"蓝方泉水": return false
			"红方水晶":
				return not simulator.name_poi_dict.get("红方上路高地塔", null).is_alive() or not simulator.name_poi_dict.get("红方中路高地塔", null).is_alive() or not simulator.name_poi_dict.get("红方下路高地塔", null).is_alive()
			"蓝方水晶":
				return not simulator.name_poi_dict.get("蓝方上路高地塔", null).is_alive() or not simulator.name_poi_dict.get("蓝方中路高地塔", null).is_alive() or not simulator.name_poi_dict.get("蓝方下路高地塔", null).is_alive()
			"红方上路高地塔":
				return not simulator.name_poi_dict.get("红方上路一塔", null).is_alive() and not simulator.name_poi_dict.get("红方上路二塔", null).is_alive()
			"蓝方上路高地塔":
				return not simulator.name_poi_dict.get("蓝方上路一塔", null).is_alive() and not simulator.name_poi_dict.get("蓝方上路二塔", null).is_alive()
			"红方中路高地塔":
				return not simulator.name_poi_dict.get("红方中路一塔", null).is_alive() and not simulator.name_poi_dict.get("红方中路二塔", null).is_alive()
			"蓝方中路高地塔":
				return not simulator.name_poi_dict.get("蓝方中路一塔", null).is_alive() and not simulator.name_poi_dict.get("蓝方中路二塔", null).is_alive()
			"红方下路高地塔":
				return not simulator.name_poi_dict.get("红方下路一塔", null).is_alive() and not simulator.name_poi_dict.get("红方下路二塔", null).is_alive()
			"蓝方下路高地塔":
				return not simulator.name_poi_dict.get("蓝方下路一塔", null).is_alive() and not simulator.name_poi_dict.get("蓝方下路二塔", null).is_alive()
			"红方上路二塔":
				return not simulator.name_poi_dict.get("红方上路一塔", null).is_alive()
			"蓝方上路二塔":
				return not simulator.name_poi_dict.get("蓝方上路一塔", null).is_alive()
			"红方中路二塔":
				return not simulator.name_poi_dict.get("红方中路一塔", null).is_alive()
			"蓝方中路二塔":
				return not simulator.name_poi_dict.get("蓝方中路一塔", null).is_alive()
			"红方下路二塔":
				return not simulator.name_poi_dict.get("红方下路一塔", null).is_alive()
			"蓝方下路二塔":
				return not simulator.name_poi_dict.get("蓝方下路一塔", null).is_alive()
			_:
				return true
	else:
		return true

func get_in_battle():
	var in_battle = false
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp != camp:
			in_battle = true
			break
	
	if in_battle:
		if camp == "BLUE":
			return "正在与敌方交战。"
		else:
			return "正在与我方交战。"
	else:
		return ""

func get_self_status():
	var status = ""
	var npc_name = npc.npc_name if npc != null else "未知"

	if camp == "BLUE":
		var name_string = "“" + npc_name + "”"
		status += name_string + "使用的英雄是" + pawn_name + "（" + lane + "）。"
		status += name_string + "" + get_health() + "。"
		status += name_string + get_kda() + "。"
		if get_in_battle() != "":
			status += name_string + get_in_battle()
		if get_on_lane() != "":
			status += name_string + get_on_lane() + "。"
		status += name_string + "在" + get_region() + "附近。"
		status += name_string + get_money() + "。"
	elif camp == "RED":
		var name_string = "“" + npc_name + "”"
		status += name_string + "使用的英雄是" + pawn_name + "（" + lane + "）。"
		status += name_string + "" + get_health() + "。"
		status += name_string + get_kda() + "。"
		if get_in_battle() != "":
			status += name_string + get_in_battle()
		if get_on_lane() != "":
			status += name_string + get_on_lane() + "。"
		status += name_string + "在" + get_region() + "附近。"
		status += name_string + get_money() + "。"
	return status


func get_status(visible=true):
	var status = ""
	var npc_name = npc.npc_name if npc != null else "未知"

	if camp == "BLUE":
		var name_string = "<我方-" + npc_name + "-" + pawn_name + ">"
		status += name_string + "是我方" + lane + "，"
		status += get_health() + "，"
		status += get_kda() + "，"
		status += "在" + get_region() + "附近，坐标" + get_corrdinate() + "。"
		status += name_string + get_in_battle()
		if get_on_lane() != "":
			status += get_on_lane() + "。"
		status += get_money() + "。"

	elif camp == "RED":
		var name_string = "<敌方-" + npc_name + "-" + pawn_name + ">"
		status += name_string + "是敌方" + lane + "，"
		if visible:
			status += get_health() + "，"
		status += get_kda() + "，"
		if visible:
			status += "在" + get_region() + "附近，坐标" + get_corrdinate() + "。"
			status += name_string + get_in_battle()
			if get_on_lane() != "":
				status += get_on_lane() + "。"
			else:
				status += ""
		status += get_money() + "。"
	return status
		

func get_player_status():
	var player_pawn = GameManager.player.pawn
	var status = player_pawn.get_status()

	# if player_pawn in nearby_pawns:
	# 	status += ""玩家" + "在" + "" + npc.npc_name + "" + "附近。"

	return status


func get_in_sight_status():
	var status = ""
	var npc_name = npc.npc_name if npc != null else "未知"

	if camp == "BLUE":
		var name_string = "<我方-" + npc_name + "-" + pawn_name + ">"
		status += name_string + "是我方" + lane + "，在" + get_region() + "附近，" + get_health() + "。"
	elif camp == "RED":
		var name_string = "<敌方-" + npc_name + "-" + pawn_name + "->"
		status += name_string + "是敌方" + lane + "，在" + get_region() + "附近，" + get_health() + "。"

	return status

func get_builing_status():
	var destroyed_status = "被摧毁的防御塔："
	var remaining_status = "未被摧毁的防御塔："

	for p in simulator.name_poi_dict.values():
		# print(p.pawn_name)
		if p.type == "BUILDING" and p.pawn_name.contains("塔"):
			if p.is_alive():
				remaining_status += p.pawn_name.replace("红方", "敌方").replace("蓝方", "我方") + "，"
			else:
				destroyed_status += p.pawn_name.replace("红方", "敌方").replace("蓝方", "我方") + "，"
	destroyed_status = destroyed_status.rstrip("，") + "。"
	remaining_status = remaining_status.rstrip("，") + "。"
	return destroyed_status + "\n" + remaining_status

func get_dead_pawns():
	var dead_heros = "我方阵亡英雄："
	var opponent_dead_heros = "敌方阵亡英雄："

	for p in simulator.name_pawn_dict.values():
		if p.type == "CHARACTER" and p.camp == camp and not p.is_alive():
			dead_heros += p.pawn_name + "，"
		elif p.type == "CHARACTER" and p.camp != camp and not p.is_alive():
			opponent_dead_heros += p.pawn_name + "，"
	
	dead_heros = dead_heros.rstrip("，") + "。"
	opponent_dead_heros = opponent_dead_heros.rstrip("，") + "。"
	return dead_heros + "\n" + opponent_dead_heros

func get_scenario_stirng():
	var scenario = "[地图信息]\n"
	scenario += simulator.get_map_info_string() + "\n"

	scenario += "\n[总体态势]\n"
	scenario += "我方人头数：" + str(simulator.blue_team_total_kill) + "，敌方人头数：" + str(simulator.red_team_total_kill) + "。\n"
	scenario += "我方总经济：" + str(simulator.blue_team_total_money) + "，敌方总经济：" + str(simulator.red_team_total_money) + "。\n"
	
	scenario += "\n[玩家情况]\n"
	scenario += get_player_status() + "\n"
	
	scenario += "\n[附近英雄]\n"
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp == camp:
			scenario += p.get_status() + "\n"
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp != camp:
			scenario += p.get_status() + "\n"

	scenario += "\n[不在附近但在视野可见的英雄]\n"
	for p in simulator.name_pawn_dict.values():
		if p.type == "CHARACTER" and p not in nearby_pawns and p.visible_to_blue and p != self:
			scenario += p.get_status() + "\n"

	scenario += "\n[其他英雄]\n"
	for p in simulator.name_pawn_dict.values():
		if p.type == "CHARACTER" and p not in nearby_pawns and !p.visible_to_blue and p != self:
			scenario += p.get_status(false) + "\n"

	scenario += "\n[阵亡英雄]\n"
	scenario += get_dead_pawns() + "\n"

	scenario += "\n[防御塔状态]\n"
	scenario += get_builing_status() + "\n"
	
	
	return scenario

# 鼠标进入按钮时显示虚线
func _on_button_mouse_entered():
	# 只有在非拖动状态下才显示虚线
	if not dragging:
		show_target_line = true
		show_detect_shape = true  # 显示检测区域圆形
		queue_redraw()  # 触发重绘


# 鼠标离开按钮时隐藏虚线
func _on_button_mouse_exited():
	# 无论是否在拖动，都隐藏虚线
	show_target_line = false
	show_detect_shape = false  # 隐藏检测区域圆形
	queue_redraw()  # 触发重绘

# 重写_draw方法来绘制虚线
func _draw():
	# 如果需要显示检测区域圆形
	if show_detect_shape:
		# 获取检测区域的半径
		var collision_shape = detect_shape_collision_shape
		var radius = 0
		
		# 假设碰撞形状是CircleShape2D
		if collision_shape.shape is CircleShape2D:
			radius = collision_shape.shape.radius
		
		# 根据阵营选择颜色
		var circle_color
		match camp:
			"BLUE":
				circle_color = Color(0, 0, 1, 0.2)  # 半透明蓝色
			"RED":
				circle_color = Color(1, 0, 0, 0.2)  # 半透明红色
			"NEUTRAL":
				circle_color = Color(0.5, 0.5, 0.5, 0.2)  # 半透明灰色
		
		# 绘制半透明圆形
		draw_circle(Vector2.ZERO, radius, circle_color)
	
	# 如果正在拖动且有悬停目标
	if dragging and hover_target != null:
		# 绘制从起始位置到悬停目标的虚线
		var start_pos = to_local(drag_start_position)
		var target_pos = to_local(hover_target.global_position)
		
		# 根据阵营选择颜色
		var line_color
		match camp:
			"BLUE":
				line_color = Color.BLUE
			"RED":
				line_color = Color.RED
			"NEUTRAL":
				line_color = Color.GRAY
		
		# 绘制虚线
		custom_draw_dashed_line(start_pos, target_pos, line_color, 2.0, 5.0)
	# 如果显示目标线且有移动目标
	elif show_target_line and move_target != null and move_target.is_alive():
		# 获取目标位置（相对于当前pawn的局部坐标）
		var target_pos = to_local(move_target.global_position)
		
		# 根据阵营选择颜色
		var line_color
		match camp:
			"BLUE":
				line_color = Color.BLUE
			"RED":
				line_color = Color.RED
			"NEUTRAL":
				line_color = Color.GRAY
		
		# 绘制虚线
		custom_draw_dashed_line(Vector2.ZERO, target_pos, line_color, 2.0, 5.0)

	elif under_command and move_target != null and move_target.is_alive():
		# 获取目标位置（相对于当前pawn的局部坐标）
		var target_pos = to_local(move_target.global_position)
		
		# 根据阵营选择颜色
		var line_color
		match camp:
			"BLUE":
				line_color = Color.BLUE
			"RED":
				line_color = Color.RED
			"NEUTRAL":
				line_color = Color.GRAY
		
		# 绘制虚线
		custom_draw_dashed_line(Vector2.ZERO, target_pos, line_color, 2.0, 5.0)

# 绘制虚线的辅助方法
func custom_draw_dashed_line(from, to, color, width, dash_length):
	var length = from.distance_to(to)
	var normal = (to - from).normalized()
	var dash_step = normal * dash_length
	
	var current = from
	var drawn = 0.0
	
	while drawn < length:
		var next = current + dash_step
		if drawn + dash_length > length:
			next = to
		
		draw_line(current, next, color, width)
		
		# 移动到下一段虚线的起点（跳过一段空白）
		current = next + dash_step
		drawn += dash_length * 2.0
		
		# 确保不会超出总长度
		if drawn >= length:
			break

# 计算pawn的战斗强度，仅适用于CHARACTER类型的pawn
# 强度取值范围说明：
# - 理论最小值：0（新角色，无经济，无击杀，技能水平为0）
# - 理论最大值：约45-50（满级，满经济，高KDA，最高技能水平，团队加成）
# - 一般范围：10-30（普通游戏中的常见取值范围）
func calculate_power() -> float:
	# 如果不是CHARACTER类型，返回0
	if type != "CHARACTER":
		return 0.0
	
	# 基础分数
	var power_score: float = 0.0
	
	# 1. 考虑英雄等级 (权重: 20%)
	# 等级越高，强度越大，呈线性关系
	var level_factor: float = level * 3.0  # 每级提供3点强度
	power_score += level_factor * 0.20     # 最高贡献：约12点(假设最高20级)
	
	# 2. 考虑经济 (权重: 25%)
	# 经济越高，装备越好，强度越大
	var money_factor: float = min(money / 12000.0, 1.0)  # 将经济归一化，最高12000
	power_score += money_factor * 40.0 * 0.25  # 满经济提供10点强度
	
	# 3. 考虑KDA (权重: 15%)
	# KDA越高，玩家越强
	var kda: float = (kill_number + assist_number * 0.5) / max(death_number, 1.0)
	var kda_factor: float = min(kda / 5.0, 1.0)  # 将KDA归一化，最高5.0
	power_score += kda_factor * 30.0 * 0.15  # 满KDA提供4.5点强度
	
	# 4. 考虑NPC技能水平 (权重: 40%)
	# NPC技能水平是最重要的因素
	var skill_level_factor: float = 0.0
	if npc != null:
		skill_level_factor = npc.skill_level / 10.0  # 假设skill_level是0-10的值
	else:
		skill_level_factor = 0.5  # 如果没有NPC，给一个中等水平
	power_score += skill_level_factor * 50.0 * 0.40  # 满技能水平提供20点强度
	
	# 额外因素：如果在战斗中，不考虑血量因素，只考虑是否有战斗加成
	if get_in_battle() != "":
		# 战斗状态下可能有战术优势
		power_score *= 1.05  # 增加5%的战斗意识加成
	
	# 额外因素：如果有友方英雄在附近，增加强度
	var nearby_friends = 0
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp == camp and p != self:
			nearby_friends += 1
	
	# 每个友方英雄提供10%的额外强度，最多30%
	if nearby_friends > 0:
		power_score *= (1.0 + min(nearby_friends * 0.1, 0.3))
	
	# 返回最终计算的强度值，四舍五入到一位小数
	return round(power_score * 10) / 10.0


# 智能选择移动目标函数
func select_move_target() -> Pawn:
	# 如果不是CHARACTER类型，不需要选择移动目标
	if type != "CHARACTER":
		return null
		
	# 获取自身战力
	var self_power = calculate_power()
	
	# 获取所有可能的目标
	var all_pawns = simulator.name_pawn_dict.values()
	var potential_targets = []
	
	# 根据当前状态决定行为策略
	var strategy = "ATTACK"  # 默认策略是进攻
	
	# 1. 健康状态评估
	if hp < 30:  # 血量低于30%，优先撤退
		strategy = "RETREAT"
	elif hp < 50:  # 血量低于50%，根据战力决定
		# 如果附近有敌方英雄且我方战力不足，选择撤退
		var nearby_enemies = []
		for p in nearby_pawns:
			if p.type == "CHARACTER" and p.camp != camp and p.is_alive() and p.is_attackable():
				nearby_enemies.append(p)
				
		if nearby_enemies.size() > 0:
			var total_enemy_power = 0.0
			for enemy in nearby_enemies:
				total_enemy_power += enemy.calculate_power()
				
			if self_power < total_enemy_power:
				strategy = "RETREAT"
	
	# 2. 特殊角色策略
	if lane == "辅助":
		# 辅助优先跟随己方ADC（下路）
		strategy = "SUPPORT"
	
	# 3. 目标筛选
	match strategy:
		"ATTACK":
			# 进攻策略：选择敌方目标
			# 优先级：血量低的敌方英雄 > 附近的敌方建筑 > 其他敌方单位
			
			# 3.1 寻找血量低的敌方英雄
			var low_hp_enemies = []
			for p in all_pawns:
				if p.camp != camp and p.type == "CHARACTER" and p.is_alive() and p.is_attackable() and p.hp < 40:
					low_hp_enemies.append(p)
			
			if low_hp_enemies.size() > 0:
				# 为低血量敌人分配权重
				var target_weights = {}
				for enemy in low_hp_enemies:
					# 基础权重：血量越低权重越高
					var base_weight = (100 - enemy.hp) / 100.0
					
					# 距离因子：距离越近权重越高
					var distance = position.distance_to(enemy.position)
					var distance_factor = 1000.0 / max(distance, 100.0)
					
					# 战力因子：如果我方战力高于敌方，增加权重
					var power_factor = self_power / max(enemy.calculate_power(), 1.0)
					power_factor = clamp(power_factor, 0.5, 2.0)
					
					# 计算总权重
					var total_weight = base_weight * 0.4 + distance_factor * 0.4 + power_factor * 0.2
					target_weights[enemy] = total_weight
				
				# 根据权重选择目标
				var best_target = null
				var highest_weight = 0
				
				for target in target_weights:
					if target_weights[target] > highest_weight:
						highest_weight = target_weights[target]
						best_target = target
				
				if best_target != null:
					# print("%s选择攻击低血量敌人：%s" % [pawn_name, best_target.pawn_name])
					return best_target
			
			# 3.2 如果在兵线上，考虑攻击敌方建筑
			if is_on_lane:
				var enemy_buildings = []
				for p in all_pawns:
					if p.camp != camp and p.type == "BUILDING" and p.is_alive() and p.is_attackable():
						enemy_buildings.append(p)
				
				if enemy_buildings.size() > 0:
					# 按照建筑物类型和距离排序
					var building_priorities = {
						"一塔": 3,
						"二塔": 2,
						"高地塔": 1,
						"水晶": 0
					}
					
					var best_building = null
					var best_priority = -1
					var best_distance = 999999
					
					for building in enemy_buildings:
						var priority = -1
						for key in building_priorities:
							if building.pawn_name.contains(key):
								if building.is_attackable() and building.is_alive():
									priority = building_priorities[key]
									break
								else:
									priority = 10000
									break
						
						if priority > best_priority:
							best_priority = priority
							best_building = building
							best_distance = position.distance_to(building.position)
						elif priority == best_priority:
							var distance = position.distance_to(building.position)
							if distance < best_distance:
								best_building = building
								best_distance = distance
					
					if best_building != null:
						print("%s选择攻击敌方建筑：%s" % [pawn_name, best_building.pawn_name])
						return best_building
			
			# 3.3 选择附近的敌方单位
			var nearby_enemies = []
			for p in nearby_pawns:
				if p.camp != camp and p.is_alive() and p.is_attackable():
					nearby_enemies.append(p)
			
			if nearby_enemies.size() > 0:
				# 按照类型和战力排序
				var type_priorities = {
					"CHARACTER": 3,
					"MINION": 2,
					"MONSTER": 1,
					"BUILDING": 0
				}
				
				var best_enemy = null
				var best_priority = -1
				var best_power_ratio = 0
				
				for enemy in nearby_enemies:
					var priority = type_priorities.get(enemy.type, 0)
					
					if priority > best_priority:
						best_priority = priority
						best_enemy = enemy
						if enemy.type == "CHARACTER":
							best_power_ratio = self_power / max(enemy.calculate_power(), 1.0)
						else:
							best_power_ratio = 999
					elif priority == best_priority and enemy.type == "CHARACTER":
						var power_ratio = self_power / max(enemy.calculate_power(), 1.0)
						if power_ratio > best_power_ratio:
							best_enemy = enemy
							best_power_ratio = power_ratio
				
				if best_enemy != null:
					print("%s选择攻击附近敌人：%s" % [pawn_name, best_enemy.pawn_name])
					return best_enemy
			
			# 3.4 如果没有找到合适的目标，选择敌方水晶
			var enemy_crystal_name = "红方水晶" if camp == "BLUE" else "蓝方水晶"
			var enemy_crystal = simulator.name_poi_dict.get(enemy_crystal_name)
			
			if enemy_crystal != null and enemy_crystal.is_alive() and enemy_crystal.is_attackable():
				print("%s选择攻击敌方水晶" % pawn_name)
				return enemy_crystal
				
		"RETREAT":
			# 撤退策略：选择己方目标
			# 优先级：己方泉水 > 己方塔 > 己方英雄
			
			# 4.1 如果血量很低，直接撤回泉水
			if hp < 20:
				var fountain_name = "蓝方泉水" if camp == "BLUE" else "红方泉水"
				var fountain = simulator.name_poi_dict.get(fountain_name)
				
				if fountain != null:
					print("%s血量过低，撤回泉水" % pawn_name)
					return fountain
			
			# 4.2 寻找附近的己方防御塔
			var friendly_towers = []
			for p in all_pawns:
				if p.camp == camp and p.type == "BUILDING" and p.is_alive() and p.pawn_name.contains("塔"):
					friendly_towers.append(p)
			
			if friendly_towers.size() > 0:
				# 选择最近的防御塔
				var closest_tower = friendly_towers[0]
				var min_distance = position.distance_to(closest_tower.position)
				
				for tower in friendly_towers:
					var distance = position.distance_to(tower.position)
					if distance < min_distance:
						min_distance = distance
						closest_tower = tower
				
				print("%s撤退到己方防御塔：%s" % [pawn_name, closest_tower.pawn_name])
				return closest_tower
			
			# 4.3 寻找附近的己方英雄
			var friendly_heroes = []
			for p in all_pawns:
				if p.camp == camp and p.type == "CHARACTER" and p.is_alive() and p != self:
					# 优先选择血量高的英雄
					if p.hp > 50:
						friendly_heroes.append(p)
			
			if friendly_heroes.size() > 0:
				# 选择最近的友方英雄
				var closest_hero = friendly_heroes[0]
				var min_distance = position.distance_to(closest_hero.position)
				
				for hero in friendly_heroes:
					var distance = position.distance_to(hero.position)
					if distance < min_distance:
						min_distance = distance
						closest_hero = hero
				
				print("%s撤退到己方英雄：%s" % [pawn_name, closest_hero.pawn_name])
				return closest_hero
				
		"SUPPORT":
			# 支援策略：跟随己方ADC或需要帮助的队友
			
			# 5.1 寻找己方ADC（下路）
			var adc_heroes = []
			for p in all_pawns:
				if p.camp == camp and p.type == "CHARACTER" and p.is_alive() and p.lane == "下路":
					adc_heroes.append(p)
			
			if adc_heroes.size() > 0:
				# 选择最近的ADC
				var closest_adc = adc_heroes[0]
				var min_distance = position.distance_to(closest_adc.position)
				
				for adc in adc_heroes:
					var distance = position.distance_to(adc.position)
					if distance < min_distance:
						min_distance = distance
						closest_adc = adc
				
				print("%s支援己方ADC：%s" % [pawn_name, closest_adc.pawn_name])
				return closest_adc
			
			# 5.2 寻找血量低的队友
			var low_hp_allies = []
			for p in all_pawns:
				if p.camp == camp and p.type == "CHARACTER" and p.is_alive() and p != self and p.hp < 50:
					low_hp_allies.append(p)
			
			if low_hp_allies.size() > 0:
				# 选择血量最低的队友
				var lowest_hp_ally = low_hp_allies[0]
				
				for ally in low_hp_allies:
					if ally.hp < lowest_hp_ally.hp:
						lowest_hp_ally = ally
				
				print("%s支援低血量队友：%s" % [pawn_name, lowest_hp_ally.pawn_name])
				return lowest_hp_ally
	
	# 如果以上策略都没有找到目标，使用原有的select_target_by_distance方法
	var fallback_targets = []
	
	if hp > 50:  # 血量健康，选择敌方目标
		for p in all_pawns:
			if p.camp != camp and p.is_alive() and p.is_attackable():
				fallback_targets.append(p)
	else:  # 血量不健康，选择友方目标
		for p in all_pawns:
			if p.camp == camp and p.is_alive() and p != self:
				fallback_targets.append(p)
	
	print("%s使用默认目标选择方法" % pawn_name)
	return select_target_by_distance(fallback_targets)


func refresh_command():
	# if under_command and move_target != null and move_target.is_alive():
	# 	# 获取目标位置（相对于当前pawn的局部坐标）
	# 	var target_pos = to_local(move_target.global_position)
		
	# 	# 根据阵营选择颜色
	# 	var line_color
	# 	match camp:
	# 		"BLUE":
	# 			line_color = Color.BLUE
	# 		"RED":
	# 			line_color = Color.RED
	# 		"NEUTRAL":
	# 			line_color = Color.GRAY
		
	# 	# 绘制虚线
	# 	custom_draw_dashed_line(Vector2.ZERO, target_pos, line_color, 2.0, 5.0)

	if under_command:
		if GameManager.game_index >= command_game_index + GameManager.main_view.command_durration:
			under_command = false
		elif not is_alive():
			under_command = false
		elif move_target == null or not move_target.is_alive():
			under_command = false
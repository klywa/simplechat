class_name Pawn
extends Node2D

@export var pawn_name: String
@export var moveable: bool = true
@export var max_speed: float = 100
@export_enum("BLUE", "RED", "NEUTRAL") var camp: String = "NEUTRAL"
@export_enum("CHARACTER", "BUILDING", "RESOURCE", "MONSTER") var type: String = "CHARACTER"
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

var map_rect 
var tile_size
var map_size

var kill_number : int = 0
var death_number : int = 0
var assist_number : int = 0

var move_target : Pawn = null
@onready var move_target_label := $MoveTarget

@onready var camp_color_flag := $CampColor
@onready var shield_flag := $ShieldFlag
@onready var name_label := $Name
@onready var sprite := $Sprite
@onready var popup_panel := $PopupPanel

@onready var body_shape := $BodyArea
@onready var detect_shape := $DetectArea

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

@onready var revive_button := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ReviveButton

@onready var popup_panel_title := $PopupPanel/PanelContainer/MarginContainer/VBoxContainer/Title

var npc : NPC
var hp : int = 100
var level : int = 1
var money : int = 0
var revive_count_down : int = 0
var visible_to_blue : bool = true
var nearby_pawns : Array[Pawn] = []

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
		"BUILDING":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.5
			health_bar.modulate.a = 0.0
		"RESOURCE":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.2
			health_bar.modulate.a = 0.0
		"MONSTER":
			moveable = false
			name_label.visible = false
			hero_icon.visible = false
			sprite.visible = false
			camp_color_flag.modulate.a = 0.2
			health_bar.modulate.a = 0.0
	name_label.text = pawn_name

func _show():
	name_label.text = pawn_name
	set_hero_avatar()

func load_npc(npc: NPC):
	self.npc = npc
	pawn_name = npc.hero_name
	lane = npc.hero_lane
	_show()

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

func _process(_delta):

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

	if move_target == null or not move_target.is_alive():
		reselect_move_target()

	# 根据可见性状态更新显示
	if camp == "RED":
		if visible_to_blue:
			sprite.modulate.a = 1.0
			camp_color_flag.modulate.a = 1.0
		else:
			sprite.modulate.a = 0.5
			camp_color_flag.modulate.a = 0.5

	health_bar.value = hp
	move_target_label.text = move_target.get_unique_name() if move_target != null else ""

	if is_attackable():
		shield_flag.visible = false
	else:
		shield_flag.visible = true
		
	# 如果正在拖动且有悬停目标，或者有移动目标且显示目标线，则触发重绘
	if (dragging and hover_target != null) or (show_target_line and move_target != null):
		queue_redraw()

func random_move():
	if dragging:
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
	
	# 设置新位置
	position = Vector2(random_x, random_y)


func _on_button_pressed():
	popup_panel_title.text = pawn_name

	if not dragged or not moveable:
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
			print("%s检测到%s进入范围" % [pawn_name, other_pawn.pawn_name])
			
			# 如果自己是RED阵营，且进入的pawn是BLUE阵营
			if camp == "RED" and other_pawn.camp == "BLUE":
				if not visible_to_blue:
					visible_to_blue = true
					# 更新可见性
					sprite.modulate.a = 1.0
					camp_color_flag.modulate.a = 1.0
					print("%s被BLUE阵营发现，变为可见" % pawn_name)

# 当其他pawn离开检测区域时调用
func _on_detect_area_exited(area: Area2D) -> void:
	# 检查离开的区域是否是另一个pawn的body_shape
	if area.get_parent() is Pawn and area.name == "BodyArea":
		var other_pawn = area.get_parent() as Pawn
		if nearby_pawns.has(other_pawn):
			nearby_pawns.erase(other_pawn)
			print("%s检测到%s离开范围" % [pawn_name, other_pawn.pawn_name])
			
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
					sprite.modulate.a = 0.5
					camp_color_flag.modulate.a = 0.5
					print("%s附近没有BLUE阵营单位，变为不可见" % pawn_name)

func send_message(message: String):
	simulator.chat.add_message(GameManager.system, message)

func killed_by(pawn: Pawn, assist_pawns: Array = []):

	death_number += 1
	pawn.kill_number += 1
	pawn.money += randi() % 100
	for p in assist_pawns:
		p.assist_number += 1
		p.money += randi() % 50

	hp = 0
	var msg = ""
	var self_name = ""
	if npc != null:
		self_name = npc.npc_name + "-" + pawn_name
	else:
		self_name = pawn_name
	if camp == "BLUE":
		if type == "BUILDING":
			self_name = pawn_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			self_name = "<我方-" + self_name + ">"
	elif camp == "RED":
		if type == "BUILDING":
			self_name = pawn_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			self_name = "<敌方-" + self_name + ">"
	
	var killer_name = ""
	if pawn.npc != null:
		killer_name = pawn.npc.npc_name + "-" + pawn.pawn_name
	else:
		killer_name = pawn.pawn_name

	if pawn.camp == "BLUE":
		if pawn.type == "BUILDING":
			killer_name = killer_name.replace("红方", "敌方").replace("蓝方", "我方")
		else:
			killer_name = "<我方-" + killer_name + ">"
	elif pawn.camp == "RED":
		if pawn.type == "BUILDING":
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
				tmp_name = p.npc.npc_name + "-" + p.pawn_name + "-" + p.lane
			else:
				tmp_name = p.pawn_name + "-" + p.lane
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
					msg = "%s击杀了%s。%s" % [killer_name, self_name, assist_msg]
				"BLUE":
					msg = "%s被%s击杀。%s" % [self_name, killer_name, assist_msg]
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
		reselect_move_target()

func heal(heal: int):
	var origin_hp = hp
	hp += heal
	if hp > 100:
		hp = 100
	
	if origin_hp < 100 and hp >= 100:
		reselect_move_target()

func reselect_move_target():

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
	
	var debug_str = pawn_name + "距离："
	for target in targets:
		var distance = position.distance_to(target.position)
		# 距离越近，权重越大，使用更强的距离惩罚
		var weight = 1.0 / pow(max(distance/1000, 0.1), 2) # 使用三次方权重，更强调近距离目标
		weights.append(weight)
		total_weight += weight
		debug_str += "目标:%s 距离:%.2f 权重:%.4f | " % [target.pawn_name, distance, weight]
	print(debug_str + "总权重:%.4f" % total_weight)
	
	# 如果总权重为0（极端情况），直接选择最近的目标
	if total_weight <= 0.0001:
		var closest_target = targets[0]
		var min_distance = position.distance_to(closest_target.position)
		
		for target in targets:
			var distance = position.distance_to(target.position)
			if distance < min_distance:
				min_distance = distance
				closest_target = target
		
		print("使用最近目标：", closest_target.pawn_name)
		return closest_target
	
	# 根据权重随机选择目标
	var random_value = randf() * total_weight
	var current_sum = 0.0
	
	for i in range(targets.size()):
		current_sum += weights[i]
		if random_value <= current_sum:
			print("选择了目标：", targets[i].pawn_name)
			return targets[i]
	
	# 保险起见，如果没有选中任何目标，返回第一个
	print("未选中任何目标，返回第一个")
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

	popup_panel.visible = false

func _on_hp_editor_changed(value: String):
	hp = int(value)
	if hp <= 0:
		die()

func _on_level_editor_changed(value: String):
	level = int(value)

func _on_revive_button_pressed():
	revive()
	popup_panel.visible = false

func _on_target_dropdown_item_selected(index: int):
	var target_name = move_target_dropdown.get_item_text(index)
	var target_pawn = simulator.name_pawn_dict.get(target_name, null)
	if target_pawn != null:
		move_target = target_pawn

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
			return closest.pawn_name + "野区"
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
	elif hp < 40:
		return "血量中等"
	else:
		return "血量健康"

func get_kda():
	var kda = (kill_number + assist_number + 0.01) / (death_number + 0.01)
	if kda < 0.8:
		return "战绩很差"
	elif kda < 1.2:
		return "战绩一般"
	elif kda < 1.5:
		return "战绩不错"
	else:
		return "战绩超神"

func get_on_lane():
	# 获取附近的建筑物
	var nearby_buildings = []
	for p in nearby_pawns:
		if p.type == "BUILDING" and p.is_attackable():
			nearby_buildings.append(p)
	
	# 如果附近有可攻击的建筑物，50%概率返回"正在和小兵交战"
	if nearby_buildings.size() > 0 and randf() < 0.5:
		return "附近有兵线"
	
	# 检查附近是否有中立单位（野怪）
	for p in nearby_pawns:
		if p.camp == "NEUTRAL":
			return "附近有野怪"

	# 默认返回空字符串
	return ""

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

func get_self_status():
	var status = ""

	if camp == "BLUE":
		var name_string = "“" + npc.npc_name + "”"
		status += name_string + "使用的英雄是" + pawn_name + "（" + lane + "）。"
		status += name_string + "" + get_health() + "。"
		status += name_string + get_kda() + "。"
		if get_on_lane() != "":
			status += name_string + get_on_lane() + "。"
		status += name_string + "在" + get_region() + "附近。"
	
	return status


func get_status():
	var status = ""

	if camp == "BLUE":
		var name_string = "<我方-" + npc.npc_name + "-" + pawn_name + ">"
		status += name_string + "是我方" + lane + "，"
		status += get_health() + "，"
		status += get_kda() + "，"
		status += "在" + get_region() + "附近"
		if get_on_lane() != "":
			status += get_on_lane() + "。"
		else:
			status += "。"

	elif camp == "RED":
		var name_string = "<敌方-" + pawn_name + ">"
		status += name_string + "是" + lane + "，"
		status += get_health() + "，"
		status += get_kda() + "，"
		status += "在" + get_region() + "附近"
		if get_on_lane() != "":
			status += get_on_lane() + "。"
		else:
			status += "。"

	return status
		

func get_player_status():
	var player_pawn = GameManager.player.pawn
	var status = player_pawn.get_status()

	# if player_pawn in nearby_pawns:
	# 	status += "“玩家”在" + "”" + npc.npc_name + "”" + "附近。"

	return status


func get_in_sight_status():
	var status = ""
	if camp == "BLUE":
		var name_string = "<" + npc.npc_name + "-" + pawn_name + "-我方>"
		status += name_string + "是我方" + lane + "，在" + get_region() + "附近，" + get_health() + "。"
	elif camp == "RED":
		var name_string = "<" + pawn_name + "-敌方>"
		status += name_string + "是敌方" + lane + "，在" + get_region() + "附近，" + get_health() + "。"

	return status

func get_builing_status():
	var destroyed_status = "被摧毁的防御塔："
	var remaining_status = "未被摧毁的防御塔："

	for p in simulator.name_poi_dict.values():
		print(p.pawn_name)
		if p.type == "BUILDING" and p.pawn_name.contains("塔"):
			if p.is_alive():
				remaining_status += p.pawn_name.replace("红方", "敌方").replace("蓝方", "我方") + "，"
			else:
				destroyed_status += p.pawn_name.replace("红方", "敌方").replace("蓝方", "我方") + "，"
	destroyed_status = destroyed_status.rstrip("，") + "。"
	remaining_status = remaining_status.rstrip("，") + "。"
	return destroyed_status + "\n" + remaining_status

func get_scenario_stirng():
	var scenario = "[玩家情况]\n"
	scenario += get_player_status() + "\n"
	
	scenario += "\n[附近英雄]\n"
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp == camp:
			scenario += p.get_in_sight_status() + "\n"
	for p in nearby_pawns:
		if p.type == "CHARACTER" and p.camp != camp:
			scenario += p.get_in_sight_status() + "\n"

	scenario += "\n[不在附近但在视野可见的英雄]\n"
	for p in simulator.name_pawn_dict.values():
		if p.type == "CHARACTER" and p not in nearby_pawns and p.visible_to_blue and p != self:
			scenario += p.get_status() + "\n"

	scenario += "\n[附近防御塔]\n"
	scenario += get_builing_status() + "\n"
	
	
	return scenario

# 鼠标进入按钮时显示虚线
func _on_button_mouse_entered():
	# 只有在非拖动状态下才显示虚线
	if not dragging:
		show_target_line = true
		queue_redraw()  # 触发重绘

# 鼠标离开按钮时隐藏虚线
func _on_button_mouse_exited():
	# 无论是否在拖动，都隐藏虚线
	show_target_line = false
	queue_redraw()  # 触发重绘

# 重写_draw方法来绘制虚线
func _draw():
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

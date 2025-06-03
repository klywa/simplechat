class_name KoHSimulator
extends Node2D


@onready var blue_hero_1 = $Pawns/BlueHero1
@onready var blue_hero_2 = $Pawns/BlueHero2
@onready var blue_hero_3 = $Pawns/BlueHero3
@onready var blue_hero_4 = $Pawns/BlueHero4
@onready var blue_hero_5 = $Pawns/BlueHero5
@onready var red_hero_1 = $Pawns/RedHero1
@onready var red_hero_2 = $Pawns/RedHero2
@onready var red_hero_3 = $Pawns/RedHero3
@onready var red_hero_4 = $Pawns/RedHero4
@onready var red_hero_5 = $Pawns/RedHero5

@onready var blue_crystal = $POIs/BlueCrystal
@onready var red_crystal = $POIs/RedCrystal

@onready var pois := $KoHMap/POIs
@onready var pawns := $KoHMap/Pawns
@onready var map := $KoHMap

var map_rect 
var tile_size
var map_size

var blue_pawns: Array[Pawn] = []
var red_pawns: Array[Pawn] = []
var name_poi_dict : Dictionary = {}

var name_pawn_dict : Dictionary = {}
var camp_name_pawn_dict : Dictionary = {}

var init_random_range : int = 30
var chat: Chat

var blue_team_total_money : int = 0
var red_team_total_money : int = 0
var blue_team_total_kill : int = 0
var red_team_total_kill : int = 0

var replay_info : Array

var match_time : int = 0

var frame_synced : bool = false

signal simulate_finished

const PAWN_SCENE = preload("res://scenes/simulator/pawn.tscn")

func _ready() -> void:
	blue_pawns = [blue_hero_1, blue_hero_2, blue_hero_3, blue_hero_4, blue_hero_5]
	red_pawns = [red_hero_1, red_hero_2, red_hero_3, red_hero_4, red_hero_5]

	for p in pois.get_children():
		name_poi_dict[p.pawn_name] = p

	map_rect = map.ground_layer.get_used_rect()
	tile_size = map.ground_layer.tile_set.tile_size
	map_size = map_rect.size * tile_size

func init(chat_in: Chat):
	chat = chat_in
	replay_info.clear()

	name_pawn_dict.clear()
	for p_name in name_poi_dict:
		name_pawn_dict[p_name] = name_poi_dict[p_name]
		camp_name_pawn_dict[p_name.replace("蓝方", "我方").replace("红方", "敌方")] = name_poi_dict[p_name]

	# 清除所有pawn的子节点
	for child in pawns.get_children():
		pawns.remove_child(child)
		child.queue_free()
		
	for pawn in name_pawn_dict.values():
		pawn.revive()

	blue_team_total_money = 0
	red_team_total_money = 0
	blue_team_total_kill = 0
	red_team_total_kill = 0

	for npc_name in chat.members:
		var npc = chat.members[npc_name]
		if npc.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:

			var new_pawn = PAWN_SCENE.instantiate()
			new_pawn.npc = npc
			print("npc.hero_name: ", npc.hero_name)
			new_pawn.pawn_name = npc.hero_name
			new_pawn.camp = "BLUE"
			new_pawn.lane = npc.hero_lane
			new_pawn.type = "CHARACTER"

			pawns.add_child(new_pawn)
			new_pawn._show()
			npc.pawn = new_pawn
			npc.origin_pawn = new_pawn
			npc.character_button.set_hero_avatar()
			new_pawn.add_to_group("hero")

			name_pawn_dict[new_pawn.get_unique_name()] = new_pawn
			if new_pawn.camp == "BLUE":
				camp_name_pawn_dict["我方" + new_pawn.pawn_name] = new_pawn
			else:
				camp_name_pawn_dict["敌方" + new_pawn.pawn_name] = new_pawn
			
			print("movable: ", new_pawn.moveable)

			match new_pawn.lane:
				"上路":
					new_pawn.position = name_poi_dict["蓝方上路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					new_pawn.is_on_lane = true
				"打野":
					if randf() < 0.5:
						new_pawn.position = name_poi_dict["蓝方蓝Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					else:
						new_pawn.position = name_poi_dict["蓝方红Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"中路":
					new_pawn.position = name_poi_dict["蓝方中路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					new_pawn.is_on_lane = true
				"下路":
					new_pawn.position = name_poi_dict["蓝方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					new_pawn.is_on_lane = true
				"辅助":
					new_pawn.position = name_poi_dict["蓝方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					new_pawn.is_on_lane = true
				_:
					new_pawn.position = name_poi_dict["蓝方水晶"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
			
			new_pawn.position.x = clamp(new_pawn.position.x, 0, map_size.x * map.scale.x)
			new_pawn.position.y = clamp(new_pawn.position.y, 0, map_size.y * map.scale.y)


	for npc_name in chat.opponent_members:
		var npc = chat.opponent_members[npc_name]

		if npc.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
			var new_pawn = PAWN_SCENE.instantiate()
			new_pawn.npc = npc
			var lane_heroes = GameManager.lane_hero_dict[npc.hero_lane]
			new_pawn.pawn_name = lane_heroes[randi() % lane_heroes.size()] if lane_heroes.size() > 0 else "未知英雄"
			new_pawn.camp = "RED"
			new_pawn.lane = npc.hero_lane
			new_pawn.type = "CHARACTER"
			pawns.add_child(new_pawn)
			
			new_pawn._show()
			npc.pawn = new_pawn
			npc.origin_pawn = new_pawn
			new_pawn.add_to_group("hero")

			name_pawn_dict[new_pawn.get_unique_name()] = new_pawn
			if new_pawn.camp == "BLUE":
				camp_name_pawn_dict["我方" + new_pawn.pawn_name] = new_pawn
			else:
				camp_name_pawn_dict["敌方" + new_pawn.pawn_name] = new_pawn

			match new_pawn.lane:
				"上路":
					new_pawn.position = name_poi_dict["红方上路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"打野":
					if randf() < 0.5:
						new_pawn.position = name_poi_dict["红方蓝Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
					else:
						new_pawn.position = name_poi_dict["红方红Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"中路":
					new_pawn.position = name_poi_dict["红方中路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"下路":
					new_pawn.position = name_poi_dict["红方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"辅助":
					new_pawn.position = name_poi_dict["红方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				_:
					new_pawn.position = name_poi_dict["红方水晶"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
			
			new_pawn.position.x = clamp(new_pawn.position.x, 0, map_size.x * map.scale.x)
			new_pawn.position.y = clamp(new_pawn.position.y, 0, map_size.y * map.scale.y)


	name_pawn_dict["暴君"].die()
	name_pawn_dict["主宰"].die()

	for pawn in name_pawn_dict.values():
		if pawn.type == "CHARACTER":
			pawn.set_init_move_target()
			
	match_time = 0

	print(get_map_info_string())
	print(camp_name_pawn_dict)

	await get_tree().process_frame

	update_replay_info()
	chat.add_message(GameManager.system, "比赛开始。")

func simulate():

	match_time += 1

	var pawn_list = name_pawn_dict.values()
	pawn_list.shuffle()

	for pawn in pawn_list:

		if pawn.is_alive():
			if pawn.type == "CHARACTER":

				if pawn.is_on_lane:
					pawn.money += randi() % 20 + 20
				elif pawn.has_monster_nearby():
					pawn.money += randi() % 20 + 20
				else:
					pawn.money += randi() % 10

				if randi() % 100 <= 10:
					pawn.level += 1
					pawn.level = min(pawn.level, 20)
				
				pawn.random_move()
				pawn.set_on_lane()
		
			# attack
			# choose random nearby target with opposite camp
			var target = null
			var potential_targets = []
			for other in pawn.nearby_pawns:
				if other.is_alive() and other.camp != pawn.camp and other.is_attackable():
					potential_targets.append(other)
			
			if potential_targets.size() > 0:
				target = potential_targets[randi() % potential_targets.size()]

			if target != null and pawn.is_alive():
				var damage : int = 0

				if true:
					damage = calculate_damage(pawn, target)
				
					if damage >= target.hp:
						var killer = pawn
						# 从附近的不同阵营角色中随机选择一些作为助攻
						var assist_pawns = []
						var potential_assists = []
						
						# 收集所有附近的、与被击杀者阵营不同的角色型单位
						for nearby in target.nearby_pawns:
							if nearby != killer and nearby.is_alive() and nearby.camp == killer.camp and nearby.type == "CHARACTER":
								potential_assists.append(nearby)
						
						# 随机决定有多少个助攻（0-4个）
						var assist_count = min(randi() % 5, potential_assists.size())
						
						# 随机选择助攻
						potential_assists.shuffle()
						for i in range(assist_count):
							if i < potential_assists.size():
								assist_pawns.append(potential_assists[i])
						
						# 处理击杀
						if target.type in ["CHARACTER", "BUILDING"]:
							target.killed_by(killer, assist_pawns)
						else:
							target.killed_by(killer)
					elif damage > 0:
						target.take_damage(damage)

			# heal
			if pawn.type == "CHARACTER":
				var has_other_camp_nearby = false
				for nearby in pawn.nearby_pawns:
					if nearby.is_alive() and nearby.camp != pawn.camp:
						has_other_camp_nearby = true
						break
				
				if not has_other_camp_nearby:
					pawn.heal(randi() % 20 + 10)

				for nearby in pawn.nearby_pawns:
					if nearby.camp == pawn.camp and nearby.type == "CHARACTER" and nearby.lane == "辅助":
						nearby.heal(randi() % 20 + 20)
				
		else:
			if pawn.type in ["CHARACTER", "MONSTER"]:
				pawn.revive_count_down -= 1
				if pawn.revive_count_down <= 0:
					pawn.revive()

	blue_team_total_money = 0
	red_team_total_money = 0
	for pawn in name_pawn_dict.values():
		if pawn.type == "CHARACTER":
			if pawn.camp == "BLUE":
				blue_team_total_money += pawn.money
			elif pawn.camp == "RED":
				red_team_total_money += pawn.money
	
	blue_team_total_kill = 0
	red_team_total_kill = 0
	for pawn in name_pawn_dict.values():
		if pawn.type in ["CHARACTER", "BUILDING"]:
			if pawn.camp == "BLUE":
				blue_team_total_kill += pawn.kill_number
			elif pawn.camp == "RED":
				red_team_total_kill += pawn.kill_number
	
	simulate_finished.emit()

	update_replay_info()
	# GameManager.chat_view.autosave_chat()

func back_to_last_frame():
	if replay_info.size() <= 1:
		return
	var last_game_index = replay_info[-1].get("game_index", 0)
	var last_last_game_index = replay_info[-2].get("game_index", 0)

	replay_info.pop_back()

	print("back to last frame: ", last_last_game_index)
	set_frame_info(replay_info[-1], 0.3)

	for child in GameManager.chat_view.message_list.get_children():
		if child is Message or child is SystemMessage:
			if child.game_index > last_last_game_index:
				chat.messages.erase(child)
				child.queue_free()
	
	# for message in chat.messages:
	# 	if message.game_index > last_last_game_index:
	# 		chat.messages.erase(message)

func calculate_damage(attacker: Pawn, defender: Pawn):
	if attacker.camp == defender.camp:
		return 0

	match attacker.type:
		"CHARACTER":
			match defender.type:
				"CHARACTER":
					# 使用calculate_power函数计算伤害
					var attacker_power = attacker.calculate_power()
					var defender_power = defender.calculate_power()
					
					# 计算基础伤害
					var base_damage = 10.0 + (attacker_power / 5.0)
					
					# 计算伤害倍率，基于双方战力比
					var power_ratio = attacker_power / max(defender_power, 1.0)
					var damage_multiplier = clamp(power_ratio, 0.5, 2.0)
					
					# 计算最终伤害，添加随机因素
					var final_damage = int(round(base_damage * damage_multiplier))
					final_damage += randi() % int(max(5, final_damage * 0.3))
					
					# 辅助角色伤害降低
					if attacker.lane == "辅助":
						final_damage = int(final_damage * 0.7)
						
					return final_damage
				"BUILDING":
					if defender.has_friend_hero_nearby():
						if attacker.is_on_lane:
							return randi() % int(ceil(min(10.0, 0.01 + round(float(match_time) / 18.0))))
						else:
							return randi() % int(ceil(min(5.0, 0.01 + round(float(match_time) / 36.0))))
					elif attacker.is_on_lane:
						return randi() % int(ceil(min(40.0, 0.01 + round(float(match_time) / 4.5))))
					else:
						return randi() % int(ceil(min(5.0, 0.01 + round(float(match_time) / 36.0))))
				"MINION":
					if attacker.lane == "辅助":
						return randi() % int(round(20.0 + 10.0 * ((float(attacker.money) + 0.01) / (6000.0 + 0.01) - 1.0)))
					else:
						return randi() % int(round(50.0 + 20.0 * ((float(attacker.money) + 0.01) / (6000.0 + 0.01) - 1.0)))
				"MONSTER":
					if attacker.lane == "辅助":
						return randi() % int(round(20.0 + 10.0 * ((float(attacker.money) + 0.01) / (6000.0 + 0.01) - 1.0)))
					else:
						return randi() % int(round(50.0 + 20.0 * ((float(attacker.money) + 0.01) / (6000.0 + 0.01) - 1.0)))
		"BUILDING":
			match defender.type:
				"CHARACTER":
					if defender.has_friend_hero_nearby():
						if defender.move_target.type == "CHARACTER" and defender.move_target.camp == defender.camp:
							return randi() % 50
						elif defender.is_on_lane:
							return randi() % 5
						else:
							return randi() % 20
					else:
						return 0
				"MINION":
					return randi() % 20
				_:
					return 0
		"MINION":
			return randi() % 10
		"MONSTER":
			return randi() % 10


func get_map_info_string():
	var info = "王者荣耀地图范围为120*120，"
	
	# 获取水晶坐标
	var blue_crystal_pos = name_poi_dict["蓝方水晶"].get_corrdinate()
	var red_crystal_pos = name_poi_dict["红方水晶"].get_corrdinate()
	info += "我方水晶位于" + blue_crystal_pos + "，敌方水晶位于" + red_crystal_pos + "。"
	
	# 获取防御塔坐标
	info += "我方防御塔坐标为："
	for tower_name in ["蓝方上路一塔", "蓝方上路二塔", "蓝方上路高地塔", 
					  "蓝方中路一塔", "蓝方中路二塔", "蓝方中路高地塔",
					  "蓝方下路一塔", "蓝方下路二塔", "蓝方下路高地塔"]:
		if name_poi_dict[tower_name].is_alive():
			info += tower_name + name_poi_dict[tower_name].get_corrdinate() + "、"
	info = info.rstrip("、") + "。"
	
	info += "敌方防御塔坐标为："
	for tower_name in ["红方上路一塔", "红方上路二塔", "红方上路高地塔",
					  "红方中路一塔", "红方中路二塔", "红方中路高地塔", 
					  "红方下路一塔", "红方下路二塔", "红方下路高地塔"]:
		if name_poi_dict[tower_name].is_alive():
			info += tower_name + name_poi_dict[tower_name].get_corrdinate() + "、"
	info = info.rstrip("、") + "。"
	
	return info

func update_replay_info():
	replay_info.append(get_frame_info(GameManager.get_game_index()))

func get_frame_info(game_index: int) -> Dictionary:
	var frame_info = {}

	frame_info["game_index"] = game_index
	frame_info["match_time"] = match_time
	frame_info["blue_team_total_money"] = blue_team_total_money
	frame_info["red_team_total_money"] = red_team_total_money
	frame_info["blue_team_total_kill"] = blue_team_total_kill
	frame_info["red_team_total_kill"] = red_team_total_kill
	frame_info["pawns"] = {}
	
	for pawn in name_pawn_dict.values():
		frame_info["pawns"][pawn.get_unique_name()] = pawn.get_pawn_info()

	return frame_info

func set_frame_info(frame_info: Dictionary, tween_time: float = 0.0):
	match_time = frame_info.get("match_time", 0)
	blue_team_total_money = frame_info.get("blue_team_total_money", 0)
	red_team_total_money = frame_info.get("red_team_total_money", 0)
	blue_team_total_kill = frame_info.get("blue_team_total_kill", 0)
	red_team_total_kill = frame_info.get("red_team_total_kill", 0)

	for pawn in name_pawn_dict.values():
		# print("setting ...")
		# print(pawn.get_unique_name(), " | ", frame_info["pawns"][pawn.get_unique_name()])
		pawn.set_pawn_info(frame_info["pawns"][pawn.get_unique_name()], tween_time)

func init_pawns(frame_info: Dictionary):
	var character_pawns = []
	var character_pawn_info = []

	for p_info in frame_info["pawns"].values():
		if p_info.get("type") == "CHARACTER":
			character_pawn_info.append(p_info)
	
	for pawn in name_pawn_dict.values():
		if pawn.type == "CHARACTER":
			character_pawns.append(pawn)
		else:
			pawn.init_pawn(frame_info["pawns"][pawn.get_unique_name()])
	
	for i in range(character_pawns.size()):
		print(i, " | ", character_pawn_info[i])
		character_pawns[i].init_pawn(character_pawn_info[i])

	set_frame_info(frame_info)

func reset_frame():
	frame_synced = false
	set_frame_info(GameManager.simulator.replay_info[-1], 0.0)
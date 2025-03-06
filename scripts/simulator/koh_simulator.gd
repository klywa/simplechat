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

var init_random_range : int = 100
var chat: Chat

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

	name_pawn_dict.clear()
	for p_name in name_poi_dict:
		name_pawn_dict[p_name] = name_poi_dict[p_name]

	# 清除所有pawn的子节点
	for child in pawns.get_children():
		pawns.remove_child(child)
		child.queue_free()
		
	for pawn in name_pawn_dict.values():
		pawn.revive()

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
			new_pawn.add_to_group("hero")

			name_pawn_dict[new_pawn.get_unique_name()] = new_pawn
			
			print("movable: ", new_pawn.moveable)

			match new_pawn.lane:
				"上路":
					new_pawn.position = name_poi_dict["蓝方上路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"打野":
					new_pawn.position = name_poi_dict["蓝方蓝Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"中路":
					new_pawn.position = name_poi_dict["蓝方中路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"下路":
					new_pawn.position = name_poi_dict["蓝方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				"辅助":
					new_pawn.position = name_poi_dict["蓝方下路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
				_:
					new_pawn.position = name_poi_dict["蓝方水晶"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
			
			new_pawn.position.x = clamp(new_pawn.position.x, 0, map_size.x * map.scale.x)
			new_pawn.position.y = clamp(new_pawn.position.y, 0, map_size.y * map.scale.y)


	for lane in ["上路", "打野", "中路", "下路", "辅助"]:
		var new_pawn = PAWN_SCENE.instantiate()
		new_pawn.npc = null
		var lane_heroes = GameManager.lane_hero_dict[lane]
		new_pawn.pawn_name = lane_heroes[randi() % lane_heroes.size()] if lane_heroes.size() > 0 else "未知英雄"
		new_pawn.camp = "RED"
		new_pawn.lane = lane
		new_pawn.type = "CHARACTER"
		pawns.add_child(new_pawn)
		new_pawn._show()
		new_pawn.add_to_group("hero")

		name_pawn_dict[new_pawn.get_unique_name()] = new_pawn

		match new_pawn.lane:
			"上路":
				new_pawn.position = name_poi_dict["红方上路一塔"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
			"打野":
				new_pawn.position = name_poi_dict["红方蓝Buff"].position + Vector2(randf_range(-init_random_range, init_random_range), randf_range(-init_random_range, init_random_range))
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


func simulate():
	for pawn in name_pawn_dict.values():

		if pawn.is_alive():
			if pawn.type == "CHARACTER":

				pawn.money += randi() % 10
				if randi() % 100 < 10:
					pawn.level += 1
				
				
				pawn.random_move()
		

			for other in pawn.nearby_pawns:
				if pawn.is_alive() and other.is_alive() and other.camp != pawn.camp and pawn.is_attackable():
					var damage : int = 0
					if other.type == "CHARACTER":
						damage = randi() % 100
					elif other.type == "BUILDING":
						damage = randi() % 50
					elif other.type == "MONSTER":
						damage = randi() % 20
				
					if damage > pawn.hp:
						var killer = other
						# 从附近的不同阵营角色中随机选择一些作为助攻
						var assist_pawns = []
						var potential_assists = []
						
						# 收集所有附近的、与被击杀者阵营不同的角色型单位
						for nearby in other.nearby_pawns:
							if nearby != killer and nearby.is_alive() and nearby.camp == killer.camp and nearby.type == "CHARACTER":
								potential_assists.append(nearby)
						
						# 随机决定有多少个助攻（0-3个）
						var assist_count = min(randi() % 4, potential_assists.size())
						
						# 随机选择助攻
						potential_assists.shuffle()
						for i in range(assist_count):
							if i < potential_assists.size():
								assist_pawns.append(potential_assists[i])
						
						# 处理击杀
						if pawn.type == "CHARACTER":
							pawn.killed_by(killer, assist_pawns)
						else:
							pawn.killed_by(killer)
					elif damage > 0:
						pawn.take_damage(damage)

			
			if pawn.type == "CHARACTER":
				var has_other_camp_nearby = false
				for nearby in pawn.nearby_pawns:
					if nearby.is_alive() and nearby.camp != pawn.camp:
						has_other_camp_nearby = true
						break
				
				if not has_other_camp_nearby:
					pawn.heal(randi() % 20 + 10)
		else:
			if pawn.type in ["CHARACTER", "MONSTER"]:
				pawn.revive_count_down -= 1
				if pawn.revive_count_down <= 0:
					pawn.revive()


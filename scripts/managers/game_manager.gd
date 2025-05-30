extends Node

const NPC_SCENE = preload("res://scenes/characters/npc.tscn") as PackedScene
const CHAT_SCENE = preload("res://scenes/ui/chat_view.tscn") as PackedScene
const LOCATION_SCENE = preload("res://scenes/components/location.tscn") as PackedScene

var mode : String = "single"	# pipeline, single
var safe_export : bool = false
var main_view
var chat_dict: Dictionary
var npc_dict: Dictionary
var location_dict: Dictionary
var player : NPC
var env : NPC
var system : NPC
var ai_instructions : String

var simulator : KoHSimulator
var game_index : int = 0

var hero_alias_dict: Dictionary
var lane_alias_dict
var hero_id_dict : Dictionary
var id_hero_dict : Dictionary
var hero_lane_dict : Dictionary
var lane_hero_dict : Dictionary

var tmp_save_file_path : String = "res://data/tmp_save.json"

var koh_chat_initialized : bool = false

var id_lane_dict := {
	 "1":"上路", 
	 "2":"打野", 
	 "3":"中路", 
	 "4":"辅助", 
	 "5":"下路", 
	 "0":"分路未知"
}

var lane_id_dict := {
	"上路": 1,
	"打野": 2,
	"中路": 3,
	"辅助": 4,
	"下路": 5,
	"分路未知": 0
	}

var knowledge : Dictionary

func init(main, config_path: String, knowledge_path: String, simulator_in: KoHSimulator = null) -> void:

	lane_hero_dict = {
		"上路": [],
		"打野": [],
		"中路": [],
		"辅助": [],
		"下路": []
	}

	main_view = main
	mode = main.mode

	simulator = simulator_in
	print("simulator: ", simulator)

	safe_export = main.safe_export
	var hero_conf_file = FileAccess.open("res://config/hero_conf.json", FileAccess.READ)
	if hero_conf_file:
		var json = JSON.new()
		var parse_result = json.parse(hero_conf_file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			hero_alias_dict = data
	
	var lane_conf_file = FileAccess.open("res://config/lane_conf.json", FileAccess.READ)
	if lane_conf_file:
		var json = JSON.new()
		var parse_result = json.parse(lane_conf_file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			lane_alias_dict = data

	var hero_id_file = FileAccess.open("res://config/hero_id.json", FileAccess.READ)
	if hero_id_file:
		var json = JSON.new()
		var parse_result = json.parse(hero_id_file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			for d in data:
				hero_id_dict[d[1]] = d[0]
				id_hero_dict[d[0]] = d[1]
				hero_lane_dict[d[1]] = d[2]
				lane_hero_dict[d[2]].append(d[1])

	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			if data is Dictionary:

				env = NPC_SCENE.instantiate()
				env.npc_name = "环境"
				env.npc_type = NPC.NPCType.ENV

				system = NPC_SCENE.instantiate()
				system.npc_name = "系统"
				system.npc_type = NPC.NPCType.SYSTEM

				# parse player
				player = NPC_SCENE.instantiate()
				player.load_from_dict(data.get("player", {}))
				player.npc_type = NPC.NPCType.PLAYER
				main_view.player_icon.init(player)

				# parse npc
				for n in data.get("npcs", []):
					var npc_name = n.get("npc_name", "")
					npc_dict[npc_name] = NPC_SCENE.instantiate()
					# add_child(npc_dict[npc_name])
					npc_dict[npc_name].load_from_dict(n)
					npc_dict[npc_name].npc_type = NPC.NPCType.NPC

					chat_dict[npc_name] = Chat.new()
					chat_dict[npc_name].host = npc_dict[npc_name]
					chat_dict[npc_name].chat_type = Chat.ChatType.PRIVATE
					chat_dict[npc_name].add_member(player)
					chat_dict[npc_name].add_member(npc_dict[npc_name])
					chat_dict[npc_name].init()

					# chat_dict[npc_name].add_message(npc_dict[npc_name], "你好，我是"+npc_name)

					main_view.chat_list.add_chat_item(npc_name, chat_dict[npc_name])


				# parse location
				for l in data.get("locations", []):
					var location_name = l.get("location_name", "")

					location_dict[location_name] = LOCATION_SCENE.instantiate()
					location_dict[location_name].load_from_dict(l)

					chat_dict[location_name] = Chat.new()
					chat_dict[location_name].host = location_dict[location_name]
					chat_dict[location_name].chat_type = Chat.ChatType.GROUP
					chat_dict[location_name].add_member(env)
					chat_dict[location_name].init()

					main_view.chat_list.add_chat_item(location_name, chat_dict[location_name])

					var location_members = l.get("members", [])
					for member in location_members:
						if member == player.npc_name:
							chat_dict[location_name].add_member(player)
						else:
							chat_dict[location_name].add_member(npc_dict[member])

				ai_instructions = data.get("instructions", {}).get("normal", "")

		file.close()

	# 读取知识库文件
	if knowledge_path.length() > 0:
		var knowledge_file = FileAccess.open(knowledge_path, FileAccess.READ)
		if knowledge_file:
			var json_string = knowledge_file.get_as_text()
			var knowledge_json = JSON.new()
			var knowledge_parse_result = knowledge_json.parse(json_string)
			if knowledge_parse_result == OK:
				knowledge = knowledge_json.get_data()
			else:
				print("解析知识库文件失败: ", knowledge_json.get_error_message(), " at line ", knowledge_json.get_error_line())
			knowledge_file.close()
		else:
			print("无法打开知识库文件: ", knowledge_path)

	
	koh_chat_initialized = false
	

func activate_chat(chat_in : Chat) -> void:

	main_view.chat_view.init(chat_in)
	main_view.chat_view.refresh()
	if chat_in.chat_type == Chat.ChatType.GROUP and chat_in.is_koh and not koh_chat_initialized:
		main_view.chat_view.on_new_button_pressed()
		koh_chat_initialized = true


func get_knowledge(chat : Chat, npc : NPC) -> String:
	var match_string = npc.pawn.pawn_name
	var knowledge_list = []
	if player in chat.members.values():
		match_string += player.hero_name
	
	# 从聊天记录中获取最后五条消息
	var recent_messages = []
	var messages_count = chat.messages.size()
	var start_index = max(0, messages_count - 3)
	
	for i in range(start_index, messages_count):
		if i < chat.messages.size():
			recent_messages.append(chat.messages[i].message)
	
	# 将最近的消息添加到匹配字符串中
	for msg in recent_messages:
		match_string += " " + msg

	print("match_string: ", match_string, chat.members)

	# 从知识库中查找匹配的知识
	for key in knowledge.keys():
		var use = false
		if key in match_string:
			use = true
		else:
			for alias in knowledge[key].get("别名", []):
				if alias in match_string:
					use = true
					break
		
		if use and knowledge[key].get("内容", "") not in knowledge_list:
			knowledge_list.append(key + "：" + knowledge[key].get("内容", ""))
	
	if knowledge_list.size() > 0:
		return "\n".join(knowledge_list)
	else:
		return ""

func new_chat() -> void:
	game_index = 0

func get_game_index() -> int:
	game_index += 1
	return game_index
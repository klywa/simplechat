class_name NPC
extends Node

enum NPCType {
	PLAYER,
	NPC,
	ENV,
	SYSTEM
}

var uid: int
var npc_name: String
var npc_setting: String
var npc_style : String
var npc_example : String
var npc_status : String
var npc_inventory : Dictionary
var npc_skill : Dictionary
var npc_story : String
var is_player: bool
var avatar_path: String
var chat_list: Array = [] 
var npc_type: NPCType
var hero_name: String
var hero_lane: String
var scenario: String
var alias : Array = []

var hero_id: int
var lane_id: int

var origin_hero_name: String
var origin_hero_lane: String
var origin_hero_id: int
var origin_lane_id: int

var current_chat : Chat = null

func _ready():
	pass

func load_from_dict(data: Dictionary):
	match data.get("type", "npc"):
		"npc":
			npc_type = NPCType.NPC
		"player":
			npc_type = NPCType.PLAYER
		"env":
			npc_type = NPCType.ENV
	
	if npc_type in [NPCType.NPC, NPCType.PLAYER]:
		uid = data.get("uid", UUIDGenerator.generate_uuid())
		npc_name = data.get("npc_name", "")
		is_player = data.get("is_player", false)
		npc_setting = data.get("npc_setting", "")
		npc_style = data.get("npc_style", "")
		npc_example = data.get("npc_example", "")
		npc_status = data.get("npc_status", "")
		npc_inventory = data.get("npc_inventory", {})
		npc_skill = data.get("npc_skill", {})
		avatar_path = data.get("avatar_path", "")
		hero_name = data.get("hero_name", "")
		hero_lane = data.get("hero_lane", "")

		hero_id = GameManager.hero_id_dict.get(hero_name, 0)
		lane_id = GameManager.lane_id_dict.get(hero_lane, 0)
		print(npc_name, hero_id, lane_id)

		avatar_path = data.get("avatar_path", "")

		origin_hero_name = hero_name
		origin_hero_lane = hero_lane
		origin_hero_id = hero_id
		origin_lane_id = lane_id

		update_alias()
	else:
		pass

func update_alias():
	alias = [hero_name, hero_lane]
	for a in GameManager.hero_alias_dict.get(hero_name, []):
		if a not in alias:
			alias.append(a)
	for a_list in GameManager.lane_alias_dict:
		if hero_lane in a_list:
			for a in a_list:
				if a not in alias:
					alias.append(a)
			break

func generate_response(chat : Chat, use_ai: bool=false, until_message: Variant=null) -> Dictionary:
	print("generate_response", str(npc_type))
	if npc_type == NPCType.ENV:
		print("in env")
		if not use_ai:
			print("not use ai")
			await GameManager.main_view.get_tree().create_timer(1).timeout
			return {"response": "系统消息", "prompt": "", "query": "", "model_version": ""}
		else:
			print("use ai")
			var request = {
				"request_type": "npc",
				"messages": chat.get_chat_history(until_message),
				"npc_name": "王者荣耀模拟器",
				"npc_setting": "你是一个王者荣耀局面模拟器，你将根据玩家和队友的对话，生成一个符合当前局面的事件，事件应该和【交互历史】形成连续的战报。你的回复应该避免和历史对话中的内容重复。例如“玩家（伽罗）被击杀了。”“某某（兰陵王）击败了风暴龙王。”",
				"npc_style": "你的语言风格应该简练、客观。",
				"npc_example": "“玩家（伽罗）被击杀了。”\n“某某（兰陵王）击败了风暴龙王。”\n“某某（蔡文姬）奶量充足，硬生生把残血队友全部抬满，成功守住高地。”\n“玩家（盾山）精准卡住敌方关键技能，为队友创造了绝佳的反打机会。”\n“某某（百里守约）在超远距离狙击，成功收割掉敌方残血刺客。”\n“玩家（貂蝉）在团战中翩翩起舞，打出了高额的真实伤害，拿下三杀。”\n“某某（程咬金）丝血浪进敌方水晶，成功骗出敌方关键技能。”",
				"npc_status": "",
				"npc_story": "",
				"npc_hero_name": "",
				"npc_hero_lane": "",
				"scenario": "",
				"player_hero_name": GameManager.player.hero_name,
				"player_hero_lane": GameManager.player.hero_lane,
				"instructions": "你应该参照示例的格式，结合【交互历史】推演游戏局面的演化，生成一条本次对局中的事件。"
			}

			var env_scenario = "本局中我方的英雄有："
			for npc in chat.members.values():
				if npc.npc_type in [NPCType.NPC, NPCType.PLAYER]:
					env_scenario += npc.npc_name + "（" + npc.hero_name + "-" + npc.hero_lane + "）,"
			env_scenario = env_scenario.rstrip(",") + "。"
			request["scenario"] = env_scenario

			print("=====", request)
			var response = await AIManager.get_ai_response(request)

			if response.get("status") == "success":
				if response.has("prompt") and response.has("query"):
					print(response["prompt"] + "\n" + response["query"])
				return {
					"response": response.get("response", ""), 
					"prompt": response.get("prompt", ""), 
					"query": response.get("query", ""), 
					"model_version": response.get("model_version", ""),
					"skip_save": true
				}
			else:
				return {"response": "系统消息", "prompt": "", "query": "", "model_version": ""}
			
	elif npc_type == NPCType.NPC:
		scenario = get_scenario(chat)

		if not use_ai:
			return {"response": "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message(), "prompt": "", "query": "", "model_version": ""}
		var request = {
			"request_type": "npc",
			"messages": chat.get_chat_history(until_message),
			"npc_name": npc_name,
			"npc_setting": npc_setting,
			"npc_style": npc_style,
			"npc_example": npc_example,
			"npc_status": npc_status,
			"npc_story": npc_story,
			"npc_hero_name": hero_name,
			"npc_hero_lane": hero_lane,
			"scenario": scenario,
			"player_hero_name": GameManager.player.hero_name,
			"player_hero_lane": GameManager.player.hero_lane,
			"instructions": GameManager.ai_instructions
		}
		var response = await AIManager.get_ai_response(request)
		
		if response.get("status") == "success":
			if response.has("prompt") and response.has("query"):
				print(response["prompt"] + "\n" + response["query"])
			return {
				"response": response.get("response", ""), 
				"prompt": response.get("prompt", ""), 
				"query": response.get("query", ""), 
				"model_version": response.get("model_version", ""),
			}
		else:
			return {"response": "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message(), "prompt": "", "query": "", "model_version": ""}
	else:
		return {"response": "", "prompt": "", "query": "", "model_version": ""}

func quit_group_chat() -> void:
	if current_chat.chat_type == Chat.ChatType.GROUP:
		current_chat.remove_member(npc_name)
		current_chat = GameManager.chat_dict[npc_name]

func get_scenario(chat: Chat) -> String:
	# 获取日期和时间（早上、中午、晚上等）
	var current_time = GameManager.main_view.chat_view.current_time
	var current_date = GameManager.main_view.chat_view.current_date
	if current_time == null:
		current_time = Time.get_time_dict_from_system()
	if current_date == null:
		current_date = Time.get_date_dict_from_system()
	var hour = current_time["hour"] 
	var time_period = ""
	if hour >= 5 and hour < 12:
		time_period = "早上"
	elif hour >= 12 and hour < 14:
		time_period = "中午" 
	elif hour >= 14 and hour < 18:
		time_period = "下午"
	elif hour >= 18 and hour < 23:
		time_period = "晚上"
	else:
		time_period = "深夜"
	# 获取时间，格式参考"2025年02月12日 14:56:41，星期三"
	var weekday = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"][current_date["weekday"]]
	var datetime_str = "%d年%02d月%02d日 %02d:%02d:%02d，%s" % [
		current_date["year"],
		current_date["month"], 
		current_date["day"],
		current_time["hour"],
		current_time["minute"], 
		current_time["second"],
		weekday
	]
	scenario = "当前时间：" + datetime_str + "。\n"
	scenario += "现在是" + time_period + "。\n"
	scenario += "这是一段发生在队友之间的语音聊天。" + npc_name + "正在和玩家进行一场王者荣耀对局，" + npc_name + "是玩家的队友。玩家使用的角色是" + GameManager.player.hero_name + "（" + GameManager.player.hero_lane + "），" + npc_name + "使用的角色是" + hero_name + "（" + hero_lane + "）。其他队友包括："

	var other_list = []
	for other in chat.members.values():
		if other.npc_name != npc_name and other.npc_name != GameManager.player.npc_name and other.npc_name != GameManager.system.npc_name and other.npc_name != GameManager.env.npc_name:
			other_list.append(other.npc_name + "（" + other.hero_name + "-" + other.hero_lane + "）")
	scenario += ", ".join(other_list)
	if other_list.size() > 0:
		scenario += "。"

	return scenario

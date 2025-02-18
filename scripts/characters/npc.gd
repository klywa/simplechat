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
	if npc_type == NPCType.ENV:
		await GameManager.main_view.get_tree().create_timer(1).timeout
		return {"response": "系统消息", "prompt": "", "query": "", "model_version": ""}
	elif npc_type == NPCType.NPC:
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
				"model_version": response.get("model_version", "")
			}
		else:
			return {"response": "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message(), "prompt": "", "query": "", "model_version": ""}
	else:
		return {"response": "", "prompt": "", "query": "", "model_version": ""}

func quit_group_chat() -> void:
	if current_chat.chat_type == Chat.ChatType.GROUP:
		current_chat.remove_member(npc_name)
		current_chat = GameManager.chat_dict[npc_name]

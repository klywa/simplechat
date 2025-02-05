class_name NPC
extends Node

enum NPCType {
	PLAYER,
	NPC,
	ENV,
	SYSTEM
}

var npc_name: String
var npc_setting: String
var npc_style : String
var npc_example : String
var npc_status : String
var npc_inventory : Dictionary
var npc_skill : Dictionary
var is_player: bool
var avatar_path: String
var chat_list: Array = [] 
var npc_type: NPCType
var hero_name: String
var hero_lane: String

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

		avatar_path = data.get("avatar_path", "")
	else:
		pass

func generate_response(chat : Chat, use_ai: bool=false) -> String:
	if npc_type == NPCType.ENV:
		await GameManager.main_view.get_tree().create_timer(1).timeout
		return "系统消息"
	elif npc_type == NPCType.NPC:
		if not use_ai:
			return "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message()
		var scenario = npc_name + "正在和玩家进行一场王者荣耀对局，" + npc_name + "是玩家的队友。玩家使用的角色是" + GameManager.player.hero_name + "（" + GameManager.player.hero_lane + "），" + npc_name + "使用的角色是" + hero_name + "（" + hero_lane + "）。"
		var request = {
			"request_type": "npc",
			"messages": chat.get_chat_history(),
			"npc_name": npc_name,
			"npc_setting": npc_setting,
			"npc_style": npc_style,
			"npc_example": npc_example,
			"npc_status": npc_status,
			"npc_hero_name": hero_name,
			"npc_hero_lane": hero_lane,
			"scenario": scenario,
			"player_hero_name": GameManager.player.hero_name,
			"player_hero_lane": GameManager.player.hero_lane,
			"instructions": GameManager.ai_instructions
		}
		var response = await AIManager.get_ai_response(request)
		
		if response.get("status") == "success":
			return response.get("response", "")
		else:
			return "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message()
	else:
		return ""

func quit_group_chat() -> void:
	if current_chat.chat_type == Chat.ChatType.GROUP:
		current_chat.remove_member(npc_name)
		current_chat = GameManager.chat_dict[npc_name]

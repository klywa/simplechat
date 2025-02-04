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

func generate_response(chat : Chat) -> String:
	await GameManager.main_view.get_tree().create_timer(1).timeout
	if npc_type == NPCType.ENV:
		return "系统消息" + chat.get_last_message()
	elif npc_type == NPCType.NPC:
		return "你好！我是" + npc_name + "，很高兴见到你！" + chat.get_last_message()
	else:
		return ""

func quit_group_chat() -> void:
	if current_chat.chat_type == Chat.ChatType.GROUP:
		current_chat.remove_member(npc_name)
		current_chat = GameManager.chat_dict[npc_name]

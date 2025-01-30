class_name NPC
extends Node

enum NPCType {
	PLAYER,
	NPC,
	ENV
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

var current_chat: ChatView


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
	else:
		pass

func generate_response(chat : ChatView) -> String:
	return "你好!"

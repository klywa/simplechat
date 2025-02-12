class_name Chat
extends Node

enum ChatType {
	PRIVATE,
	GROUP
}

var messages: Array
var chat_type : ChatType
var members: Dictionary
var host: Variant
var host_name : String
var speaker_index : int
var last_speaker : NPC
var is_koh : bool = false

const MESSAGE_SCENE := preload("res://scenes/ui/message.tscn") as PackedScene
const SYSTEM_MESSAGE_SCENE := preload("res://scenes/ui/system_message.tscn") as PackedScene

signal message_added(message: Dictionary)

func _init():
	message_added.connect(on_message_added)

func init():
	if host is Location and host.location_name == "王者峡谷":
		is_koh = true

func add_member(npc: NPC):
	if npc.npc_name not in members:
		members[npc.npc_name] = npc
		if chat_type == ChatType.GROUP and npc.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
			if not is_koh:	
				if host is NPC:
					add_message(GameManager.system, npc.npc_name + "来到了" + host.npc_name + "。")
				elif host is Location:
					add_message(GameManager.system, npc.npc_name + "来到了" + host.location_name + "。")
	
	if is_koh and chat_type == ChatType.GROUP:
		# random choose a speaker, avoid player and env
		var speaker_list = []
		for nn in members.values():
			if nn.npc_type != NPC.NPCType.PLAYER and nn.npc_type != NPC.NPCType.ENV:
				speaker_list.append(nn)
		if speaker_list.size() > 0:
			var random_index = randi() % speaker_list.size()
			last_speaker = speaker_list[random_index]
			speaker_index = members.values().find(last_speaker)

func remove_member(npc_name: String):
	if chat_type == ChatType.GROUP and ((npc_name in GameManager.npc_dict and GameManager.npc_dict[npc_name].npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]) or (npc_name == GameManager.player.npc_name and GameManager.player.npc_type == NPC.NPCType.PLAYER)):
		if npc_name in members:
			members.erase(npc_name)
			if not is_koh:
				if host is NPC:
					add_message(GameManager.system, npc_name + "离开了" + host.npc_name + "。")
				elif host is Location:
					add_message(GameManager.system, npc_name + "离开了" + host.location_name + "。")

	if is_koh and chat_type == ChatType.GROUP:
		# random choose a speaker, avoid player and env
		var speaker_list = []
		for nn in members.values():
			if nn.npc_type != NPC.NPCType.PLAYER and nn.npc_type != NPC.NPCType.ENV:
				speaker_list.append(nn)
		if speaker_list.size() > 0:
			var random_index = randi() % speaker_list.size()
			last_speaker = speaker_list[random_index]
			speaker_index = members.values().find(last_speaker)	


func get_member(npc_name: String):
	return members.get(npc_name, null)

func add_message(sender: NPC, content: String, auxiliary: Dictionary={}, follow_up: bool = true):
	var tmp_message
	if sender.npc_type in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
		tmp_message = SYSTEM_MESSAGE_SCENE.instantiate()
	elif sender.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
		tmp_message = MESSAGE_SCENE.instantiate()
	tmp_message.chat = self
	tmp_message.sender = sender
	tmp_message.sender_type = sender.npc_type
	tmp_message.message = content
	tmp_message.prompt = auxiliary.get("prompt", "")
	tmp_message.query = auxiliary.get("query", "")
	tmp_message.model_version = auxiliary.get("model_version", "")
	tmp_message.abandon = auxiliary.get("abandon", false)
	if is_koh and chat_type == ChatType.GROUP:
		if sender.npc_type == NPC.NPCType.NPC:
			if sender.hero_name != "" and tmp_message is Message:
				tmp_message.right_side_label_text = "（" + sender.hero_name + "）"

	messages.append(tmp_message)
	if follow_up:
		message_added.emit(tmp_message)	

	# if GameManager.main_view.chat_view.chat == self:
	# 	GameManager.main_view.chat_view.add_message(tmp_message)
		

func remove_message(message : Variant):
	messages.erase(message)

func on_message_added(message: Message):
	if chat_type == ChatType.PRIVATE:
		await GameManager.get_tree().process_frame
		if message.sender_type == NPC.NPCType.PLAYER:
			var response : Dictionary = {}
			if GameManager.main_view.chat_view.use_ai_toggle.button_pressed:
				response = await host.generate_response(self, true)
			else:
				response = await host.generate_response(self, false)
			add_message(host, response.get("response", ""), response)
	elif chat_type == ChatType.GROUP and is_koh:
		if message.sender_type != NPC.NPCType.PLAYER:
			return
		await GameManager.get_tree().process_frame
		
		for npc in members.values():
			if npc.npc_type == NPC.NPCType.PLAYER:
				continue
			for alias in npc.alias:
				if alias in message.message:
					last_speaker = npc
					break
		if last_speaker != null:
			speaker_index = members.values().find(last_speaker)
			var response = await last_speaker.generate_response(self, GameManager.main_view.chat_view.use_ai_toggle.button_pressed)
			add_message(last_speaker, response.get("response", ""), response)
				
	else:
		pass


func get_chat_history(until_message: Variant=null) -> String:
	var history = ""
	for message in messages:
		if message == until_message:
			break
		history += message.sender.npc_name + "：" + message.message+ "\n"
	return history.strip_edges()


func get_last_message() -> String:
	if messages.size() == 0:
		return ""
	return messages[-1].message

func save_to_json(json_file_path: String):
	var json_file = FileAccess.open(json_file_path, FileAccess.WRITE)
	var chat_name = ""
	if host is NPC:
		chat_name = host.npc_name
	elif host is Location:
		chat_name = host.location_name
	var json_dict = {
		"chat_name": chat_name,
		"chat_type": "PRIVATE" if chat_type == ChatType.PRIVATE else "GROUP",
		"members": [],
		"messages": []
	}
	for member in members.values():
		var tmp_member = {
			"npc_name": member.npc_name,
			"npc_type": member.npc_type,
			"npc_setting": member.npc_setting,
			"npc_style": member.npc_style,
			"npc_example": member.npc_example,
			"npc_status": member.npc_status,
			"npc_inventory": member.npc_inventory,
			"npc_skill": member.npc_skill,
			"npc_story": member.npc_story,
			"hero_name": member.hero_name,
			"hero_lane": member.hero_lane,
			"alias": member.alias,
		}
		match member.npc_type:
			NPC.NPCType.NPC:
				tmp_member["npc_type"] = "NPC"
			NPC.NPCType.PLAYER:
				tmp_member["npc_type"] = "PLAYER"
			NPC.NPCType.ENV:
				tmp_member["npc_type"] = "ENV"
			NPC.NPCType.SYSTEM:
				tmp_member["npc_type"] = "SYSTEM"
		json_dict["members"].append(tmp_member)

	for message in messages:
		# print("scenario", message.sender.scenario)
		var tmp_message = {
			"npc_name": message.sender.npc_name,
			"message": message.message,
			"negative_message": message.negative_message,
			"problem_tags": message.problem_tags,
			"abandon": message.abandon,
			"query": message.query,
			"model_version": message.model_version,
			"npc_type": "",
			"npc_setting": message.sender.npc_setting,
			"npc_style": message.sender.npc_style,
			"npc_example": message.sender.npc_example,
			"npc_status": message.sender.npc_status,
			"npc_story": message.sender.npc_story,
			"scenario": message.sender.scenario,
			"npc_inventory": message.sender.npc_inventory,
			"npc_skill": message.sender.npc_skill,
			"npc_hero_name": message.sender.hero_name,
			"npc_hero_lane": message.sender.hero_lane,
			"player_hero_name": GameManager.player.hero_name,
			"player_hero_lane": GameManager.player.hero_lane,
			"instructions": GameManager.ai_instructions,
		}
		match message.sender.npc_type:
			NPC.NPCType.NPC:
				tmp_message["npc_type"] = "NPC"
			NPC.NPCType.PLAYER:
				tmp_message["npc_type"] = "PLAYER"
			NPC.NPCType.ENV:
				tmp_message["npc_type"] = "ENV"
			NPC.NPCType.SYSTEM:
				tmp_message["npc_type"] = "SYSTEM"
		if tmp_message["npc_type"] != "SYSTEM":
			json_dict["messages"].append(tmp_message)
	json_file.store_string(JSON.stringify(json_dict, "\t", false))
	json_file.close()


func load_from_json(json_file_path: String):
	var json_file = FileAccess.open(json_file_path, FileAccess.READ)
	if json_file == null:
		return
		
	var json_text = json_file.get_as_text()
	var json_dict = JSON.parse_string(json_text)
	if json_dict == null:
		print("json解析失败")
		return
		
	# 替换成员
	members.clear()
	for member in json_dict["members"]:
		if member["npc_type"] == "NPC":
			if member["npc_name"] not in GameManager.npc_dict:
				print("成员不存在", member["npc_name"])
				return
			members[member["npc_name"]] = GameManager.npc_dict[member["npc_name"]]
			if "hero_name" in member:
				members[member["npc_name"]].hero_name = member["hero_name"]
			if "hero_lane" in member:
				members[member["npc_name"]].hero_lane = member["hero_lane"]
			if "alias" in member:
				members[member["npc_name"]].alias = member["alias"]
		elif member["npc_type"] == "PLAYER":
			members[member["npc_name"]] = GameManager.player
			if "hero_name" in member:
				members[member["npc_name"]].hero_name = member["hero_name"]
			if "hero_lane" in member:
				members[member["npc_name"]].hero_lane = member["hero_lane"]
			if "alias" in member:
				members[member["npc_name"]].alias = member["alias"]
		elif member["npc_type"] == "ENV":
			members[member["npc_name"]] = GameManager.env
		elif member["npc_type"] == "SYSTEM":
			members[member["npc_name"]] = GameManager.system
			
	# 清空当前消息
	messages.clear()
	
	# 添加新消息
	for message in json_dict["messages"]:
		var sender : NPC
		match message.get("npc_type", ""):
			"NPC":
				sender = GameManager.npc_dict[message["npc_name"]]
			"PLAYER":
				sender = GameManager.player
			"ENV":
				sender = GameManager.env
			"SYSTEM":
				sender = GameManager.system
		sender.npc_setting = message["npc_setting"]
		sender.npc_style = message["npc_style"] 
		sender.npc_example = message["npc_example"]
		sender.npc_status = message["npc_status"]
		sender.npc_story = message.get("npc_story", "")
		sender.scenario = message["scenario"]
		sender.npc_inventory = message["npc_inventory"]
		sender.npc_skill = message["npc_skill"]
		sender.hero_name = message["npc_hero_name"]
		sender.hero_lane = message["npc_hero_lane"]
		
		add_message(sender, message["message"], {
			"negative_message": message["negative_message"],
			"problem_tags": message["problem_tags"],
			"query": message["query"],
			"model_version": message["model_version"],
			"abandon": message.get("abandon", false),
		}, false)
		
	json_file.close()


func clear():
	messages.clear()

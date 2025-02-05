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
	if chat_type == ChatType.GROUP and GameManager.npc_dict[npc_name].npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
		if npc_name in members:
			members.erase(npc_name)
			if host is NPC:
				add_message(GameManager.system, npc_name + "离开了" + host.npc_name + "。")
			elif host is Location:
				add_message(GameManager.system, npc_name + "离开了" + host.location_name + "。")

func get_member(npc_name: String):
	return members.get(npc_name, null)

func add_message(sender: NPC, content: String):
	var tmp_message
	if sender.npc_type in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
		tmp_message = SYSTEM_MESSAGE_SCENE.instantiate()
	elif sender.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
		tmp_message = MESSAGE_SCENE.instantiate()
	tmp_message.chat = self
	tmp_message.sender = sender
	tmp_message.sender_type = sender.npc_type
	tmp_message.message = content
	messages.append(tmp_message)
	message_added.emit(tmp_message)

	# if GameManager.main_view.chat_view.chat == self:
	# 	GameManager.main_view.chat_view.add_message(tmp_message)
		

func remove_message(message : Variant):
	messages.erase(message)

func on_message_added(message: Message):
	if chat_type == ChatType.PRIVATE:
		await GameManager.get_tree().process_frame
		if message.sender_type == NPC.NPCType.PLAYER:
			var response : String = ""
			if GameManager.main_view.chat_view.use_ai_toggle.button_pressed:
				response = await host.generate_response(self, true)
			else:
				response = await host.generate_response(self, false)
			add_message(host, response)
	elif chat_type == ChatType.GROUP and is_koh:
		if message.sender_type != NPC.NPCType.PLAYER:
			return
		await GameManager.get_tree().process_frame
		
		for npc in members.values():
			if npc.npc_type == NPC.NPCType.PLAYER:
				continue
			if npc.npc_name in message.message or npc.hero_name in message.message or npc.hero_lane in message.message:
				last_speaker = npc
				break
		if last_speaker != null:
			speaker_index = members.values().find(last_speaker)
			var response = await last_speaker.generate_response(self, GameManager.main_view.chat_view.use_ai_toggle.button_pressed)
			add_message(last_speaker, response)
				
	else:
		pass


func get_chat_history() -> String:
	var history = ""
	for message in messages:
		history += message.sender.npc_name + "：" + message.message+ "\n"
	return history.strip_edges()


func get_last_message() -> String:
	if messages.size() == 0:
		return ""
	return messages[-1].message

func save_to_json(json_file_path: String):
	var json_file = FileAccess.open(json_file_path, FileAccess.WRITE)
	var json_dict = {
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
		var tmp_message = {
			"npc_name": message.sender.npc_name,
			"message": message.message,
			"negative_message": message.negative_message,
			"npc_type": "",
			"npc_setting": message.sender.npc_setting,
			"npc_style": message.sender.npc_style,
			"npc_example": message.sender.npc_example,
			"npc_status": message.sender.npc_status,
			"npc_inventory": message.sender.npc_inventory,
			"npc_skill": message.sender.npc_skill,
			"npc_hero_name": message.sender.hero_name,
			"npc_hero_lane": message.sender.hero_lane,
			"player_hero_name": GameManager.player.hero_name,
			"player_hero_lane": GameManager.player.hero_lane,
			"instructions": GameManager.ai_instructions
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

class_name Chat
extends Node

enum ChatType {
	PRIVATE,
	GROUP
}

var messages: Array
var chat_type : ChatType
var members: Dictionary
var host : String
var speaker_index : int

const MESSAGE_SCENE := preload("res://scenes/ui/message.tscn") as PackedScene
const SYSTEM_MESSAGE_SCENE := preload("res://scenes/ui/system_message.tscn") as PackedScene

signal message_added(message: Dictionary)

func _init():
	message_added.connect(on_message_added)

func add_member(npc: NPC):
	members[npc.npc_name] = npc

func remove_member(npc_name: String):
	members.erase(npc_name)

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
		if message.sender_type == NPC.NPCType.PLAYER:
			var response = await members[host].generate_response(self)
			add_message(members[host], response)
	elif chat_type == ChatType.GROUP:
		pass


func get_chat_history() -> String:
	var history = ""
	for message in messages:
		history += message.get("sender", "") + "：" + message.get("message", "") + "\n"
	return history.strip_edges()


func get_last_message() -> String:
	if messages.is_empty():
		return ""
	return messages[-1].message

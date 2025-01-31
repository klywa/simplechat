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

signal message_added(message: Dictionary)

func _init():
	message_added.connect(on_message_added)

func add_member(npc: NPC):
	members[npc.npc_name] = npc

func remove_member(npc_name: String):
	members.erase(npc_name)

func get_member(npc_name: String):
	return members.get(npc_name, null)

func add_message(sender: NPC, message: String):
	var message_dict = {
		"sender": sender,
		"sender_type": sender.npc_type,
		"message": message,
	}

	messages.append(message_dict)
	GameManager.main_view.chat_view.refresh()
	message_added.emit(message_dict)

func on_message_added(message: Dictionary):
	if chat_type == ChatType.PRIVATE:
		if message.get("sender_type", NPC.NPCType.NPC) == NPC.NPCType.PLAYER:
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
	return messages[-1].get("message", "")

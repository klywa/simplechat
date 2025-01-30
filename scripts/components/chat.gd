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

func add_member(npc: NPC):
	members[npc.npc_name] = npc

func remove_member(npc_name: String):
	members.erase(npc_name)

func get_member(npc_name: String):
	return members.get(npc_name, null)

func add_message(sender: NPC, message: String):
	messages.append(
		{
			"sender": sender,
			"sender_type": sender.npc_type,
			"message": message,
		}
	)

func get_chat_history() -> String:
	var history = ""
	for message in messages:
		history += message.get("sender", "") + "：" + message.get("message", "") + "\n"
	return history.strip_edges()
	
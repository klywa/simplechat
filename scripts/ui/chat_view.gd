class_name ChatView
extends MarginContainer

enum ChatType {
	PRIVATE,
	GROUP
}

@onready var message_list := $ChatContainer/ChatWindow/ScrollContainer/MessageList
@onready var name_label := $ChatContainer/NamePanel/MarginContainer/CenterContainer/NameLabel
@onready var dialogue_target : OptionButton = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer2/DialogueTarget
@onready var action_input : LineEdit = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer2/ActionInput
@onready var dialogue_input : LineEdit = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer/DialogueContent
@onready var send_button : Button = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer/MarginContainer/SendButton
@onready var no_chat_panel : PanelContainer = $NoChatPanel

var chat : Chat

const MESSAGE_SCENE := preload("res://scenes/ui/message.tscn") as PackedScene
const SYSTEM_MESSAGE_SCENE := preload("res://scenes/ui/system_message.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	no_chat_panel.visible = true

	for child in message_list.get_children():
		message_list.remove_child(child)

	send_button.pressed.connect(on_send_button_pressed)

	# var npc1 = NPC.new()
	# npc1.npc_name = "小明"
	# npc1.npc_type = NPC.NPCType.NPC

	# var npc2 = NPC.new()
	# npc2.npc_name = "小红"
	# npc2.npc_type = NPC.NPCType.PLAYER

	# var env = NPC.new()
	# env.npc_name = "环境"
	# env.npc_type = NPC.NPCType.ENV

	# add_message(npc1, "你好，我是小明")
	# add_message(npc2, "你好，我是小红")
	# add_message(env, "系统消息")

	dialogue_target.add_item("自言自语")


func init(chat_in : Chat) -> void:
	no_chat_panel.visible = false
	chat = chat_in
	name_label.text = chat.host

	for child in message_list.get_children():
		message_list.remove_child(child)
	
	for option in range(dialogue_target.get_item_count()):
		dialogue_target.remove_item(option)

	if chat.chat_type == Chat.ChatType.PRIVATE:
		for member in chat.members.values():
			if member.npc_type == NPC.NPCType.NPC:
				dialogue_target.add_item("对" + member.npc_name + "说")
				dialogue_target.select(dialogue_target.get_item_count() - 1)
				break
				# for i in range(dialogue_target.get_item_count()):
				# 	if dialogue_target.get_item_text(i) == "对" + member.npc_name + "说":
				# 		dialogue_target.select(i)
				# 		break
	else:
		name_label.text = chat.host
		for member in chat.members.values():
			dialogue_target.add_item("对" + member.npc_name + "说")
		for i in range(dialogue_target.get_item_count()):
			if dialogue_target.get_item_text(i) == "自言自语":
					dialogue_target.select(i)
					break
	
	refresh()
	

func on_send_button_pressed() -> void:
	# print("name: " + GameManager.player.npc_name)
	# print("type: " + str(GameManager.player.npc_type))
	
	var action = ""
	if action_input.text.length() > 0 or dialogue_input.text.length() > 0:
		if action_input.text.length() > 0:
			action += "（" + action_input.text + "）"
		if dialogue_input.text.length() > 0:
			action += "[" + dialogue_target.text +  "]" + dialogue_input.text
	
	chat.add_message(GameManager.player, action)
	refresh()

func set_chat(chat_in : Chat) -> void:
	chat = chat_in

func refresh() -> void:
	clear_message_list()
	for message in chat.messages:
		var tmp_message = MESSAGE_SCENE.instantiate()
		tmp_message.sender = message.get("sender", null)
		tmp_message.sender_type = message.get("sender_type", null)
		tmp_message.message = message.get("message", null)
		message_list.add_child(tmp_message)
		tmp_message._show()

func clear_message_list() -> void:
	for child in message_list.get_children():
		message_list.remove_child(child)


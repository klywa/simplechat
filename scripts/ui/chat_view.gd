class_name ChatView
extends MarginContainer

enum ChatType {
	PRIVATE,
	GROUP
}

@onready var message_list := $ChatContainer/ChatWindow/MarginContainer/ScrollContainer/MessageList
@onready var name_label := $ChatContainer/NamePanel/MarginContainer/CenterContainer/NameLabel
@onready var dialogue_target : OptionButton = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer2/DialogueTarget
@onready var action_input : LineEdit = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer2/ActionInput
@onready var dialogue_input : LineEdit = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer/DialogueContent
@onready var send_button : Button = $ChatContainer/MessagePanel/MarginContainer3/VBoxContainer/HBoxContainer/MarginContainer/SendButton
@onready var no_chat_panel : PanelContainer = $NoChatPanel
@onready var scroll_container : ScrollContainer = $ChatContainer/ChatWindow/MarginContainer/ScrollContainer
@onready var env_button : Button = $ChatContainer/ScenePanel/MarginContainer2/EnvButton
@onready var member_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/MemberButton
@onready var npc_slots := $ChatContainer/ScenePanel/MarginContainer2/VBoxContainer/HBoxContainer/NPCButtonSlots
@onready var player_slot := $ChatContainer/ScenePanel/MarginContainer2/VBoxContainer/HBoxContainer/PlayerButtonSlots
@onready var member_panel := $MemberPanel
@onready var accept_member_button := $MemberPanel/PanelContainer/VBoxContainer/HBoxContainer/AcceptButton
@onready var cancel_member_button := $MemberPanel/PanelContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var member_list := $MemberPanel/PanelContainer/VBoxContainer/MemberList
@onready var join_group_chat_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/JoinChat
@onready var leave_group_chat_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/LeaveChat

var chat : Chat

const MESSAGE_SCENE := preload("res://scenes/ui/message.tscn") as PackedScene
const SYSTEM_MESSAGE_SCENE := preload("res://scenes/ui/system_message.tscn") as PackedScene
const CHARACTER_BUTTON_SCENE := preload("res://scenes/ui/character_button.tscn") as PackedScene

signal refreshed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	no_chat_panel.visible = true

	send_button.pressed.connect(on_send_button_pressed)
	env_button.pressed.connect(on_env_button_pressed)
	action_input.text_submitted.connect(_on_action_submitted)
	dialogue_input.text_submitted.connect(_on_dialogue_submitted)

	member_button.pressed.connect(on_member_button_pressed)
	accept_member_button.pressed.connect(on_accept_member_button_pressed)
	cancel_member_button.pressed.connect(on_cancel_member_button_pressed)


func init(chat_in : Chat) -> void:
	no_chat_panel.visible = false
	chat = chat_in
	name_label.text = chat.host

	for child in npc_slots.get_children():
		npc_slots.remove_child(child)

	for child in player_slot.get_children():
		player_slot.remove_child(child)

	for child in message_list.get_children():
		message_list.remove_child(child)

	member_list.clear()
	
	while dialogue_target.get_item_count() > 0:
		dialogue_target.remove_item(0)
	dialogue_target.add_item("自言自语")

	if chat.chat_type == Chat.ChatType.PRIVATE:
		member_button.visible = false
		join_group_chat_button.visible = false
		leave_group_chat_button.visible = false

		for member in chat.members.values():
			if member.npc_type == NPC.NPCType.NPC:
				dialogue_target.add_item("对" + member.npc_name + "说")
				dialogue_target.select(dialogue_target.get_item_count() - 1)
				break
	else:
		member_button.visible = true
		join_group_chat_button.visible = true
		leave_group_chat_button.visible = true

		name_label.text = chat.host
		for member in chat.members.values():
			dialogue_target.add_item("对" + member.npc_name + "说")
		for i in range(dialogue_target.get_item_count()):
			if dialogue_target.get_item_text(i) == "自言自语":
				dialogue_target.select(i)
				break
		for npc in GameManager.npc_dict.values():
			member_list.add_item(npc.npc_name)
			if npc.npc_name in chat.members:
				member_list.select(member_list.get_item_count() - 1)

	for character in chat.members.values():
		if character.npc_type == NPC.NPCType.NPC:
			var tmp_button = CHARACTER_BUTTON_SCENE.instantiate()
			npc_slots.add_child(tmp_button)
			tmp_button.init(character)
			tmp_button.avatar.flip_h = true
		elif character.npc_type == NPC.NPCType.PLAYER:
			var tmp_button = CHARACTER_BUTTON_SCENE.instantiate()
			player_slot.add_child(tmp_button)
			tmp_button.init(character)
	
	refresh()
	chat.message_added.connect(add_message)
	# chat.message_added.connect(refresh)

func on_send_button_pressed() -> void:
	
	var action = ""
	if action_input.text.length() > 0 or dialogue_input.text.length() > 0:
		if action_input.text.length() > 0:
			action += "（" + action_input.text + "）"
		if dialogue_input.text.length() > 0:
			action += "[" + dialogue_target.text +  "]" + dialogue_input.text
	
		chat.add_message(GameManager.player, action)

		action_input.text = ""
		dialogue_input.text = ""

func set_chat(chat_in : Chat) -> void:
	chat = chat_in

func refresh() -> void:
	clear_message_list()
	# for message in chat.messages:
	# 	if message.get("sender_type", null) in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
	# 		var tmp_message = MESSAGE_SCENE.instantiate()
	# 		tmp_message.sender = message.get("sender", null)
	# 		tmp_message.sender_type = message.get("sender_type", null)
	# 		tmp_message.message = message.get("message", null)
	# 		message_list.add_child(tmp_message)
	# 		tmp_message._show()
	# 	elif message.get("sender_type", null) in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
	# 		var tmp_message = SYSTEM_MESSAGE_SCENE.instantiate()
	# 		tmp_message.sender = message.get("sender", null)
	# 		tmp_message.sender_type = message.get("sender_type", null)
	# 		tmp_message.message = message.get("message", null)
	# 		message_list.add_child(tmp_message)
	# 		tmp_message._show()

	for message in chat.messages:
		message_list.add_child(message)
		message._show()
	
	await scroll_container.get_v_scroll_bar().changed
	scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value

	refreshed.emit()

func add_message(message: Variant) -> void:
	message_list.add_child(message)
	message._show()

	await scroll_container.get_v_scroll_bar().changed
	scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value

func save_chat() -> void:
	chat.messages = []
	for child in message_list.get_children():
		if child.save_message:
			chat.messages.append(
				{
					"sender": child.sender,
					"sender_type": child.sender.npc_type,
					"message": child.content_label.text,
				}
			)

func clear_message_list() -> void:
	for child in message_list.get_children():
		message_list.remove_child(child)

func _on_action_submitted(text: String):
	on_send_button_pressed()
	
func _on_dialogue_submitted(text: String):
	on_send_button_pressed()

func on_env_button_pressed():
	var response = await GameManager.env.generate_response(chat)
	chat.add_message(GameManager.env, response)

# func add_system_message(message: String) -> void:
# 	var tmp_message = SYSTEM_MESSAGE_SCENE.instantiate()
# 	tmp_message.sender = GameManager.system
# 	tmp_message.sender_type = NPC.NPCType.SYSTEM
# 	tmp_message.message = message
# 	message_list.add_child(tmp_message)
# 	tmp_message._show()

func on_member_button_pressed() -> void:
	member_panel.visible = true

func on_accept_member_button_pressed() -> void:
	if chat.chat_type != Chat.ChatType.GROUP:
		return
	var add_list = []
	var leave_list = []
	var selected_list = [GameManager.env.npc_name]
	for index in member_list.get_selected_items():
		selected_list.append(member_list.get_item_text(index))
	for npc_name in selected_list:
		if npc_name not in chat.members:
			chat.add_member(GameManager.npc_dict[npc_name])
			add_list.append(npc_name)
	for npc_name in chat.members:
		if npc_name not in selected_list:
			chat.remove_member(npc_name)
			leave_list.append(npc_name)
	member_panel.visible = false

	init(chat)
	for npc_name in add_list:
		chat.add_message(GameManager.system, npc_name + "来到了" + chat.host + "。")
	for npc_name in leave_list:
		chat.add_message(GameManager.system, npc_name + "离开了" + chat.host + "。")


func on_cancel_member_button_pressed() -> void:
	member_panel.visible = false

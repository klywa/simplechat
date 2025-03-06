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
@onready var env_button : Button = $ChatContainer/ScenePanel/MarginContainer2/RightCornerButtonList/EnvButton
@onready var use_ai_toggle := $ChatContainer/ScenePanel/MarginContainer2/RightCornerButtonList/UseAIToggle
@onready var member_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/MemberButton
@onready var npc_slots := $ChatContainer/ScenePanel/MarginContainer2/VBoxContainer/HBoxContainer/NPCButtonSlots
@onready var player_slot := $ChatContainer/ScenePanel/MarginContainer2/VBoxContainer/HBoxContainer/PlayerButtonSlots
@onready var member_panel := $MemberPanel
@onready var accept_member_button := $MemberPanel/PanelContainer/VBoxContainer/HBoxContainer/AcceptButton
@onready var cancel_member_button := $MemberPanel/PanelContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var random_member_button := $MemberPanel/PanelContainer/VBoxContainer/HBoxContainer/RandomButton
@onready var member_list := $MemberPanel/PanelContainer/VBoxContainer/MemberList
@onready var join_group_chat_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/JoinChat
@onready var leave_group_chat_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/LeaveChat
@onready var clear_chat_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/ClearChat
@onready var new_button := $ChatContainer/ScenePanel/MarginContainer2/RightCornerButtonList/NewButton
@onready var save_button := $ChatContainer/NamePanel/MarginContainer/VBoxContainer/SaveButton
@onready var load_button := $ChatContainer/NamePanel/MarginContainer/VBoxContainer/LoadButton
@onready var save_panel := $SavePanel
@onready var save_path_input := $SavePanel/PanelContainer/MarginContainer/VBoxContainer/SaveFilePath
@onready var confirm_save_button := $SavePanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ConfirmSaveButton
@onready var cancel_save_button := $SavePanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CancelSaveButton

@onready var scene_panel := $ChatContainer/ScenePanel/MarginContainer2
@onready var left_corner_button_list := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList
@onready var expand_button := $ChatContainer/ScenePanel/MarginContainer2/LeftCornerButtonList/ExpandButton

@onready var load_file_panel := $LoadFilePanel
@onready var save_file_panel := $SaveFilePanel


var chat : Chat

const MESSAGE_SCENE := preload("res://scenes/ui/message.tscn") as PackedScene
const SYSTEM_MESSAGE_SCENE := preload("res://scenes/ui/system_message.tscn") as PackedScene
const CHARACTER_BUTTON_SCENE := preload("res://scenes/ui/character_button.tscn") as PackedScene
const MESSAGE_SPACE_HOLDER := preload("res://scenes/ui/message_space_holder.tscn") as PackedScene

var current_time = null
var current_date = null

var load_file_path : String = ""
var load_file_name : String = ""

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
	random_member_button.pressed.connect(on_random_member_button_pressed)

	join_group_chat_button.pressed.connect(on_join_group_chat_button_pressed)
	leave_group_chat_button.pressed.connect(on_leave_group_chat_button_pressed)

	new_button.pressed.connect(on_new_button_pressed)
	save_button.pressed.connect(on_save_button_pressed)
	load_button.pressed.connect(on_load_button_pressed)
	# confirm_save_button.pressed.connect(on_confirm_save_button_pressed)
	# cancel_save_button.pressed.connect(on_cancel_save_button_pressed)

	load_file_panel.canceled.connect(on_cancel_load_button_pressed)
	load_file_panel.file_selected.connect(on_load_file_selected)
	save_file_panel.canceled.connect(on_cancel_save_button_pressed)
	save_file_panel.file_selected.connect(on_confirm_save_button_pressed)

	clear_chat_button.pressed.connect(on_clear_chat_button_pressed)

	expand_button.pressed.connect(on_expand_button_pressed)

	member_button.visible = false
	join_group_chat_button.visible = false
	leave_group_chat_button.visible = false
	clear_chat_button.visible = false
	expand_button.text = ">"


func init(chat_in : Chat) -> void:

	if GameManager.mode == "pipeline" and GameManager.safe_export:
		save_button.visible = false
		load_button.visible = false

	current_time = Time.get_time_dict_from_system()
	current_date = Time.get_date_dict_from_system()

	no_chat_panel.visible = false
	chat = chat_in
	if chat.host is NPC:
		name_label.text = chat.host.npc_name
	elif chat.host is Location:
		name_label.text = chat.host.location_name

	for child in npc_slots.get_children():
		npc_slots.remove_child(child)

	for child in player_slot.get_children():
		player_slot.remove_child(child)

	for child in message_list.get_children():
		message_list.remove_child(child)

	member_list.clear()
	
	while dialogue_target.get_item_count() > 0:
		dialogue_target.remove_item(0)
	
	if chat.chat_type == Chat.ChatType.GROUP:
		dialogue_target.add_item("对大家说")
	dialogue_target.add_item("自言自语")

	if chat.chat_type == Chat.ChatType.PRIVATE:
		member_button.visible = false
		join_group_chat_button.visible = false
		leave_group_chat_button.visible = false
		expand_button.visible =false
		clear_chat_button.visible = true

		for member in chat.members.values():
			if member.npc_type == NPC.NPCType.NPC:
				dialogue_target.add_item("对" + member.npc_name + "说")
				dialogue_target.select(dialogue_target.get_item_count() - 1)
				break
	else:
		expand_button.visible = true
		clear_chat_button.visible = false
		member_button.visible = false
		join_group_chat_button.visible = false
		leave_group_chat_button.visible = false
		expand_button.text = ">"

		if chat.host is Location:
			name_label.text = chat.host.location_name
		elif chat.host is NPC:
			name_label.text = chat.host.npc_name

		for member in chat.members.values():
			if member.npc_type == NPC.NPCType.NPC:
				dialogue_target.add_item("对" + member.npc_name + "说")
		for i in range(dialogue_target.get_item_count()):
			if dialogue_target.get_item_text(i) == "对大家说":
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
			tmp_button.init(character, chat)
			tmp_button.character_left_clicked.connect(on_character_left_clicked)
			tmp_button.avatar.flip_h = true
		elif character.npc_type == NPC.NPCType.PLAYER:
			var tmp_button = CHARACTER_BUTTON_SCENE.instantiate()
			player_slot.add_child(tmp_button)
			tmp_button.init(character, chat)
			tmp_button.character_left_clicked.connect(on_character_left_clicked)
	refresh()
	chat.message_added.connect(add_message)
	# chat.message_added.connect(refresh)

	if GameManager.mode == "pipeline":
		AIManager.init_chat(chat)

func on_send_button_pressed() -> void:
	
	var action = ""
	if action_input.text.length() > 0 or dialogue_input.text.length() > 0:
		if action_input.text.length() > 0:
			action += "（" + action_input.text + "）"
		if dialogue_input.text.length() > 0:
			if dialogue_target.text == "对大家说":
				action += dialogue_input.text
			else:
				action += "[" + dialogue_target.text + "]" + dialogue_input.text
	
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

	# check the last message of message_list, if it's message_space_holder, remove it
	for child in message_list.get_children():
		if child is MessageSpaceHolder:
			message_list.remove_child(child)
			break

	message_list.add_child(message)
	message._show()

	message_list.add_child(MESSAGE_SPACE_HOLDER.instantiate())

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
	var response = await GameManager.env.generate_response(chat, use_ai_toggle.button_pressed)
	chat.add_message(GameManager.system, response.get("response", ""), response)

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
	var selected_list = []
	for index in member_list.get_selected_items():
		selected_list.append(member_list.get_item_text(index))
	for npc_name in selected_list:
		if npc_name not in chat.members:
			chat.add_member(GameManager.npc_dict[npc_name])
			add_list.append(npc_name)
	for npc_name in chat.members:
		if chat.members[npc_name] == GameManager.player or chat.members[npc_name] == GameManager.env:
			continue
		if npc_name not in selected_list:
			leave_list.append(npc_name)
	for npc_name in leave_list:
		chat.remove_member(npc_name)
	member_panel.visible = false

	if chat.is_koh:

		# 为selected_list中的每个NPC指定一个英雄，根据NPC的lane，从GameManager.lane_hero_dict中随机选择一个英雄
		for npc_name in selected_list:
			var npc = chat.members[npc_name]
			var lane = npc.hero_lane
			var hero_list = GameManager.lane_hero_dict[lane]
			var hero = hero_list[randi() % hero_list.size()]
			npc.hero_name = hero
			npc.hero_id = GameManager.hero_id_dict[hero]
			npc.hero_lane = lane
			npc.lane_id = GameManager.lane_id_dict[lane]
			npc.update_alias()
			npc.origin_hero_name = hero
			npc.origin_hero_id = GameManager.hero_id_dict[hero]
			npc.origin_hero_lane = lane
			npc.origin_lane_id = GameManager.lane_id_dict[lane]


		# 在上路、打野、中路、辅助、下路中，选择一个上述NPC没有选择的lane，为GameManager.player指定一个这个lane的英雄
		var used_lanes = []
		for npc_name in selected_list:
			var npc = chat.members[npc_name]
			used_lanes.append(npc.hero_lane)
		
		var available_lanes = []
		for lane in ["上路", "打野", "中路", "辅助", "下路"]:
			if lane not in used_lanes:
				available_lanes.append(lane)
		
		if available_lanes.size() > 0:
			var random_lane = available_lanes[randi() % available_lanes.size()]
			var hero_list = GameManager.lane_hero_dict[random_lane]
			var hero = hero_list[randi() % hero_list.size()]
			GameManager.player.hero_name = hero
			GameManager.player.hero_id = GameManager.hero_id_dict[hero]
			GameManager.player.hero_lane = random_lane
			GameManager.player.lane_id = GameManager.lane_id_dict[random_lane]
			GameManager.player.origin_hero_name = hero
			GameManager.player.origin_hero_id = GameManager.hero_id_dict[hero]
			GameManager.player.origin_hero_lane = random_lane
			GameManager.player.origin_lane_id = GameManager.lane_id_dict[random_lane]


	init(chat)

	print("simulator: ", GameManager.simulator)
	print("chat simulator", GameManager.main_view.simulator)
	GameManager.simulator.init(chat)

	# for npc_name in add_list:
	# 	chat.add_message(GameManager.system, npc_name + "来到了" + chat.host + "。")
	# for npc_name in leave_list:
	# 	chat.add_message(GameManager.system, npc_name + "离开了" + chat.host + "。")

func on_random_member_button_pressed():
	if chat.is_koh:
		var all_lanes = ["上路", "打野", "中路", "辅助", "下路"]
		# 随机选择4个分路
		var selected_lanes = []
		all_lanes.shuffle()
		for i in range(4):
			selected_lanes.append(all_lanes[i])

		print("selected_lanes: ", selected_lanes)
			
		# 清除之前的选择
		member_list.deselect_all()

		# 为每个分路随机选择一个NPC
		for lane in selected_lanes:
			var lane_npcs = []
			for index in member_list.get_item_count():
				var npc = GameManager.npc_dict[member_list.get_item_text(index)]
				if npc.hero_lane == lane:
					lane_npcs.append(npc.npc_name)
					print(lane, " lane_npcs: ", lane_npcs)
			
			if lane_npcs.size() > 0:
				# 随机选择一个该分路的NPC
				var random_npc_name = lane_npcs[randi() % lane_npcs.size()]
				for index in member_list.get_item_count():
					if member_list.get_item_text(index) == random_npc_name:
						member_list.select(index, false)
				# member_list.select(member_list.get_item_index(random_npc_name))
				print("selected ", random_npc_name)
	

func on_cancel_member_button_pressed() -> void:
	member_panel.visible = false

func on_join_group_chat_button_pressed() -> void:
	if GameManager.player.npc_name in chat.members:
		return 
	chat.add_member(GameManager.player)
	init(chat)
	# chat.add_message(GameManager.system, GameManager.player.npc_name + "来到了" + chat.host + "。")

func on_leave_group_chat_button_pressed() -> void:
	if GameManager.player.npc_name not in chat.members:
		return
	chat.remove_member(GameManager.player.npc_name)
	init(chat)
	# chat.add_message(GameManager.system, GameManager.player.npc_name + "离开了" + chat.host + "。")

func on_character_left_clicked(character: NPC) -> void:
	if character.npc_type == NPC.NPCType.NPC:
		var response : Dictionary = {}
		if use_ai_toggle.button_pressed:
			print("use ai")
			response = await character.generate_response(chat, true)
		else:
			print("not use ai")
			response = await character.generate_response(chat, false)
		chat.add_message(character, response.get("response", ""), response)
		chat.last_speaker = character
		chat.speaker_index = chat.members.values().find(character)

func replay_from_message(message: Variant) -> void:
	if not (message is Message or message is SystemMessage):
		return 
	# remove message below the given message (include the given message) and then show the removed messages
	# one by one, with time delay of 1 second between each message
	var removed_messages = []
	for child in message_list.get_children():
		if child.get_index() >= message.get_index():
			removed_messages.append(child)
	for child in removed_messages:
		message_list.remove_child(child)
	
	await get_tree().create_timer(1.0).timeout
	
	for child in removed_messages:
		message_list.add_child(child)
		if child is Message or child is SystemMessage:
			child._show()

		await scroll_container.get_v_scroll_bar().changed
		scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value

		await get_tree().create_timer(1.0).timeout

func on_save_button_pressed() -> void:
	# save_panel.visible = true
	save_file_panel.visible = true
	var current_time_string = Time.get_datetime_string_from_system(false, true)

	if load_file_path != "":
		save_file_panel.set_current_dir(load_file_path)
	else:
		save_file_panel.set_current_dir("./data/")

	if load_file_name != "":
		save_file_panel.current_file = load_file_name
	else:
		if chat.host is NPC:
			save_file_panel.current_file = chat.host.npc_name + "_" + current_time_string.replace(" ", "_").replace(":", "-") + ".json"
		elif chat.host is Location:
			save_file_panel.current_file = chat.host.location_name + "_" + current_time_string.replace(" ", "_").replace(":", "-") + ".json"

func on_confirm_save_button_pressed(file_path: String) -> void:
	# save_panel.visible = false
	# var file_path = "res://data/" + save_path_input.text + ".json"
	# chat.save_to_json(file_path)
	save_file_panel.visible = false
	chat.save_to_json(file_path)

	if file_path != load_file_path + "/" + load_file_name:
		load_file_name = ""
	load_file_path = save_file_panel.current_dir

func on_cancel_save_button_pressed() -> void:
	save_file_panel.visible = false

func on_load_button_pressed() -> void:
	load_file_panel.visible = true

func on_cancel_load_button_pressed() -> void:
	load_file_panel.visible = false

func on_load_file_selected(file_path: String) -> void:
	load_file_panel.visible = false
	chat.load_from_json(file_path)
	init(chat)
	
	load_file_path = load_file_panel.current_dir
	load_file_name = load_file_panel.current_file
	# print(load_file_path, load_file_name)

func on_clear_chat_button_pressed() -> void:
	chat.clear()
	init(chat)

func on_expand_button_pressed() -> void:
	if member_button.visible:
		member_button.visible = false
		join_group_chat_button.visible = false
		leave_group_chat_button.visible = false
		clear_chat_button.visible = false
		expand_button.text = ">"
	else:
		member_button.visible = true
		join_group_chat_button.visible = true
		leave_group_chat_button.visible = true
		clear_chat_button.visible = true
		expand_button.text = "<"


func on_new_button_pressed() -> void:
	on_member_button_pressed()
	on_random_member_button_pressed()
	on_accept_member_button_pressed()

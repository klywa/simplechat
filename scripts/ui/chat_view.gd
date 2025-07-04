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

@onready var convert_to_text_button := $ChatContainer/NamePanel/MarginContainer/VBoxContainer/ConvertToText
@onready var text_history_panel := $TextHistoryPanel
@onready var text_history_model_verstion := $TextHistoryPanel/Panel/MarginContainer/VBoxContainer/ModelVersion
@onready var text_history := $TextHistoryPanel/Panel/MarginContainer/VBoxContainer/TextHistory

@onready var review_panel := $ReviewPanel
@onready var review_file_name := $ReviewPanel/PanelContainer/VBoxContainer/MarginContainer3/ReivewFileName
@onready var review_options := $ReviewPanel/PanelContainer/VBoxContainer/MarginContainer/ReviewOptions
@onready var review_confirm_button := $ReviewPanel/PanelContainer/VBoxContainer/MarginContainer2/ConfirmReview

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

var autosave_file_name : String = ""

signal refreshed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	no_chat_panel.visible = true

	send_button.pressed.connect(on_send_button_pressed)
	env_button.pressed.connect(on_env_button_pressed)
	action_input.text_submitted.connect(_on_action_submitted)
	dialogue_input.text_submitted.connect(_on_dialogue_submitted)

	action_input.focus_entered.connect(on_input_focus_entered)
	dialogue_input.focus_entered.connect(on_input_focus_entered)

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

	convert_to_text_button.pressed.connect(on_convert_to_text_button_pressed)

	text_history_panel.close_requested.connect(on_text_history_close_requested)

	clear_chat_button.pressed.connect(on_clear_chat_button_pressed)

	expand_button.pressed.connect(on_expand_button_pressed)

	review_confirm_button.pressed.connect(on_review_confirm_button_pressed)

	member_button.visible = false
	join_group_chat_button.visible = false
	leave_group_chat_button.visible = false
	clear_chat_button.visible = false
	expand_button.text = ">"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Review"):
		review_panel.visible = true
		review_file_name.text = chat.current_file_name

		for i in range(review_options.get_item_count()):
			if review_options.get_item_text(i) == chat.review_result:
				review_options.select(i)
				break

func on_review_confirm_button_pressed() -> void:
	chat.review_result = review_options.get_item_text(review_options.selected)
	print("current_review_result: ", chat.review_result)
	if chat.current_file_name != "":
		chat.save_to_json(chat.current_file_name)
	else:
		print("current_file_name is empty")
	review_panel.visible = false

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
				dialogue_target.add_item(member.npc_name)
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
				dialogue_target.add_item(member.npc_name)
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
			if character.pawn != null and chat.is_koh:
				tmp_button.set_hero_avatar()
		elif character.npc_type == NPC.NPCType.PLAYER:
			var tmp_button = CHARACTER_BUTTON_SCENE.instantiate()
			player_slot.add_child(tmp_button)
			tmp_button.init(character, chat)
			tmp_button.character_left_clicked.connect(on_character_left_clicked)
			if character.pawn != null and chat.is_koh:
				tmp_button.set_hero_avatar()
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
				action += dialogue_input.text
	
		chat.add_message(GameManager.player, action)

		action_input.text = ""
		dialogue_input.text = ""

		if dialogue_target.text in chat.members.keys():
			chat.last_speaker = chat.members[dialogue_target.text]
			dialogue_target.select(0)
			chat.last_speaker_assigned = true

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

	if message.sender.npc_type in [NPC.NPCType.NPC, NPC.NPCType.PLAYER]:
		autosave_chat()
		if message.game_index >= GameManager.last_reply_index:
			GameManager.last_reply_index = message.game_index
	
	# if message.game_index >= GameManager.game_index:
	# 	GameManager.simulator.update_replay_info(true)
	# 	print("========================= frame saved along with message =========================")
	# 	print(GameManager.simulator.replay_info[-1])

func autosave_chat() -> void:
	if autosave_file_name == "":
		set_autosave_filename()
	chat.save_to_json(autosave_file_name)

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

	var member_heroes = []
	var opponent_heroes = []

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
			member_heroes.append(hero)


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
			member_heroes.append(hero)

		# 为上路、打野、中路、辅助、下路的每个分路，选择一个目前不再chat.members中的NPC，作为chat.opponent_members的成员
		chat.opponent_members.clear()
		for lane in ["上路", "打野", "中路", "辅助", "下路"]:
			var lane_npcs = []
			for npc_name in GameManager.npc_dict:
				var npc = GameManager.npc_dict[npc_name]
				if npc.hero_lane == lane and npc.npc_name not in chat.members:
					lane_npcs.append(npc)
			
			if lane_npcs.size() > 0:
				var random_npc = lane_npcs[randi() % lane_npcs.size()]
				# 为对手NPC设置英雄
				var hero_list = GameManager.lane_hero_dict[lane]
				# for h in GameManager.lane_hero_dict[lane]:
				# 	if h not in member_heroes:
				# 		hero_list.append(h)
				var hero = hero_list[randi() % hero_list.size()]
				random_npc.hero_name = hero
				random_npc.hero_id = GameManager.hero_id_dict[hero]
				random_npc.hero_lane = lane
				random_npc.lane_id = GameManager.lane_id_dict[lane]
				random_npc.update_alias()
				random_npc.origin_hero_name = hero
				random_npc.origin_hero_id = GameManager.hero_id_dict[hero]
				random_npc.origin_hero_lane = lane
				random_npc.origin_lane_id = GameManager.lane_id_dict[lane]
				
				chat.opponent_members[random_npc.npc_name] = random_npc

				opponent_heroes.append(hero)

				print("OPPONENT MEMBERS: ", random_npc.npc_name, " ", chat.opponent_members[random_npc.npc_name].hero_name)

	init(chat)

	print("simulator: ", GameManager.simulator)
	print("chat simulator", GameManager.main_view.simulator)
	print("chat opponent_members: ", chat.opponent_members.keys())
	print("chat opponent_heroes: ", opponent_heroes)
	GameManager.new_chat()
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
	GameManager.main_view.minimap.simulate_button.disabled = true

	if not (message is Message or message is SystemMessage):
		return

	var first_index = message.game_index
	var max_index = max(chat.messages[-1].game_index, GameManager.simulator.replay_info[-1].get("game_index", 0))

	var simulation_replay_delay = GameManager.main_view.simulation_replay_delay
	var message_replay_delay = GameManager.main_view.message_replay_delay
	
	# remove message below the given message (include the given message) and then show the removed messages
	# one by one, with time delay of 1 second between each message
	var removed_messages = []
	for child in message_list.get_children():
		if child.get_index() >= message.get_index():
			removed_messages.append(child)
	for child in removed_messages:
		message_list.remove_child(child)

	# 找到第一个小于first_index的帧
	var target_frame = null
	for frame in GameManager.simulator.replay_info:
		if frame.get("game_index", 0) < first_index:
			target_frame = frame
		else:
			break
	
	if target_frame:
		GameManager.simulator.set_frame_info(target_frame, 0.0)
	
	await get_tree().create_timer(1.0).timeout
	
	# for child in removed_messages:
	# 	message_list.add_child(child)
	# 	if child is Message or child is SystemMessage:
	# 		child._show()

	# 	await scroll_container.get_v_scroll_bar().changed
	# 	scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value

	# 	await get_tree().create_timer(1.0).timeout

	for i in range(first_index, max_index+1):

		var skip_message = true
		var skip_simulation = true

		for frame in GameManager.simulator.replay_info:
			if frame.get("game_index", 0) == i:
				skip_simulation = false
				print("simulate frame: ", i)
				GameManager.simulator.set_frame_info(frame, simulation_replay_delay)

				for child in removed_messages:
					if child is Message or child is SystemMessage:
						if child.game_index == i:
							skip_message = false
							message_list.add_child(child)
							child._show()
				if not skip_message:
					await scroll_container.get_v_scroll_bar().changed
					scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value
		
		if not skip_simulation:
			await get_tree().create_timer(simulation_replay_delay).timeout

		if skip_simulation:
			for child in removed_messages:
				if child is Message or child is SystemMessage:
					if child.game_index == i:
						print("message frame: ", i)
						skip_message = false
						message_list.add_child(child)
						child._show()

			if not skip_message:
				await scroll_container.get_v_scroll_bar().changed
				scroll_container.scroll_vertical =  scroll_container.get_v_scroll_bar().max_value
				await get_tree().create_timer(message_replay_delay).timeout

	GameManager.main_view.minimap.simulate_button.disabled = false


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
	load_file_path = ""
	load_file_name = ""

func on_load_button_pressed() -> void:
	load_file_panel.visible = true

func on_cancel_load_button_pressed() -> void:
	load_file_panel.visible = false

func on_load_file_selected(file_path: String) -> void:
	load_file_panel.visible = false
	chat.load_from_json(file_path)
	init(chat)

	set_autosave_filename()
	
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
	on_clear_chat_button_pressed()
	set_autosave_filename()


func set_autosave_filename() -> void:
	clean_autosave_files()
	autosave_file_name = "data/autosave_" + get_current_time_string().replace(" ", "_").replace(":", "-") + ".json"

func clean_autosave_files() -> void:
	# 检查并清理自动保存文件，保留最新的19个
	var dir = DirAccess.open("data")
	if dir:
		var files = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		# 收集所有以autosave_开头的文件
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("autosave_"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		# 按字母顺序排序（由于文件名格式为autosave_YYYY-MM-DD_HH:MM:SS.json，
		# 所以按字母顺序排序即为按时间排序）
		files.sort()
		
		# 如果文件数超过19个，删除最旧的文件
		while files.size() > 19:
			var oldest_file = files[0]
			var file_path = "data/" + oldest_file
			if FileAccess.file_exists(file_path):
				DirAccess.remove_absolute(file_path)
			files.remove_at(0)


func get_current_time_string() -> String:
	# 从当前日期和时间获取格式化的时间字符串
	if current_time == null:
		current_time = Time.get_time_dict_from_system()
	if current_date == null:
		current_date = Time.get_date_dict_from_system()
	
	# 格式化为 "YYYY-MM-DD_HH:MM:SS" 格式
	var time_string = "%04d-%02d-%02d_%02d:%02d:%02d" % [
		current_date["year"],
		current_date["month"],
		current_date["day"],
		current_time["hour"],
		current_time["minute"],
		current_time["second"]
	]
	
	return time_string


func set_current_time_from_string(input_time_string: String) -> void:
	# 从input_time_string中获取日期和时间，格式与Time.get_date_dict_from_system()和Time.get_time_dict_from_system()的格式相同
	# 预期格式: "YYYY-MM-DD_HH:MM:SS"
	var result = {}
	
	# 检查输入字符串格式是否正确
	if input_time_string.length() != 19 or input_time_string[4] != '-' or input_time_string[7] != '-' or input_time_string[10] != '_' or input_time_string[13] != ':' or input_time_string[16] != ':':
		push_error("时间字符串格式错误，应为 YYYY-MM-DD_HH:MM:SS")
		return
	
	# 解析日期部分
	var year = input_time_string.substr(0, 4).to_int()
	var month = input_time_string.substr(5, 2).to_int()
	var day = input_time_string.substr(8, 2).to_int()
	
	# 解析时间部分
	var hour = input_time_string.substr(11, 2).to_int()
	var minute = input_time_string.substr(14, 2).to_int()
	var second = input_time_string.substr(17, 2).to_int()
	
	# 计算星期几 (Zeller公式)
	var weekday = 0
	if month < 3:
		month += 12
		year -= 1
	var century = year / 100
	var year_of_century = year % 100
	weekday = (day + 13 * (month + 1) / 5 + year_of_century + year_of_century / 4 + century / 4 - 2 * century) % 7
	# 调整为Godot的星期格式（0是周日，1是周一，以此类推）
	# 确保weekday在0-6的范围内，避免访问数组越界
	weekday = (weekday + 6) % 7
	
	# 更新当前日期和时间
	current_date = {
		"year": year,
		"month": month,
		"day": day,
		"weekday": weekday
	}
	
	current_time = {
		"hour": hour,
		"minute": minute,
		"second": second
	}

func random_generate_time() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 生成随机年份（2025年及以后）
	var year = rng.randi_range(2024, 2026)
	# 生成随机月份（1-12）
	var month = rng.randi_range(1, 12)
	# 根据月份确定天数上限
	var max_day = 31
	if month in [4, 6, 9, 11]:
		max_day = 30
	elif month == 2:
		# 处理闰年
		if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
			max_day = 29
		else:
			max_day = 28
	# 生成随机天数
	var day = rng.randi_range(1, max_day)
	
	# 生成随机时间
	var hour = rng.randi_range(0, 23)
	var minute = rng.randi_range(0, 59)
	var second = rng.randi_range(0, 59)
	
	# 计算星期几 (Zeller公式)
	var weekday = 0
	if month < 3:
		month += 12
		year -= 1
	var century = year / 100
	var year_of_century = year % 100
	weekday = (day + 13 * (month + 1) / 5 + year_of_century + year_of_century / 4 + century / 4 - 2 * century) % 7
	weekday = (weekday + 6) % 7
	
	# 设置随机生成的日期和时间
	current_date = {
		"year": year,
		"month": month,
		"day": day,
		"weekday": weekday
	}
	
	current_time = {
		"hour": hour,
		"minute": minute,
		"second": second
	}
		
	# 调用设置时间函数
	return get_current_time_string()


func on_convert_to_text_button_pressed() -> void:
	text_history_panel.visible = true
	text_history_model_verstion.text = "模型版本：" + chat.get_model_version()
	text_history.text = chat.get_text_history()


func on_text_history_close_requested() -> void:
	text_history_panel.hide()

func on_input_focus_entered() -> void:
	if GameManager.simulator.frame_synced:
		GameManager.simulator.reset_frame()

func random_member_reply() -> void:
	var candidates = []
	for member in chat.members.values():
		if member.npc_type in [NPC.NPCType.NPC]:
			candidates.append(member)

	if candidates.size() > 0:
		var random_member = candidates[randi() % candidates.size()]
		var response: Dictionary = {}
		
		if use_ai_toggle.button_pressed:
			response = await random_member.generate_response(chat, true)
			chat.add_message(random_member, response.get("response", ""), response)
			chat.last_speaker = random_member
			chat.speaker_index = chat.members.values().find(random_member)

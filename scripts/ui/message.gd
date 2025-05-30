class_name Message
extends MarginContainer

var chat: Chat
var message_id : int
var message: String
var sender: NPC
var sender_type: NPC.NPCType
var save_message: bool = true
var negative_message: String
var better_response: String = ""
var prompt : String = ""
var query : String = ""
var model_version : String = ""
var score : String = ""
var problem_tags : String = ""
var right_side_label_text : String = ""
var abandon : bool = false
var time : String = ""
var elapsed_time : String = ""
var char_count : int = 0
var skip_save : bool = false
var is_consecutive: bool = false

var npc_name : String = ""
var npc_setting : String = ""
var npc_style : String = ""
var npc_example : String = ""
var npc_status : String = ""
var npc_story : String = ""
var npc_inventory : Variant
var scenario : String = ""
var npc_skill : Variant
var npc_hero_name : String = ""
var npc_hero_lane : String = ""
var player_hero_name : String = ""
var player_hero_lane : String = ""
var instructions : String = ""
var knowledge : String = ""
var memory : String = ""


@onready var name_label : Label = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/NameLabel
@onready var right_side_label : Label = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSideLabel
@onready var content_label : RichTextLabel = $MessageContainer/VBoxContainer/ContentContainer/Content
@onready var message_left_space : Control = $MessageContainer/LeftSpace
@onready var message_right_space : Control = $MessageContainer/RightSpace
@onready var name_left_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/LeftSpace
@onready var name_right_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace
@onready var revise_panel := $MessagePopupPanel
@onready var consecutive_toggle := $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace/HBoxContainer/ConsecutiveToggle
@onready var badcase_toggle := $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace/HBoxContainer/BadcaseToggle
@onready var abandon_toggle := $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace/HBoxContainer/AbandonToggle
@onready var name_button := $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/NameLabel/NameButton
# @onready var revise_content := $PopupPanel/PanelContainer/VBoxContainer/MarginContainer/ReviseContent
# @onready var revise_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
# @onready var delete_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
@onready var button := $MessageContainer/VBoxContainer/ContentContainer/Button
# @onready var replay_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton

@onready var revised_flag := $MessageContainer/VBoxContainer/ContentContainer/Button/MarginContainer/RevisedFlag


func _ready():
	revise_panel.visible = false
	abandon_toggle.visible = false
	consecutive_toggle.visible = false
	button.pressed.connect(on_button_pressed)
	revised_flag.visible = false

	revise_panel.revise_button.pressed.connect(on_revise_button_pressed)
	#revise_panel.revise_content.text_submitted.connect(on_revise_content_submitted)
	revise_panel.delete_button.pressed.connect(on_delete_button_pressed)
	revise_panel.replay_button.pressed.connect(on_replay_button_pressed)

	name_button.pressed.connect(on_name_button_pressed)

	badcase_toggle.toggled.connect(on_badcase_toggled)
	abandon_toggle.toggled.connect(on_abandon_toggled)
	consecutive_toggle.toggled.connect(on_consecutive_toggled)

func on_abandon_toggled(button_pressed: bool):
	abandon = button_pressed

func on_badcase_toggled(button_pressed: bool):
	if button_pressed:
		score = "0"
	else:
		score = ""

func on_consecutive_toggled(button_pressed: bool):
	is_consecutive = button_pressed

func _show():
	name_label.text = sender.npc_name
	content_label.text = message
	if right_side_label_text.length() > 0:
		right_side_label.text = right_side_label_text
		# if elapsed_time.length() > 0:
		# 	if char_count > 0:
		# 		right_side_label.text += "[" + str(char_count) + "字/" + elapsed_time + "]"
		# 	else:
		# 		right_side_label.text += "[" + elapsed_time + "]"
	if sender_type == NPC.NPCType.PLAYER:
		message_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		message_right_space.size_flags_horizontal = SIZE_SHRINK_END
		name_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_right_space.size_flags_horizontal = SIZE_SHRINK_END
	else:
		badcase_toggle.visible = true
		abandon_toggle.visible = true
		consecutive_toggle.visible = true
		message_left_space.size_flags_horizontal = SIZE_SHRINK_END
		message_right_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_left_space.size_flags_horizontal = SIZE_SHRINK_END
		name_right_space.size_flags_horizontal = SIZE_EXPAND_FILL
		if abandon:
			abandon_toggle.button_pressed = true
		if is_consecutive:
			consecutive_toggle.button_pressed = true
		if score == "0":
			badcase_toggle.button_pressed = true

	if better_response.length() > 0:
		revised_flag.visible = true

	# 如果message中包含"[]"，则将[]中的内容发送给send_command_to_pawn()
	var regex = RegEx.new()
	regex.compile("^（(.*?)）")
	var matches = regex.search_all(message)
	if matches:
		for m in matches:
			var command = m.get_string(1)
			send_command_to_pawn(command)

	chat.save_to_json(GameManager.tmp_save_file_path)

func send_command_to_pawn(command : String):
	print("send_command_to_pawn: ", command)
	var pawn = sender.pawn
	var target_pawn = null

	for p_name in GameManager.simulator.camp_name_pawn_dict:
		if p_name in command:
			target_pawn = GameManager.simulator.camp_name_pawn_dict[p_name]
			break
	
	if target_pawn != null and pawn != null:
		print("command send to pawn: ", pawn.pawn_name, " -> ", target_pawn.pawn_name)
		pawn.move_target = target_pawn


func on_button_pressed():
	if GameManager.mode == "pipeline" and GameManager.safe_export:
		return
	revise_panel.visible = true
	revise_panel._show()


func on_revise_button_pressed():
	if message != revise_panel.revise_content.text:
		negative_message = message
		message = revise_panel.revise_content.text
		knowledge = revise_panel.knowledge_editor.text
		memory = revise_panel.memory_editor.text
		sender.memory = memory
	elif revise_panel.memory_editor.text != memory:
		memory = revise_panel.memory_editor.text
		sender.memory = memory
	revise_panel.revise_content.text = ""
	revise_panel.visible = false

	if revise_panel.score.text.length() > 0:
		revise_panel.on_save_problem_button_pressed()

	_show()

	# print(self)
	# print(GameManager.main_view.chat_view.chat.messages)
	# GameManager.main_view.chat_view.save_chat()
	# print(GameManager.main_view.chat_view.chat.messages)

func on_delete_button_pressed():
	chat.remove_message(self)
	get_parent().remove_child(self)
	# GameManager.main_view.chat_view.save_chat()

func on_replay_button_pressed():
	revise_panel.visible = false
	GameManager.main_view.chat_view.replay_from_message(self)

func on_revise_content_submitted(text: String):
	on_revise_button_pressed()

func on_name_button_pressed():
	var tmp_scenario = "[角色状态]\n" + npc_status + "\n\n" + scenario + "\n\n[相关知识]\n" + knowledge
	sender.character_button.on_name_button_pressed(tmp_scenario)

class_name Message
extends MarginContainer

var chat: Chat
var message: String
var sender: NPC
var sender_type: NPC.NPCType
var save_message: bool = true
var negative_message: String
var prompt : String = ""
var query : String = ""
var model_version : String = ""
var problem_tags : String = ""
@onready var name_label : Label = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/NameLabel
@onready var content_label : RichTextLabel = $MessageContainer/VBoxContainer/ContentContainer/Content
@onready var message_left_space : Control = $MessageContainer/LeftSpace
@onready var message_right_space : Control = $MessageContainer/RightSpace
@onready var name_left_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/LeftSpace
@onready var name_right_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace
@onready var revise_panel := $MessagePopupPanel
# @onready var revise_content := $PopupPanel/PanelContainer/VBoxContainer/MarginContainer/ReviseContent
# @onready var revise_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
# @onready var delete_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
@onready var button := $MessageContainer/VBoxContainer/ContentContainer/Button
# @onready var replay_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton


func _ready():
	revise_panel.visible = false
	button.pressed.connect(on_button_pressed)

	revise_panel.revise_button.pressed.connect(on_revise_button_pressed)
	revise_panel.revise_content.text_submitted.connect(on_revise_content_submitted)
	revise_panel.delete_button.pressed.connect(on_delete_button_pressed)
	revise_panel.replay_button.pressed.connect(on_replay_button_pressed)


func _show():
	name_label.text = sender.npc_name
	content_label.text = message
	if sender_type == NPC.NPCType.PLAYER:
		message_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		message_right_space.size_flags_horizontal = SIZE_SHRINK_END
		name_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_right_space.size_flags_horizontal = SIZE_SHRINK_END
	else:
		message_left_space.size_flags_horizontal = SIZE_SHRINK_END
		message_right_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_left_space.size_flags_horizontal = SIZE_SHRINK_END
		name_right_space.size_flags_horizontal = SIZE_EXPAND_FILL

func on_button_pressed():
	revise_panel.visible = true
	revise_panel.revise_content.text = content_label.text
	revise_panel.revise_content.grab_focus()
	revise_panel.revise_content.set_caret_column(revise_panel.revise_content.text.length())


func on_revise_button_pressed():
	if message != revise_panel.revise_content.text:
		negative_message = message
		message = revise_panel.revise_content.text
	revise_panel.revise_content.text = ""
	revise_panel.visible = false

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
class_name SystemMessage
extends MarginContainer

@onready var content_label = $HBoxContainer/Content
@onready var button := $ReviseButton
@onready var revise_panel := $MessagePopupPanel
# @onready var revise_content := $PopupPanel/PanelContainer/VBoxContainer/MarginContainer/ReviseContent
# @onready var revise_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
# @onready var delete_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
# @onready var replay_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton

var chat: Chat
var message_id : int
var message: String
var sender: NPC
var sender_type: NPC.NPCType
var save_message: bool = true
var negative_message: String
var prompt : String = ""
var query : String = ""
var model_version : String = ""
var score : String = ""
var problem_tags : String = ""
var abandon : bool = false
var time : String = ""
var elapsed_time : String = ""
var char_count : int = 0
var scenario : String = ""
var skip_save : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_button_pressed)
	
	revise_panel.revise_button.pressed.connect(on_revise_button_pressed)
	revise_panel.revise_content.text_submitted.connect(on_revise_content_submitted)
	revise_panel.delete_button.pressed.connect(on_delete_button_pressed)
	revise_panel.replay_button.pressed.connect(on_replay_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _show() -> void:
	content_label.text = message
	chat.save_to_json(GameManager.tmp_save_file_path)

func on_button_pressed() -> void:
	revise_panel.visible = true
	revise_panel._show()

func on_revise_button_pressed() -> void:
	if message != revise_panel.revise_content.text:
		negative_message = message
		message = revise_panel.revise_content.text
	revise_panel.revise_content.text = ""
	revise_panel.visible = false

	if revise_panel.score.text.length() > 0:
		revise_panel.on_save_problem_button_pressed()

	_show()

	# GameManager.main_view.chat_view.save_chat()

func on_delete_button_pressed() -> void:
	chat.remove_message(self)
	get_parent().remove_child(self)
	# GameManager.main_view.chat_view.save_chat()


func on_replay_button_pressed() -> void:
	revise_panel.visible = false
	GameManager.main_view.chat_view.replay_from_message(self)

func on_revise_content_submitted(text: String) -> void:
	on_revise_button_pressed()
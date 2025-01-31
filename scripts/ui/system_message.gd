class_name SystemMessage
extends MarginContainer

@onready var content_label = $HBoxContainer/Content
@onready var button := $ReviseButton
@onready var revise_panel := $PopupPanel
@onready var revise_content := $PopupPanel/PanelContainer/VBoxContainer/MarginContainer/ReviseContent
@onready var revise_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
@onready var delete_button := $PopupPanel/PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete

var chat: Chat
var message: String
var sender: NPC
var sender_type: NPC.NPCType
var save_message: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_button_pressed)
	
	revise_button.pressed.connect(on_revise_button_pressed)
	delete_button.pressed.connect(on_delete_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _show() -> void:
	content_label.text = message

func on_button_pressed() -> void:
	revise_panel.visible = true
	revise_content.text = content_label.text
	revise_content.grab_focus()
	revise_content.set_caret_column(revise_content.text.length())

func on_revise_button_pressed() -> void:
	# content_label.text = revise_content.text
	message = revise_content.text
	revise_content.text = ""
	revise_panel.visible = false

	_show()

	# GameManager.main_view.chat_view.save_chat()

func on_delete_button_pressed() -> void:
	chat.remove_message(self)
	get_parent().remove_child(self)
	# GameManager.main_view.chat_view.save_chat()

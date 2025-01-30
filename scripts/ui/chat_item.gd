extends Button

@onready var chat_name_label = $PanelContainer/VBoxContainer/ChatName

var chat: Chat
var chat_name : String


func init() -> void:
	pressed.connect(on_pressed)
	chat_name_label.text = chat_name

	
func on_pressed() -> void:
	print("chat_name: " + chat_name)
	GameManager.activate_chat(chat)

extends Button

@onready var chat_name_label = $PanelContainer/VBoxContainer/ChatName
@onready var chat_avatar = $PanelContainer/VBoxContainer/ChatAvatar

var chat: Chat
var chat_name : String


func init() -> void:
	pressed.connect(on_pressed)
	chat_name_label.text = chat_name
	chat_avatar.texture = load(chat.host.avatar_path)
	
func on_pressed() -> void:
	GameManager.activate_chat(chat)
	

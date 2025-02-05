extends Control

@export var config_path : String
@export var ai_server_url : String = "http://127.0.0.1:8000"

@onready var player_icon := $VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/PlayerIcon
@onready var chat_view : ChatView = $VBoxContainer/ChatPanel/ChatWindow/ChatView
@onready var chat_list := $VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/ChatList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if config_path.length() > 0:
		GameManager.init(self, config_path)
	AIManager.init(ai_server_url)

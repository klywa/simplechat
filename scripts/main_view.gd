extends Control

@export var config_path : String

@onready var player_icon := $VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/PlayerIcon
@onready var chat_view : ChatView = $VBoxContainer/ChatPanel/ChatWindow/ChatView
@onready var chat_list := $VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/ChatList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if config_path.length() > 0:
		GameManager.init(self, config_path)

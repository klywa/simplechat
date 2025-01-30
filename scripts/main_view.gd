extends Control

@export var config_path : String

@onready var chat_view : ChatView = $HBoxContainer/ChatWindow/ChatView
@onready var chat_window := $HBoxContainer/ChatWindow
@onready var chat_list := $HBoxContainer/Sidebar/MarginContainer/VBoxContainer/ChatList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if config_path.length() > 0:
		GameManager.init(self, config_path)

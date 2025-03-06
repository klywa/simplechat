extends Control

@export_enum("single", "pipeline") var mode : String = "single"
@export var config_path : String = "res://config/default.json"
@export var ai_server_url : String = "http://9.208.245.48:8000/model_chat_14b"
@export var ai_pipeline_url : String = "http://30.50.188.179:8080/api/smartnpc"
@export var safe_export : bool = false

@onready var player_icon := $HBoxContainer/VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/PlayerIcon
@onready var chat_view : ChatView = $HBoxContainer/VBoxContainer/ChatPanel/ChatWindow/ChatView
@onready var chat_list := $HBoxContainer/VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/ChatList
@onready var minimap := $HBoxContainer/Minimap


var simulator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	simulator = minimap.simulator
	if config_path.length() > 0:
		GameManager.init(self, config_path, simulator)
	
	if mode == "pipeline":
		AIManager.init(ai_pipeline_url)
	else:
		AIManager.init(ai_server_url)


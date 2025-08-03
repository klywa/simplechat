extends Control

@export_enum("single", "pipeline") var mode : String = "single"
@export var config_path : String = "res://config/default.json"
@export var ai_server_url : String = "http://9.208.245.48:8000/model_chat/koh-0312-t2"
@export var ai_pipeline_url : String = "http://30.50.188.179:8080/api/smartnpc"
@export var knowledge_path : String = "res://config/knowledge.json"
@export var proactive_wait_time: int = 0
@export var safe_export : bool = false
@export var simulation_delay : float = 0.5
@export var simulation_replay_delay : float = 0.5
@export var message_replay_delay : float = 1.0
@export var command_duration: int = 10
@export var message_animation_time : float = 0.3
@export var no_speak_wait_time: int = 6
@export var use_minions: bool = false

@onready var player_icon := $HBoxContainer/VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/PlayerIcon
@onready var chat_view : ChatView = $HBoxContainer/VBoxContainer/ChatPanel/ChatWindow/ChatView
@onready var chat_list := $HBoxContainer/VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/ChatList
@onready var minimap := $HBoxContainer/Minimap
@onready var setting_panel := $Setting
@onready var setting_button := $HBoxContainer/VBoxContainer/ChatPanel/Sidebar/MarginContainer/VBoxContainer/MarginContainer/SettingButton
@onready var set_time_button := $Setting/MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/SetTimeButton
@onready var set_time_editor := $Setting/MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/Time
@onready var random_time_button := $Setting/MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/RandomTimeButton


var simulator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	simulator = minimap.simulator
	if config_path.length() > 0:
		GameManager.init(self, config_path, knowledge_path, simulator)
	
	if mode == "pipeline":
		AIManager.init(ai_pipeline_url)
	else:
		AIManager.init(ai_server_url)
		
	set_time_button.pressed.connect(on_set_time_button_pressed)
	setting_button.pressed.connect(on_setting_button_pressed)
	random_time_button.pressed.connect(on_random_time_button_pressed)

func on_setting_button_pressed() -> void:
	setting_panel.visible = true
	set_time_editor.text = GameManager.main_view.chat_view.get_current_time_string()

func on_set_time_button_pressed() -> void:
	setting_panel.visible = false
	GameManager.main_view.chat_view.set_current_time_from_string(set_time_editor.text)
	setting_panel.visible = false

func on_random_time_button_pressed() -> void:
	set_time_editor.text = GameManager.main_view.chat_view.random_generate_time()

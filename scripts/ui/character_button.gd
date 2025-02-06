class_name CharacterButton
extends Control

var character: NPC
var chat : Chat

@onready var button = $"."
@onready var avatar = $VBoxContainer/CenterContainer/Avatar
@onready var name_label = $VBoxContainer/Name
@onready var lane_label = $VBoxContainer/Lane

signal character_left_clicked(character: NPC)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_pressed)

func init(character_in: NPC, chat_in: Chat) -> void:
	character = character_in
	chat = chat_in
	avatar.texture = load(character.avatar_path)
	if chat.chat_type == Chat.ChatType.GROUP and chat.host is Location and chat.host.location_name == "王者峡谷":
		name_label.text = character.npc_name
		lane_label.text = character.hero_name
	else:
		lane_label.text = "无"
		lane_label.add_theme_color_override("font_color", Color(0, 0, 0, 0))
		name_label.text = character.npc_name

func on_pressed() -> void:
	character_left_clicked.emit(character)
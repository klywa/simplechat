class_name CharacterButton
extends Control

var character: NPC
var chat : Chat

@onready var button = $VBoxContainer/CenterContainer/Button
@onready var avatar = $VBoxContainer/CenterContainer/Avatar
@onready var name_label = $VBoxContainer/Name
@onready var lane_label = $VBoxContainer/Lane
@onready var name_button = $VBoxContainer/Name/NameButton
@onready var hero_button = $VBoxContainer/Lane/LaneButton

@onready var character_info_panel := $CharacterInfoPanel
@onready var setting_info := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Setting
@onready var style_info := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Style
@onready var example_info := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Example

@onready var hero_panel := $HeroPanel
@onready var new_hero_label := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Hero
@onready var new_lane_label := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Lane
@onready var confirm_hero_change_button := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Confirm
@onready var cancel_hero_change_button := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Cancel


signal character_left_clicked(character: NPC)

const CHARACTER_INFO_PANEL_SCENE = preload("res://scenes/ui/character_info_panel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_pressed)
	name_button.pressed.connect(on_name_button_pressed)

	hero_button.pressed.connect(on_hero_button_pressed)
	confirm_hero_change_button.pressed.connect(on_confirm_hero_change_button_pressed)
	cancel_hero_change_button.pressed.connect(on_cancel_hero_change_button_pressed)

func init(character_in: NPC, chat_in: Chat) -> void:

	if GameManager.mode == "pipeline":
		button.disabled = true

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

func on_name_button_pressed() -> void:
	setting_info.text = character.npc_setting
	style_info.text = character.npc_style
	example_info.text = character.npc_example
	character_info_panel.visible = true

func on_hero_button_pressed() -> void:
	hero_panel.visible = true
	new_hero_label.text = character.hero_name
	new_lane_label.text = character.hero_lane

func on_confirm_hero_change_button_pressed() -> void:
	character.hero_name = new_hero_label.text
	character.hero_lane = new_lane_label.text
	character.update_alias()
	hero_panel.visible = false
	init(character, chat)

func on_cancel_hero_change_button_pressed() -> void:
	hero_panel.visible = false

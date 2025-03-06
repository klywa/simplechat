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

@onready var exchange_button := $ExchangeButton


signal character_left_clicked(character: NPC)

const CHARACTER_INFO_PANEL_SCENE = preload("res://scenes/ui/character_info_panel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_pressed)
	name_button.pressed.connect(on_name_button_pressed)

	hero_button.pressed.connect(on_hero_button_pressed)
	confirm_hero_change_button.pressed.connect(on_confirm_hero_change_button_pressed)
	cancel_hero_change_button.pressed.connect(on_cancel_hero_change_button_pressed)
	exchange_button.pressed.connect(on_exchange_button_pressed)

	new_hero_label.text_changed.connect(on_new_hero_label_text_changed)

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
	
	if character.npc_type == NPC.NPCType.PLAYER:
		exchange_button.visible = false

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

func on_exchange_button_pressed() -> void:

	var skip_change = false
	if character.hero_name == GameManager.player.origin_hero_name:
		skip_change = true

	for n in chat.members.values():
		n.hero_name = n.origin_hero_name
		n.hero_lane = n.origin_hero_lane
		n.hero_id = n.origin_hero_id
		n.lane_id = n.origin_lane_id
		if n.pawn != null and n.origin_pawn != null:
			n.pawn = GameManager.simulator.name_pawn_dict[n.origin_pawn.get_unique_name()]
	
	if not skip_change:
		var player = GameManager.player
		var tmp_hero_name = player.hero_name
		var tmp_hero_lane = player.hero_lane
		var tmp_hero_id = player.hero_id
		var tmp_lane_id = player.lane_id
		var tmp_pawn = player.pawn

		player.hero_name = character.hero_name
		player.hero_lane = character.hero_lane
		player.hero_id = character.hero_id
		player.lane_id = character.lane_id
		player.pawn = character.pawn
		player.pawn.npc = player

		character.hero_name = tmp_hero_name
		character.hero_lane = tmp_hero_lane
		character.hero_id = tmp_hero_id
		character.lane_id = tmp_lane_id
		character.pawn = tmp_pawn
		tmp_pawn.npc = character

	for panel in get_parent().get_parent().get_children():
		for child in panel.get_children():
			if child is CharacterButton:
				child.init(child.character, child.chat)

	if GameManager.mode == "pipeline":
		chat.add_message(GameManager.env, "【交换英雄】")
	elif GameManager.mode == "single":
		var message = "玩家与" + character.npc_name + "交换了英雄。当前英雄使用情况："
		for n in chat.members.values():
			if n.npc_type in [NPC.NPCType.PLAYER, NPC.NPCType.NPC]:
				message += n.npc_name + "使用" + n.hero_name + "（" + n.hero_lane + "），"
		message = message.substr(0, message.length()-1) + "。"
		chat.add_message(GameManager.system, message)

func on_confirm_hero_change_button_pressed() -> void:
	character.hero_name = new_hero_label.text
	character.hero_lane = new_lane_label.text
	character.update_alias()
	hero_panel.visible = false
	init(character, chat)

	character.pawn.load_npc(character)

func on_cancel_hero_change_button_pressed() -> void:
	hero_panel.visible = false

func on_new_hero_label_text_changed(new_hero_str : String) -> void:
	if new_hero_str in GameManager.hero_lane_dict:
		new_lane_label.text = GameManager.hero_lane_dict[new_hero_str]

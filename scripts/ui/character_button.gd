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
@onready var ingame_info := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/InGame

@onready var hero_panel := $HeroPanel
@onready var new_hero_label := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Hero
@onready var new_lane_label := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Lane
@onready var confirm_hero_change_button := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Confirm
@onready var cancel_hero_change_button := $HeroPanel/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Cancel

@onready var skill_editor := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/SkillEditor
@onready var memory_editor := $CharacterInfoPanel/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/Memory

@onready var exchange_button := $ExchangeButton
@onready var hero_avatar := $VBoxContainer/HeroAvatar
@onready var hero_avatar_button := $VBoxContainer/HeroAvatar/HeroAvatarButton


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
	hero_avatar_button.pressed.connect(on_hero_avatar_button_pressed)
	skill_editor.text_submitted.connect(on_skill_editor_text_submitted)
	memory_editor.text_changed.connect(on_memory_editor_text_changed)

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

	character.character_button = self

func set_hero_avatar():
	# 尝试根据pawn_name加载英雄头像
	var avatar_path = "res://assets/avatars/hero_avatar/%s.webp" % character.pawn.pawn_name
	var avatar_path_2 = "res://assets/avatars/hero_avatar/%s.jpg" % character.pawn.pawn_name
	var default_path = "res://assets/avatars/hero_avatar/默认.webp"
	
	# 检查文件是否存在
	print("avatar_path: ", avatar_path)
	if FileAccess.file_exists(avatar_path):
		var texture = load(avatar_path)
		if texture:
			hero_avatar.texture = texture
	elif FileAccess.file_exists(avatar_path_2):
		var texture = load(avatar_path_2)
		if texture:
			hero_avatar.texture = texture
	else:
		# 如果找不到对应头像，使用默认头像
		print("default_path: ", default_path)
		var texture = load(default_path)
		if texture:
			hero_avatar.texture = texture
	
	# 缩放头像至96*96大小
	if hero_avatar.texture:
		var image = hero_avatar.texture.get_image()
		image.resize(48, 48)
		var new_texture = ImageTexture.create_from_image(image)
		hero_avatar.texture = new_texture

func on_pressed() -> void:
	character_left_clicked.emit(character)

func on_name_button_pressed(scenario: String = "") -> void:
	skill_editor.text = str(character.skill_level)
	setting_info.text = character.npc_setting
	style_info.text = character.npc_style
	example_info.text = character.npc_example
	if scenario != "":
		ingame_info.text = scenario
	else:
		ingame_info.text = character.ingame_info
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
			n.pawn.load_npc(n)
	
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
		player.pawn.load_npc(player)
		# player.character_button.set_hero_avatar()

		character.hero_name = tmp_hero_name
		character.hero_lane = tmp_hero_lane
		character.hero_id = tmp_hero_id
		character.lane_id = tmp_lane_id
		character.pawn = tmp_pawn
		tmp_pawn.npc = character
		tmp_pawn.load_npc(character)
		# character.character_button.set_hero_avatar()

	for panel in get_parent().get_parent().get_children():
		for child in panel.get_children():
			if child is CharacterButton:
				child.init(child.character, child.chat)
				child.set_hero_avatar()

	if GameManager.mode == "pipeline":
		chat.add_message(GameManager.env, "【交换英雄】")
	elif GameManager.mode == "single":
		var message = "玩家与" + character.npc_name + "交换了英雄。当前英雄使用情况："
		message += GameManager.player.npc_name + "使用" + GameManager.player.hero_name + "（" + GameManager.player.hero_lane + "），"
		message += character.npc_name + "使用" + character.hero_name + "（" + character.hero_lane + "）。"
		# for n in chat.members.values():
		# 	if n.npc_type in [NPC.NPCType.PLAYER, NPC.NPCType.NPC]:
		# 		message += n.npc_name + "使用" + n.hero_name + "（" + n.hero_lane + "），"
		# message = message.substr(0, message.length()-1) + "。"
		chat.add_message(GameManager.system, message)

func on_confirm_hero_change_button_pressed() -> void:
	character.hero_name = new_hero_label.text
	character.hero_lane = new_lane_label.text
	character.update_alias()
	hero_panel.visible = false
	init(character, chat)
	set_hero_avatar()

	character.pawn.load_npc(character)

	chat.messages.clear()
	GameManager.chat_view.init(chat)
	GameManager.new_chat()
	GameManager.simulator.init(chat)
	GameManager.chat_view.set_autosave_filename()

func on_cancel_hero_change_button_pressed() -> void:
	hero_panel.visible = false

func on_new_hero_label_text_changed(new_hero_str : String) -> void:
	if new_hero_str in GameManager.hero_lane_dict:
		new_lane_label.text = GameManager.hero_lane_dict[new_hero_str]

func on_hero_avatar_button_pressed() -> void:
	character.pawn._on_button_pressed(true)

func on_skill_editor_text_submitted(new_text : String) -> void:
	character.skill_level = int(new_text)
	
func on_memory_editor_text_changed() -> void:
	character.memory = memory_editor.text

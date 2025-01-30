class_name Message
extends MarginContainer

enum SenderType {
	PLAYER,
	NPC,
	SYSTEM
}

var message: String
var sender: NPC
var sender_type: SenderType

@onready var name_label : Label = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/NameLabel
@onready var content_label : RichTextLabel = $MessageContainer/VBoxContainer/ContentContainer/Content
@onready var message_left_space : Control = $MessageContainer/LeftSpace
@onready var message_right_space : Control = $MessageContainer/RightSpace
@onready var name_left_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/LeftSpace
@onready var name_right_space : Control = $MessageContainer/VBoxContainer/NameContainer/HBoxContainer/RightSpace

func _ready():
	# print("Message ready")
	pass

func _show():
	name_label.text = sender.npc_name
	content_label.text = message
	if sender_type == SenderType.PLAYER:
		message_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		message_right_space.size_flags_horizontal = SIZE_SHRINK_END
		name_left_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_right_space.size_flags_horizontal = SIZE_SHRINK_END
	else:
		message_left_space.size_flags_horizontal = SIZE_SHRINK_END
		message_right_space.size_flags_horizontal = SIZE_EXPAND_FILL
		name_left_space.size_flags_horizontal = SIZE_SHRINK_END
		name_right_space.size_flags_horizontal = SIZE_EXPAND_FILL

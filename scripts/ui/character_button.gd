class_name CharacterButton
extends Control

var character: NPC

@onready var button = $"."
@onready var avatar = $Avatar

signal character_left_clicked(character: NPC)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(on_pressed)

func init(character_in: NPC) -> void:
	character = character_in
	avatar.texture = load(character.avatar_path)

func on_pressed() -> void:
	character_left_clicked.emit(character)
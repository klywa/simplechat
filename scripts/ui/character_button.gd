class_name CharacterButton
extends Control

var character: NPC

@onready var avatar = $Avatar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init(character_in: NPC) -> void:
	character = character_in
	avatar.texture = load(character.avatar_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

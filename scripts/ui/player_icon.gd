extends Button

@onready var avatar := $MarginContainer/PlayerAvatar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func init(character: NPC) -> void:
	avatar.texture = load(character.avatar_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

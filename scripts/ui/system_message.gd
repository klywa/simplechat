class_name SystemMessage
extends MarginContainer

@onready var content_label = $HBoxContainer/Content

var content: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _show() -> void:
	content_label.text = content

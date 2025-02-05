class_name MessagePopupPanel
extends PopupPanel

@onready var revise_content := $PanelContainer/VBoxContainer/MarginContainer/ReviseContent
@onready var revise_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
@onready var delete_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
@onready var replay_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

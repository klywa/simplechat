extends MarginContainer


@onready var simulator := $PanelContainer/VBoxContainer/CenterContainer/Panel2/SubViewportContainer/SubViewport/KoHSimulator

@onready var simulate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/SimulateButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	simulate_button.pressed.connect(_on_simulate_button_pressed)

func _on_simulate_button_pressed():
	simulator.simulate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

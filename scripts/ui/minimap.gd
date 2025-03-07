extends MarginContainer


@onready var simulator := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/Panel2/SubViewportContainer/SubViewport/KoHSimulator

@onready var simulate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/SimulateButton
@onready var simulate_3x_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/Simulate3xButton

@onready var blue_money := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/BlueMoney
@onready var red_money := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/RedMoney
@onready var kill_ratio := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/CenterContainer/HBoxContainer/KillRatio
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	simulate_button.pressed.connect(_on_simulate_button_pressed)
	simulate_3x_button.pressed.connect(_on_simulate_3x_button_pressed)

func _on_simulate_button_pressed():
	simulator.simulate()

func _on_simulate_3x_button_pressed():
	simulator.simulate()
	await simulator.simulate_finished

	simulator.simulate()
	await simulator.simulate_finished

	simulator.simulate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	blue_money.text = str(simulator.blue_team_total_money)
	red_money.text = str(simulator.red_team_total_money)
	kill_ratio.text = str(simulator.blue_team_total_kill) + " : " + str(simulator.red_team_total_kill)

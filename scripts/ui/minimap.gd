extends MarginContainer


@onready var simulator := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/Panel2/SubViewportContainer/SubViewport/KoHSimulator

@onready var simulate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/SimulateButton
@onready var simulate_3x_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/Simulate3xButton

@onready var blue_money := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/BlueMoney
@onready var red_money := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/RedMoney
@onready var kill_ratio := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/KillRatio

@onready var time_label := $PanelContainer/VBoxContainer/CenterContainer3/Time

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
	time_label.text = str(simulator.match_time)
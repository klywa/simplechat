extends MarginContainer


@onready var simulator := $PanelContainer/VBoxContainer/CenterContainer/VBoxContainer/Panel2/SubViewportContainer/SubViewport/KoHSimulator

@onready var simulate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/SimulateButton
@onready var simulate_3x_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/Simulate3xButton
@onready var back_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/BackButton

@onready var blue_money := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/BlueMoney
@onready var red_money := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/RedMoney
@onready var kill_ratio := $PanelContainer/VBoxContainer/CenterContainer2/HBoxContainer/KillRatio

@onready var time_label := $PanelContainer/VBoxContainer/CenterContainer3/Time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	simulate_button.pressed.connect(_on_simulate_button_pressed)
	simulate_3x_button.pressed.connect(_on_simulate_3x_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func _on_simulate_button_pressed():
	if simulate_button.disabled:
		return

	simulate_button.disabled = true

	if simulator.frame_synced:
		simulator.reset_frame()

	simulator.simulate()
	await get_tree().create_timer(GameManager.main_view.simulation_delay * 1.2).timeout

	print("index", GameManager.game_index, GameManager.last_reply_index, GameManager.main_view.proactive_wait_time)
	if GameManager.main_view.proactive_wait_time > 0:
		if GameManager.game_index - GameManager.last_reply_index >= GameManager.main_view.proactive_wait_time:
			print("should reply")
			GameManager.chat_view.random_member_reply()
			await GameManager.chat_view.chat.message_added
	
	simulate_button.disabled = false

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


func _on_back_button_pressed():
	simulator.back_to_last_frame()
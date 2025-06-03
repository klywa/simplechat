class_name MessagePopupPanel
extends PopupPanel

@onready var revise_content := $PanelContainer/VBoxContainer/MarginContainer/ReviseContent
@onready var revise_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
@onready var delete_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
@onready var replay_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton
@onready var regenerate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer5/RegenerateButton
@onready var more_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer4/MoreButton
@onready var sync_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer6/SyncSimulation

@onready var more_panel := $MorePanel
@onready var origin_response := $PanelContainer/VBoxContainer/MarginContainer3/OriginResponse
@onready var better_resposne := $PanelContainer/VBoxContainer/MarginContainer8/BetterResponse
@onready var score := $PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/Score
@onready var problem_tags := $PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/ProblemTags
@onready var save_problem_button := $PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/SaveProblem
@onready var close_more_button := $MorePanel/PanelContainer/VBoxContainer/MarginContainer/Close
@onready var prompt := $MorePanel/PanelContainer/VBoxContainer/MarginContainer2/Prompt
@onready var time_message := $PanelContainer/VBoxContainer/MarginContainer4/TimeMessage

@onready var instruction_editor := $PanelContainer/VBoxContainer/MarginContainer6/Instructions
@onready var knowledge_editor := $PanelContainer/VBoxContainer/MarginContainer5/Knowledge
@onready var memory_editor := $PanelContainer/VBoxContainer/MarginContainer7/Memory

var current_message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	more_button.pressed.connect(on_more_button_pressed)
	save_problem_button.pressed.connect(on_save_problem_button_pressed)
	close_more_button.pressed.connect(on_close_more_button_pressed)
	regenerate_button.pressed.connect(on_regenerate_button_pressed)
	better_resposne.text_changed.connect(on_better_resposne_text_changed)
	sync_button.toggled.connect(on_sync_button_pressed)

func _show() -> void:

	if current_message != get_parent():
		sync_button.button_pressed = false
		on_sync_button_pressed(false)
	
	if not GameManager.simulator.frame_synced:
		sync_button.button_pressed = false

	current_message = get_parent()

	time_message.text = str(get_parent().char_count) + "字/" + get_parent().elapsed_time
	revise_content.text = get_parent().content_label.text
	revise_content.grab_focus()
	revise_content.set_caret_column(revise_content.text.length())
	score.text = get_parent().score
	problem_tags.text = get_parent().problem_tags
	if get_parent().negative_message != "":
		origin_response.text = get_parent().sender.npc_name + "：" + get_parent().negative_message
	else:
		origin_response.text = get_parent().sender.npc_name + "：" + get_parent().message
	instruction_editor.text = get_parent().instructions
	knowledge_editor.text = get_parent().knowledge
	memory_editor.text = get_parent().memory
	better_resposne.text = get_parent().better_response

func on_more_button_pressed() -> void:
	more_panel.visible = true
	# if get_parent().negative_message != "":
	# 	origin_response.text = get_parent().sender.npc_name + "：" + get_parent().negative_message
	# else:
	# 	origin_response.text = get_parent().sender.npc_name + "：" + get_parent().message
	prompt.text = get_parent().prompt + "\n" + get_parent().query

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_close_more_button_pressed() -> void:
	more_panel.visible = false

func on_save_problem_button_pressed() -> void:
	var message = get_parent()
	message.score = score.text
	message.problem_tags = problem_tags.text
	# on_close_more_button_pressed()

	if int(score.text) == 0:
		await get_tree().process_frame
		message.badcase_toggle.button_pressed = true
	else:
		await get_tree().process_frame
		message.badcase_toggle.button_pressed = false


func on_regenerate_button_pressed() -> void:
	var message = get_parent()
	var npc = message.sender
	var chat = message.chat
	var status = message.npc_status
	var scenario = message.scenario

	if GameManager.mode == "single":
		var response : Dictionary = await npc.generate_response(chat, true, message, instruction_editor.text, knowledge_editor.text, memory_editor.text, status, scenario)
		revise_content.text = response.get("response", "")
		
	else:
		return

func on_better_resposne_text_changed() -> void:
	var message = get_parent()
	message.better_response = better_resposne.text
	message._show()


func on_sync_button_pressed(toggled_on: bool) -> void:
	if not toggled_on:
		GameManager.simulator.reset_frame()
	else:
		GameManager.simulator.frame_synced = true
		var message = get_parent()
		var first_index = message.game_index
		
		# 找到最后一个小于first_index的帧
		var target_frame = null
		for frame in GameManager.simulator.replay_info:
			if frame.get("game_index", 0) <= first_index:
				target_frame = frame
			else:
				break
		
		if target_frame:
			GameManager.simulator.set_frame_info(target_frame, 0.0)
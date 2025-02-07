class_name MessagePopupPanel
extends PopupPanel

@onready var revise_content := $PanelContainer/VBoxContainer/MarginContainer/ReviseContent
@onready var revise_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer/Revise
@onready var delete_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer2/Delete
@onready var replay_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer3/ReplayButton
@onready var regenerate_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer5/RegenerateButton
@onready var more_button := $PanelContainer/VBoxContainer/HBoxContainer/MarginContainer4/MoreButton

@onready var more_panel := $MorePanel
@onready var origin_response := $MorePanel/PanelContainer/VBoxContainer/MarginContainer3/OriginResponse
@onready var problem_tags := $MorePanel/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/ProblemTags
@onready var save_problem_button := $MorePanel/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/SaveProblem
@onready var close_more_button := $MorePanel/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Close
@onready var prompt := $MorePanel/PanelContainer/VBoxContainer/MarginContainer2/Prompt


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	more_button.pressed.connect(on_more_button_pressed)
	save_problem_button.pressed.connect(on_save_problem_button_pressed)
	close_more_button.pressed.connect(on_close_more_button_pressed)
	regenerate_button.pressed.connect(on_regenerate_button_pressed)

func on_more_button_pressed() -> void:
	more_panel.visible = true
	if get_parent().negative_message != "":
		origin_response.text = get_parent().sender.npc_name + "：" + get_parent().negative_message
	else:
		origin_response.text = get_parent().sender.npc_name + "：" + get_parent().message
	prompt.text = get_parent().prompt
	problem_tags.text = get_parent().problem_tags

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_close_more_button_pressed() -> void:
	more_panel.visible = false

func on_save_problem_button_pressed() -> void:
	var message = get_parent()
	message.problem_tags = problem_tags.text
	on_close_more_button_pressed()

func on_regenerate_button_pressed() -> void:
	var message = get_parent()
	var npc = message.sender
	var chat = message.chat
	var response : Dictionary = await npc.generate_response(chat, true, message)
	message.negative_message = message.message
	message.message = response.get("response", "")
	message.prompt = response.get("prompt", "")
	message._show()

	self.visible = false


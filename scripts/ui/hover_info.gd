extends Control

@onready var info_textbox := $Panel/MarginContainer/RichTextLabel

func set_info(info: String):
	info_textbox.text = info

func _process(delta: float) -> void:
	if visible:
		# 获取鼠标位置
		var mouse_pos = get_viewport().get_mouse_position()
		
		# 设置面板位置,稍微偏移以避免遮挡鼠标
		global_position = Vector2(mouse_pos.x + 10, mouse_pos.y - size.y)
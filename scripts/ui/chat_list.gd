class_name ChatList
extends PanelContainer

@onready var chat_list: VBoxContainer = $ScrollContainer/List

const CHAT_ITEM_SCENE := preload("res://scenes/ui/chat_item.tscn") as PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for chat_item in chat_list.get_children():
		chat_list.remove_child(chat_item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_chat_item(chat_name : String, chat : Chat) -> void:
	var chat_item = CHAT_ITEM_SCENE.instantiate()
	chat_list.add_child(chat_item)
	chat_item.chat = chat
	chat_item.chat_name = chat_name
	chat_item.init()

	# 如果chat_item对应的chat_name为“王者峡谷”，将chat_item置于chat_list的第一个位置
	if chat_name == "王者峡谷":
		chat_list.move_child(chat_item, 0)

extends Node

var uuid = 0

func _ready() -> void:
	uuid = RandomNumberGenerator.new().randi()

func generate_uuid() -> String:
	uuid += 1
	return str(uuid)

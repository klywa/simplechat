class_name Location
extends Node

var location_name: String
var location_short_description: String
var location_description: String
var avatar_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func load_from_dict(data: Dictionary) -> void:
	location_name = data.get("location_name", "")
	location_short_description = data.get("location_short_description", "")
	location_description = data.get("location_description", "")
	avatar_path = data.get("avatar_path", "")
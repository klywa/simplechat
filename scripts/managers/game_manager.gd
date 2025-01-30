extends Node

const NPC_SCENE = preload("res://scenes/characters/npc.tscn") as PackedScene
const CHAT_SCENE = preload("res://scenes/ui/chat_view.tscn") as PackedScene
const LOCATION_SCENE = preload("res://scenes/components/location.tscn") as PackedScene

var main_view
var chat_dict: Dictionary
var npc_dict: Dictionary
var location_dict: Dictionary
var player : NPC
var env : NPC


func init(main, config_path: String) -> void:
	main_view = main
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			# print("parse_result: " + str(parse_result))
			var data = json.get_data()
			# print("data: " + str(data))
			if data is Dictionary:

				env = NPC_SCENE.instantiate()
				env.npc_name = "环境"
				env.npc_type = NPC.NPCType.ENV

				# parse player
				player = NPC_SCENE.instantiate()
				print("player: " + str(data.get("player", {})))
				player.load_from_dict(data.get("player", {}))
				player.npc_type = NPC.NPCType.PLAYER

				# parse npc
				for n in data.get("npcs", []):
					var npc_name = n.get("npc_name", "")
					npc_dict[npc_name] = NPC_SCENE.instantiate()
					# add_child(npc_dict[npc_name])
					npc_dict[npc_name].load_from_dict(n)
					npc_dict[npc_name].npc_type = NPC.NPCType.NPC

					chat_dict[npc_name + "_private"] = Chat.new()
					chat_dict[npc_name + "_private"].host = npc_name
					chat_dict[npc_name + "_private"].chat_type = Chat.ChatType.PRIVATE
					chat_dict[npc_name + "_private"].add_member(player)
					chat_dict[npc_name + "_private"].add_member(npc_dict[npc_name])

					# chat_dict[npc_name + "_private"].add_message(npc_dict[npc_name], "你好，我是"+npc_name)

					main_view.chat_list.add_chat_item(npc_name, chat_dict[npc_name + "_private"])


				# parse location
				for l in data.get("locations", []):
					location_dict[l.get("location_name", "")] = LOCATION_SCENE.instantiate()
					location_dict[l.get("location_name", "")].load_from_dict(l)

		file.close()

		print(player.npc_name + str(player.npc_type))

func activate_chat(chat_in : Chat) -> void:

	main_view.chat_view.init(chat_in)
	main_view.chat_view.refresh()

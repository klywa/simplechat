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
var system : NPC


func init(main, config_path: String) -> void:
	main_view = main
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			if data is Dictionary:

				env = NPC_SCENE.instantiate()
				env.npc_name = "环境"
				env.npc_type = NPC.NPCType.ENV

				system = NPC_SCENE.instantiate()
				system.npc_name = "系统"
				system.npc_type = NPC.NPCType.SYSTEM

				# parse player
				player = NPC_SCENE.instantiate()
				player.load_from_dict(data.get("player", {}))
				player.npc_type = NPC.NPCType.PLAYER
				main_view.player_icon.init(player)

				# parse npc
				for n in data.get("npcs", []):
					var npc_name = n.get("npc_name", "")
					npc_dict[npc_name] = NPC_SCENE.instantiate()
					# add_child(npc_dict[npc_name])
					npc_dict[npc_name].load_from_dict(n)
					npc_dict[npc_name].npc_type = NPC.NPCType.NPC

					chat_dict[npc_name] = Chat.new()
					chat_dict[npc_name].host = npc_dict[npc_name]
					chat_dict[npc_name].chat_type = Chat.ChatType.PRIVATE
					chat_dict[npc_name].add_member(player)
					chat_dict[npc_name].add_member(npc_dict[npc_name])

					# chat_dict[npc_name].add_message(npc_dict[npc_name], "你好，我是"+npc_name)

					main_view.chat_list.add_chat_item(npc_name, chat_dict[npc_name])


				# parse location
				for l in data.get("locations", []):
					var location_name = l.get("location_name", "")

					location_dict[location_name] = LOCATION_SCENE.instantiate()
					location_dict[location_name].load_from_dict(l)

					chat_dict[location_name] = Chat.new()
					chat_dict[location_name].host = location_dict[location_name]
					chat_dict[location_name].chat_type = Chat.ChatType.GROUP
					chat_dict[location_name].add_member(env)

					main_view.chat_list.add_chat_item(location_name, chat_dict[location_name])

		file.close()


func activate_chat(chat_in : Chat) -> void:

	main_view.chat_view.init(chat_in)
	main_view.chat_view.refresh()

extends Node

var server_url : String = "http://127.0.0.1:8000"
var unique_id : int 


func init(server_url_in: String) -> void:
	server_url = server_url_in
	print("ai_manager init: ", server_url)
	unique_id = int(UUIDGenerator.generate_uuid())

func get_response(request_in: Dictionary) -> Variant:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 准备请求头和数据
	var headers = ["Content-Type: application/json"]
	var request_data = JSON.stringify(request_in)
	
	print(request_data)
	print(type_string(typeof(request_data)))

	# 发送POST请求
	var error = http_request.request(server_url, headers, HTTPClient.METHOD_POST, request_data)
	if error != OK:
		printerr("发送HTTP请求时出错")
		return {"status": "error", "message": "请求发送失败"}
	
	# 等待响应
	var response = await http_request.request_completed
	
	# 清理HTTP请求节点
	http_request.queue_free()
	
	# 处理响应
	return response

func get_ai_response(request_in: Dictionary) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 准备请求头和数据
	var headers = ["Content-Type: application/json"]
	var request_data = JSON.stringify(request_in)
	
	# 发送POST请求
	var error = http_request.request(server_url, headers, HTTPClient.METHOD_POST, request_data)
	if error != OK:
		printerr("发送HTTP请求时出错")
		return {"status": "error", "message": "请求发送失败"}
	
	# 等待响应
	var response = await http_request.request_completed
	
	# 清理HTTP请求节点
	http_request.queue_free()
	
	# 处理响应
	var result = _process_response(response)
	return result

func _process_response(response: Array) -> Dictionary:
	var response_code = response[1]
	var body = response[3]
	
	if response_code != 200:
		return {"status": "error", "message": "服务器响应错误"}
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error != OK:
		return {"status": "error", "message": "JSON解析错误"}
	
	var response_data = json.get_data()
	return response_data


func init_chat(chat: Chat) -> void:
	var request = {
		"game_type" : 0,
		"gameid1":111,
		"gameid2": unique_id,
		"gameid3":333,
		"gameid4":444,
		"seq_id": 1,
		"aiserver_content": {
			"request_id": UUIDGenerator.generate_uuid(),
			"version": 1.0,
			"player_info": [],
			"seg_id": UUIDGenerator.generate_uuid(),
			"camp": 1,
			"request_dialogue": {
				"req_type" : 1,
				"query": "-new-",
				# "extra_info": {
				# 	"tts_config": {
				# 		"enable_streaming": false,
				# 		'prompt_wav_name': "lingbaoC_8",
				# 		'ar_version': "trt_ar_infer_call_has_phone_ar_350M_lingbaoSFT_eavan_20241210",
				# 		'ar_seed': 10,
				# 		'opt_ddim_steps_set': "15",
				# 		'vocoder_type': "voc_type_bigvgan_48k",
				# 	}
				# }
			}

		}
	}

	for member in chat.members.values():
		if member.npc_type in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
			continue

		request["aiserver_content"]["player_info"].append(
			{
				"uid": member.uid,
				"name": member.npc_name,
				"is_ai": true if member.npc_type == NPC.NPCType.NPC else false,
				"hero_Id": member.hero_id,
				"lane": member.lane_id,
				"object_id": member.uid,
			}
		)

	var response = await get_response(request)
	print(_process_response(response))
	# print(response)


func get_pipeline_response(chat : Chat) -> Dictionary:

	var result = {}

	var pan_data = {
		"req_type": 100, 
		"game_type": 104550, 
		"req_id": 123, 
		"req_id2": 456,
		"req_id3": 789,
		"seq_id": UUIDGenerator.generate_uuid(),
		"version": 1,
		"msg_type": 2,
		"camp": "1", 
		"query_id": "",
		"players": [],
		"messages": chat.get_pipeline_messages()
	}

	pan_data["query_id"] = pan_data["messages"][-1]["message_id"]

	for member in chat.members.values():
		if member.npc_type in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
			continue

		pan_data["players"].append(
			{
				"player_id": member.uid,
				"object_id": member.uid,
				"camp": 1,
				"type": "ai" if member.npc_type == NPC.NPCType.NPC else "human",
				"hero_id": member.hero_id,
				"lane": member.lane_id,
				"is_alive": true,
				"position": [randf_range(0, 1000), 0, randf_range(0, 1000)],
			}
		)

	var pan_json_str = JSON.stringify(pan_data)
	var pan_base64_str = Marshalls.utf8_to_base64(pan_json_str)

	var request = {
		"game_type" : 0,
		"gameid1":111,
		"gameid2": unique_id,
		"gameid3":333,
		"gameid4":444,
		"seq_id": 1,
		"aiserver_content": {
			"request_id": UUIDGenerator.generate_uuid(),
			"version": 1,
			"player_info": [],
			"camp": 1,       
			"request_dialogue": {
				"query": pan_data["messages"][-1]["content"],
				"req_type":1,
				"context": pan_base64_str,
				
			},
		}
	}

	for member in chat.members.values():
		if member.npc_type in [NPC.NPCType.ENV, NPC.NPCType.SYSTEM]:
			continue

		request["aiserver_content"]["player_info"].append(
			{
				"uid": member.uid,
				"name": member.npc_name,
				"is_ai": true if member.npc_type == NPC.NPCType.NPC else false,
				"hero_Id": member.hero_id,
				"lane": member.lane_id,
				"object_id": member.uid,
			}
		)

	var response = await get_response(request)

	var response_data = _process_response(response)

	if response_data is Dictionary and response_data.get("status", "ok") == "error":
		return {
			"speaker": "系统",
			"content": "服务器错误！",
		}

	var speaker_uid = response_data.get("response_dialogue", {}).get("extra_info", {}).get("bot_uid", "")
	var content = response_data.get("response_dialogue", {}).get("asset", {}).get("sentence_text", "")

	var time_info = response_data.get("extra_info", {}).get("time_info", {})
	var time_info_str = ""
	if time_info.size() > 0:
		time_info_str += "总用时：" + str((time_info.get("all_time", 0) - time_info.get("pre_sensitive_wangzhe_cost", 0)) / 1000) + "ms"
		time_info_str += " | 前置：" + str((time_info.get("sft_safety", 0) - time_info.get("pre_sensitive_wangzhe_cost", 0)) / 1000) + "ms"
		time_info_str += " | 回复：" + str((time_info.get("reply", 0)) - time_info.get("post_sensitive_wangzhe_cost", 0) / 1000) + "ms"
		time_info_str += " | 后置：" + str((time_info.get("post_sensitive_wangzhe_cost", 0)) / 1000) + "ms"

	if speaker_uid == "":
		return {
			"speaker": "系统",
			"content": "说话人错误！",
		}
	
	if content == "":
		return {
			"speaker": "系统",
			"content": "内容错误！",
		}

	print("=========")
	print(response_data)
	print("SPEAKER: ", speaker_uid)
	print("CONTENT: ", content)
	
	# print(response)
	var speaker : NPC
	for member in GameManager.npc_dict.values():
		if member.uid == int(speaker_uid):
			speaker = member
			break

	if speaker == null:
		return {
			"speaker": "系统",
			"content": "说话人错误！",
		}
	
	result = {
		"speaker": speaker.npc_name,
		"content": content,
		"time_info": time_info_str,
	}

	return result

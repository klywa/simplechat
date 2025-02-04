extends Node

var server_url : String = "http://127.0.0.1:8000"


func init(server_url_in: String) -> void:
	server_url = server_url_in

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

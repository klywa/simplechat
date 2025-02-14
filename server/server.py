# 一个HTTP服务器，用于接受客户端的请求，并返回响应
# 接受到用户请求之后，答应请求内容
# 之后，响应已收到
# HTTP部署到

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import ai_response
import json

app = Flask(__name__)
CORS(app)


with open("config/ai.json", "r") as f:
    ai_config = json.load(f)
api_key = ai_config["kimi_api_key"]


@app.route('/', methods=['POST'])
def handle_request():
    try:
        data = request.get_json()
        
        print(data)
        print(data.keys)

        if "aiserver_content" in data:
            return jsonify({
            "status": "error",
            "message": str(e),
            "prompt": "",
            "query": "",
            "model_version": ""
        }), 500
        # 提取AI响应
        response, prompt = ai_response.get_ai_response(data, api_key)
        
        return jsonify({
            "status": "success",
            "response": response,
            "prompt": prompt,
            "query": "",
            "model_version": "kimi"
        })
    
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "prompt": "",
            "query": "",
            "model_version": ""
        }), 500

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8000)
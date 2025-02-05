from openai import OpenAI
import json
from prompt_template import system_template, chat_template

        
def get_ai_response(request, api_key):
    
    client = OpenAI(
        api_key = api_key,
        base_url = "https://api.moonshot.cn/v1",
    )

    print(request.keys())

    prompt = chat_template.format(
        npc_name = request.get("npc_name", ""),
        npc_setting = request.get("npc_setting", ""),
        npc_style = request.get("npc_style", ""),
        npc_example = request.get("npc_example", ""),
        chat_history = request.get("messages", ""),
        instructions = request.get("instructions", ""),
        scenario = request.get("scenario", ""),
    )
    print(prompt)
    
    completion = client.chat.completions.create(
    	model = "moonshot-v1-8k",
    	messages = [
    		{"role": "system", "content": system_template},
    		{"role": "user", "content": prompt}
    	],
    	temperature = 0.3,
    )
    

    print(completion)

    result = completion.choices[0].message.content

    print(result)

    if result.startswith(f"{request.get('npc_name', '')}："):
        result = result.replace(f"{request.get('npc_name', '')}：", "")
    
    if result.startswith(f"{request.get('npc_hero_name', '')}："):
        result = result.replace(f"{request.get('npc_hero_name', '')}：", "")

    if "\n" in result:
        result = result.split("\n")[0]

    print(result)

    return result, prompt

    # print("done")
    # return "收到：" + prompt.strip().split("\n")[-1]
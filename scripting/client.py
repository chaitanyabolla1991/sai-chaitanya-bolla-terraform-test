import json
import requests

with open('example.json') as f:
    data = json.load(f)

filtered = [obj for obj in data if not obj.get('private', False)]

resp = requests.post('https://example.com/service/generate', json=filtered)
out = resp.json()

for k, v in out.items():
    if isinstance(v, dict) and v.get('valid') == True:
        print(k)


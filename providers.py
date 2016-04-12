import requests

AccessKey = "5yxRd7sRpAzZMYeUqqb8cFlClsQiupzOcdGOSL35"
SecretKey = "Is1T4v0dAT9MLmRi0aWuSG6XfCN7rflPUoFFT0YB"
TenantId = "e180eae4-ed44-11e5-9cc8-005056992152"
image = "u'cen6_64'"

request = requests.get("https://api2.numergy.com/")
data = request.json()
version = (data['versions'][4]['id'])

body = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "5yxRd7sRpAzZMYeUqqb8cFlClsQiupzOcdGOSL35","secretKey": "Is1T4v0dAT9MLmRi0aWuSG6XfCN7rflPUoFFT0YB" },"tenantId": "e180eae4-ed44-11e5-9cc8-005056992152"}}'
request = requests.post("https://api2.numergy.com/%s/tokens"%version, data=body)
data = request.json()
token = (data['access']['token']['id'])

request = requests.get(("https://api2.numergy.com/%s/e180eae4-ed44-11e5-9cc8-005056992152/images"%version),headers={"X-Auth-Token" : "%s"%token})
data = request.json()
#print (data['images'][1])
for i in (data['images']):
    if image in i:
        print (i['name'],i['id'])
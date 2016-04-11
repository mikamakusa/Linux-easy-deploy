import requests

def GetVersion():
    _method = "GET"
    _url = "https://api2.numergy.com/"
    h = {"ContentType": "application/json"}
    request = requests.get(_url,headers=h)
    data = request.json()
    print (data)
    print (data['versions'][4]['id'])
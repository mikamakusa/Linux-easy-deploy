import requests

class Numergy():

    def __init__(self):
     self.version = (request.get("https://api2.numergy.com/")).json()
import boto
from boto import ec2
from boto.ec2 import image
from boto.ec2 import regions
from boto.ec2 import EC2Connection
import requests
import datetime

now = datetime.datetime.now()

def Numergy(AccessKey,SecretKey,TenantId,Image,Flavor,ServerName,ServerId,**action):
    if action.get("Insert"):
        ## Get Version
        request = requests.get("https://api2.numergy.com/")
        data = request.json()
        for i in (data['versions']['version']):
            if "CURRENT" in i['status']:
                version = i['id']
        ## Get Token
        _body = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "%s","secretKey": "%s" },"tenantId": "%s"}}'%(AccessKey,SecretKey,TenantId)
        request = requests.post("https://api2.numergy.com/%s/tokens" % version, data=_body)
        data = request.json()
        token = (data['access']['token']['id'])
        ## Get ImageId
        request = requests.get("https://api2.numergy.com/%s/%s/images" % (version,TenantId), headers={"X-Auth-Token" : "%s" % token})
        data = request.json()
        for i in (data['images']):
            if Image in i['name']:
                ImageId = i['id']
        ## Get FlavorId
        request = requests.get("https://api2.numergy.com/%s/%s/images" % (version,TenantId), headers={"X-Auth-Token" : "%s" % token})
        data = request.json()
        for i in (data["flavors"]):
            if Flavor in i["name"]:
                FlavorId = i['id']
        ## Server Creation
        _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}'%(FlavorId,ImageId,ServerName)
        requests.post("https://api2.numergy.com/%s/%s/servers" % (version,TenantId), headers={"X-Auth-Token" : "%s" % token}, data=_body)
    elif action.get("Reboot"):
        _body = '{"reboot": {"type": "SOFT"}}'
        requests.post("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s/reboot"%(version,TenantId,ServerId),data=_body,headers={"X-Auth-Token" : "%s"%(token)})
    elif action.get("Remove"):
        requests.delete("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s" %(version,TenantId,ServerId), headers={"X-Auth-Token" : "%s" %token})
    elif action.get("Rebuild"):
        _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}'%(FlavorId,ImageId,ServerName)
        requests.post("https://api2.numergy.com/%s/%s/servers" %(version,TenantId),headers={"X-Auth-Token": "%s"%(token)},data=_body)

def Cloudwatt(Username,Password,TenantId,Image,Flavor,ServerName,Number,ServPass,**action):
    ##Get version
    request = requests.get("https://compute.fr1.cloudwatt.com/")
    data = request.json()
    version = data['versions']['id']
    ## Get Token
    _body = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='%s'><passwordCredentials username='%s' password='%s'/></auth>",%(TenantId,Username,Password)
    request = requests.post("https://identity.fr1.cloudwatt.com/%s/tokens"%(version),data=_body)
    data = request.json()
    token = data['access']['token']['id']
    ## Get ImageId
    request = requests.get("https://compute.fr1.cloudwatt.com/%s/%s/images"%(version,token),headers={"X-Auth-Token" : "%s"%(token)})
    data = request.json()
    for i in (data['images']):
        if Image in i['name']:
            ImageId = i['id']
    ## Get FlavorId
    request = requests.get("https://compute.fr1.cloudwatt.com/%s/%s/flavors"%(version,token),headers={"X-Auth-Token" : "%s"%(token)})
    data = request.json()
    for i in (data['flavors']):
        if Flavor in i['name']:
            FlavorId = i['id']
    ## Get Security Group
    _body = '{"security_group":{"name":"Security","description":"SecGroup"}}'
    request = requests.post("https://network.fr1.cloudwatt.com/%s/security-groups"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
    data = request.json()
    SecGroup = data['security_group']['name']
    ## Get Network Id
    _body = '{"network":{"name": "network1", "admin_state_up": true}}'
    request = requests.post("https://network.fr1.cloudwatt.com/%s/security-groups"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
    data = request.json
    NetId = data['network']['id']
    _body = '{"subnet":{"network_id":"$s","ip_version":4,"cidr":"192.168.0.0/24"}}'%(NetId)
    request = requests.post("https://network.fr1.cloudwatt.com/%s/security-groups"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
    ## SSHKey & instance creation
    if Image not in "Win":
        _body = '{"keypair":{"name":"cle"}}'
        request = requests.post("https://network.fr1.cloudwatt.com/%s/%s/os-keypairs"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
        data = request.json()
        Key = data['keypair']
        _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"22","ethertype":"IPv4","port_range_max":"22","protocol":"tcp","security_group_id":"%s"}}'%(SecGroup)
        requests.post("https://network.fr1.cloudwatt.com/%s/security-group-rules"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
        _body = '{"server":{"name":"%s","key_name":"cle","imageRef":"%s","flavorRef":"%s","max_count":%s,"min_count":1,"networks":[{"uuid":"%s"}],"metadata": {"admin_pass": "%s"},"security_groups":[{"name":"default"},{"name":"%s"}]}}'%(ServerName,ImageId,FlavorId,Number,NetId,ServPass)
        request = requests.post("https://compute.fr1.cloudwatt.com/%s/%s/servers"%(version,TenantId),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
        data = request.json()
        ServerId = data['server']['id']
    else:
        _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"3389","ethertype":"IPv4","port_range_max":"3389","protocol":"tcp","security_group_id":"%s"}}'%(SecGroup)
        request = requests.post("https://compute.fr1.cloudwatt.com/%s/%s/servers"%(version,TenantId),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
        data = request.json()
        ServerId = data['server']['id']
    ## Public Network Interface Id
    request = requests.get("https://network.fr1.cloudwatt.com/%s/networks"%(version),headers={"X-Auth-Token" : "%s"%(token)})
    data = request.json
    for i in data['networks']:
        if "public" in i['name']:
            NetId = i['id']
    ## Floatting IP
    _body = '{"floatingip":{"floating_network_id":"%s"}}'%(NetId)
    request = requests.post("https://network.fr1.cloudwatt.com/%s/floatingips"%(version),headers={"X-Auth-Token" : "%s"%(token)},data=_body)
    data = request.json()
    IP = data['floatinip']['floating_ip_address']
    ## Commit IP to Server
    _body = '{"addFloatingIp":{"address":"%s"}}'%(IP)
    request = requests.post("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s/action"%(version,TenantId,ServerId),headers={"X-Auth-Token" : "%s"%(token)},data=_body)

def Rackspace(username,apikey,TenantId,Image,Flavor,ServerName,**action):
    ## Get version
    request = requests.get("https://compute.fr1.cloudwatt.com/")
    data = request.json()
    for i in (data['version']['version']):
        if "2" in i['id']:
            version = i['id']
    ## Get Token
    _body = '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"%s","apiKey":"%s"}}}'%(username,apikey)
    request = request.post("https://identity.api.rackspacecloud.com/%s/tokens" %version,data=_body)
    data = request.json()
    Token = data['access']['token']['id']
    ## Get Image Id
    request = requests.get("https://lon.servers.api.rackspacecloud.com/v2/%s/images"%(tenantId),headers={"Authorization" : "Bearer %s"%(Token)})
    data = request.json()
    for i in (data['images']):
        if Image in i['name']:
            ImageId = i['id']
    ## Get FlavorId
    request = requests.get("https://lon.servers.api.rackspacecloud.com/v2/%s/flavors"%(token),headers={"Authorization" : "Bearer %s"%(Token)})
    data = request.json()
    for i in (data['flavors']):
        if Flavor in i['name']:
            FlavorId = i['id']
    ## Server Creation
    _body = '{"server": {"name": "%s","imageRef": "%s","flavorRef": "%s"}}'%(ServerName,ImageId,FlavorId)
    requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers"%(TenantId),headers={"Authorization" : "Bearer %s"%(Token)},data=_body)

def DigitalOcean(Token,Image,Region,Size,ServerName,**action):
    ## Get ImageId
    request = requests.get("https://api.digitalocean.com/v2/images",headers={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['images']:
        if Image in i['slug']:
            ImageId = i['id']
    ## Get SizeId
    request = requests.get("https://api.digitalocean.com/v2/sizes",headers={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['sizes']:
        if Size in i['slug'] and "True" in i['available']:
            SizeId = i['slug']
    ## Get Region
    request = requests.get("https://api.digitalocean.com/v2/regions",headers={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['regions']:
        if Region in i['slug'] and "True" in i['available']:
            RegionId = i['slug']
    ## Server Creation
    _body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'%(ServerName,RegionId,SizeId,ImageId)
    requests.post("https://api.digitalocean.com/v2/droplets",headers={"Authorization" : "Bearer %s"}%(Token),data=_body)

def Google(Image,Project,Token,Region,Size,**action):
    ## Get ImageId
    request = requests.get("https://www.googleapis.com/compute/v1/projects/%s/%s-cloud/global/images"%(Project,Image),header={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['items']:
        if Image in data['selfLink']:
            ImageId = data['selfLink'][-1]
    ## Get RegionId
    request = requests.get("https://www.googleapis.com/compute/v1/projects/%s/regions"%(Project),header={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['items']:
        if Region in data['items']:
            RegionId = data['selfLink']
    ## Get SizeId
    request = requests.get("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/machineType"%(Project,RegionId),header={"Authorization" : "Bearer %s"}%(Token))
    data = request.json()
    for i in data['items']:
        if Size in data['items']:
            SizeId = data['selfLink']
    ## Server Creation
    _body = '{"name": "%s","machineType": "%s","networkInterfaces": [{"accessConfigs": [{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],"network": "global/networks/default"}],"disks": [{"autoDelete": "true","boot": "true","type": "PERSISTENT","initializeParams": {"sourceImage": "%s"}}]}'%(ServerName,SizeId,ImageId)
    requests.post("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances"%(Project,RegionId),header={"Authorization" : "Bearer %s"}%(Token),data=_body)

def Amazon(AccessKey,SecretKey,Region,Image,Number,**action):
    date_now = now.strftime
    date_owa = datetime.now - timedelta(days=1)
    ## Get Regions
    AWS_region_list = regions(aws_access_key_id=AccessKey, aws_secret_access_key=SecretKey)
    for i in AWS_region_list:
        if Region in i.name:
            RegionId = i.name
    AWS_connection = ec2.connect_to_region(RegionId)
    ## Get ImageId
    AWS_Image = AWS_connection.get_all_images(filter={'virtualization_type':'hvm','state':'available'})
    if "windows server" in Image:
        for i in AWS_Image:
            if "2003" in Image and 'Windows_Server-2003-R2_SP2-English-64Bit-Base-' in i.image_location:
                ImageId = i.id
            elif "2008" in Image and 'Windows_Server-2008-R2_SP1-English-64Bit-Base-' in i.image_location:
                ImageId = i.id
            elif "2012" in Image and 'Windows_Server-2012-R2_RTM-English-64Bit-Base-' in i.image_location:
                ImageId = i.id
    elif "ubuntu" in Image:
        for i in AWS_Image:
            if "ubuntu-eu-central-1/images/hvm-instance/" in i.image_location:
                ImageId = i.id
    elif "centos" in Image:
        for i in AWS_Image:
            if "CentOS Atomic Host 7" in i.name:
                ImageId = i.id
    elif "debian" in Image:
        for i in AWS_Image:
            if "debian-jessie" in i.name:
                ImageId = i.id
    elif "fedora" in Image:
        for i in AWS_Image:
            if "125523088429/Fedora-Cloud-Base-23-%s"%(date_owa) in i.image_location and "standard" in i.name:
                ImageId = i.id
    elif "gentoo" in Image:
            ImageId = "ami-4c7d9a23"
    ## Instances creation
    EC2Connection.run_instances(ImageId,min_count=1,max_count=Number,instance_type='m1.small')
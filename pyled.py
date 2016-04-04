import csv
import paramiko
import os
import json
import boto.ec2
import doto
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

def PacMan(package, action):
    if "Install" in action:
        com = os.popen("ls /etc/")
        com.read()
        if "redhat*" in com: os.popen("yum install -y %s" % package)
        elif "arch*" in com: os.popen("pacman -S %s"%package)
        elif "gentoo*" in com: os.popen("emerge %s"%package)
        elif "Suse*" in com: os.popen("zypper install -y %s"%package)
        elif "debian*" in com: os.popen("apt-get install -y %s"%package)
        elif "slackware*" in com: os.popen("slackpkg install -y %s"%package)
        elif "sabayon*" in com: os.popen( "equo install -y %s"%package)
        elif "alpine*" in com: os.popen("apk add -y %s"%package)
        elif "sourcemage*" in com: os.popen("cast -y %s"%package)

def APICom(url, header1, header2, method, body):
    os.popen("curl -X %s -H %s -H %s -d %s %s" % method % header1 % header2 % body % url)

def GetImageId(Image):
    if "Amazon" in row[1]:
        if "Amazon" in row[3]: return "ami-d22932be"
        elif "Red Hat" in row[3]: return "ami-875042eb"
        elif "Suse" in row[3]: return "ami-875042eb"
        elif "Ubuntu" in row[3]: return "ami-87564feb"
        elif "Windows 2012" in row[3]: return "ami-1135d17e"
        elif "Windows 2008" in row[3]: return "ami-e135d18e"
    elif "DigitalOcean" in row[1]:
        if "Debian" in row[3]: return "15611095"
        elif "Ubuntu" in row[3]: return "15621816"
        elif "CentOS" in row[3]: return "16040476"
        elif "Fedora"in row[3]: return "14238961"
        elif "FreeBSD" in row[3]: return "13321858"
    elif "Cloudwatt" in row[1]:
        if "Ubuntu" in row[3]: return "edffd57d-82bf-4ffe-b9e8-af22563741bf"
        elif "Suse" in row[3]: return "e194b52d-cf80-4b05-9be3-56a2f3ba10ff"
        elif "CentOS" in row[3]: return "86e61ee3-078f-405d-8eab-210174d20159"
        elif "Fedora" in row[3]: return "f77e7c4b-3ba6-4f1d-b1eb-69d20d5beee6"
        elif "Windows 2012" in row[3]: return "ed01abf8-e6a8-4dcf-b9bb-d2dd0aefd503"
        elif "Windows 2008" in row[3]: return "3d014779-fa19-49c8-8310-6c9a163ed934"
    elif "Numergy" in row[1]:
        if "Ubuntu" in row[3]: return "41221dc8-29e3-11e4-857f-005056992152"
        elif "Debian" in row[3]: return "de8ff4bc-038c-11e5-bbd3-005056992152"
        elif "CentOS" in row[3]: return "aadf1726-a838-11e2-816d-005056992152"
        elif "Red Hat" in row[3]: return "aa56ee50-a838-11e2-816d-005056992152"
        elif "Windows 2008" in row[3]: return "902771bc-47bf-11e4-857f-005056992152"
        elif "Windows 2012" in row[3]: return "59bc519c-5846-11e3-8d40-005056992152"
    elif "Google" in row[1]:
        if "Debian" in row[3]: return "projects/debian-cloud/global/images/debian-8-jessie-v20160301"
        elif "CentOS" in row[3]: return "projects/centos-cloud/global/images/centos-7-v2016030"
        elif "Suse" in row[3]: return "projects/suse-cloud/global/images/opensuse-13-2-v20160222"
        elif "Ubuntu" in row[3]: return "projects/ubuntu-os-cloud/global/images/ubuntu-1510-wily-v20160315"
        elif "Windows 2008" in row[3]: return "projects/windows-cloud/global/images/windows-server-2008-r2-dc-v20160224"
        elif "Windows 2012" in row[3]: return "projects/windows-cloud/global/images/windows-server-2012-r2-dc-v20160224"
    elif "Rackspace" in row[1]:
        if "Debian" in row[3]: return "a10eacf7-ac15-4225-b533-5744f1fe47c1"
        elif "CentOS" in row[3]: return "c195ef3b-9195-4474-b6f7-16e5bd86acd0"
        elif "Suse" in row[3]: return "096c55e5-39f3-48cf-a413-68d9377a3ab6"
        elif "Ubuntu" in row[3]: return "5cebb13a-f783-4f8c-8058-c4182c724ccd"
        elif "Windows 2008" in row[3]: return "b9ea8426-8f43-4224-a182-7cdb2bb897c8"

def GetSize(Size):
    if "DigitalOcean" in row[1]:
        if "small" in row[5]: return "512mb"
        elif "medium" in row[5]: return "1gb"
        elif "large" in row[5]: return "2gb"
        elif "xl"in row[5]: return "4gb"
        elif "xxl" in row[5]: return "8bg"
    elif "Cloudwatt" in row[1]:
        if "small" in row[5]: return "21"
        elif "medium" in row[5]: return "22"
        elif "large" in row[5]: return "23"
        elif "xl" in row[5]: return "24"
        elif "xxl" in row[5]: return "30"
    elif "Numergy" in row[1]:
        if "small" in row[5]: return "bbe1760a-30ef-11e3-8d40-005056992152"
        elif "medium" in row[5]: return "01c25006-a5c0-11e2-816d-005056992152"
        elif "large" in row[5]: return "01c250a6-a5c0-11e2-816d-005056992152"
        elif "xl" in row[5]: return "01c24ca0-a5c0-11e2-816d-005056992152"
        elif "xxl" in row[5]: return "01c24f52-a5c0-11e2-816d-005056992152"
    elif "Google" in row[1]:
        project = row[7]
        if "Asia" in row[4]: return "https://content.googleapis.com/compute/v1/projects/%s/zones/asia-east1-a/machineTypes/f1-micro" %project
        elif "Europe" in row[4]: return "https://content.googleapis.com/compute/v1/projects/%s/zones/europe-west1-b/machineTypes/f1-micro" %project
        elif "US" in row[4]: return "https://content.googleapis.com/compute/v1/projects/%s/zones/us-central1-a/machineTypes/f1-micro" %project
    elif "Rackspace" in row[1]:
        if "small" in row[5]: return "3"
        elif "medium" in row[5]: return "4"
        elif "large" in row[5]: return "5"
        elif "xl" in row[5]: return "6"
        elif "xxl" in row[5]: return "7"
    elif "Amazon" in row[1]:
        if "small" in row[5]: return "t1.micro"
        elif "medium" in row[5]: return "m1.small"
        elif "large" in row[5]: return "m1.medium"
        elif "xl" in row[5]: return "m1.large"
        elif "xxl" in row[5]: return "m1.xlarge"

def GetRegions(Region):
    if "DigitalOcean" in row[1]:
        if "New York" in row[5]: return "nyc1"
        elif "Amsterdam" in row[5]: return "ams2"
        elif "San Francisco" in row[5]: return "sfo1"
        elif "Singapour"in row[5]: return "sgp1"
        elif "London" in row[5]: return "lon1"
    elif "Google" in row[1]:
        if "Asia" in row[5]: return "asia-east1-a"
        elif "Europe" in row[5]: return "europe-west1-b"
        elif "US" in row[5]: return "us-central1-a"
    elif "Amazon" in row[1]:
        if "Europe" in row[5]: return "eu-west-1"
        elif "US" in row[5]: return "us-east-1"
        elif "Asia" in row[5]: return "ap-northeast-1"
        elif "South America" in row[5]: return "sa-east-1"

def runSSHcmd(hostname,username,password,port):
    client = paramiko.SSHClient()
    client.connect(hostname,port=port,username=username,password=password)

def create_instance(compute, project, zone, name, image):
    source_disk_image = image
    machine_type = zone

    config = {
        'name': name,
        'machineType': machine_type,

        # Specify the boot disk and the image to use as a source.
        'disks': [
            {
                'boot': True,
                'autoDelete': True,
                'initializeParams': {
                    'sourceImage': source_disk_image,
                }
            }
        ],

        # Specify a network interface with NAT to access the public
        # internet.
        'networkInterfaces': [{
            'network': 'global/networks/default',
            'accessConfigs': [
                {'type': 'ONE_TO_ONE_NAT', 'name': 'External NAT'}
            ]
        }],

        # Allow the instance to access cloud storage and logging.
        'serviceAccounts': [{
            'email': 'default',
            'scopes': [
                'https://www.googleapis.com/auth/devstorage.read_write',
                'https://www.googleapis.com/auth/logging.write'
            ]
        }],
    }

    return compute.instances().insert(
        project=project,
        zone=zone,
        body=config).execute()

file = input ("fichier d'inventaire :")

f = csv.reader(open(file), delimiter=";")
next(f)
for row in f:
    if "Host" in row[0]:
        hostip = row[1]
        login = row[2]
        passw = row[3]
        sshport = row[4]
        for i in row[1]:
            runSSHcmd(i,login,passw,sshport)
            for p in row[5]:
                action = row[6]
                PacMan(p,action)

    else:
        if "Amazon" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
            RegionSet = GetRegions(Region)
            SizeSet = GetSize(Size)
            ImageSet = GetImageId(Image)
            conn = boto.ec2.connect_to_region("%s"%RegionSet)
            key = boto.ec2.create_key_pair('%s'%Token)
            conn.run_instances('%s'%ImageSet,key_name='%s'%key,instance_type='%s'%SizeSet,security_groups=['%s'%key])
        elif "DigitalOcean" in row[1]:
            Token = row[2]
            clientid = row[3]
            Image = row[4]
            Region = row[5]
            Size = row[6]
            VMName = row[7]
            ImageSet = int(GetImageId(Image))
            SizeSet = int(GetSize(Size))
            RegionSet = int(GetRegions(Region))
            os.system("echo [Credentials] > ~/.doto/.dotorc && echo client_id = %s >> ~/.doto/.dotorc && echo api_key = %s >> ~/.doto/.dotorc"%clientid %Token)
            do = doto.connect_d0
            do.create_droplet(name=VMName,size_id=SizeSet,image_id=ImageSet,region_id=RegionSet)
        elif "Cloudwatt" in row[1]:
            Token = row[2]
            Image = row[3]
            Size = row[4]
            VMName = row[5]
            Tenant = row[6]
            ImageSet = GetImageId(Image)
            SizeSet = GetSize(Size)
            InsCreate = ('<?xml version="1.0" encoding="UTF-8"?><server xmlns="http://docs.openstack.org/compute/api/v1.1" imageRef="%s" flavorRef="%s" name="%s"></server>'%ImageSet %SizeSet %VMName)
            APICom(url="https://compute.fr1.cloudwatt.com/v2/%s/servers"%Tenant, method="POST",header1="Content-Type: application/json",header2="X-Auth-Token: %s"%Token,body=InsCreate)
        elif "Numergy" in row[1]:
            Token = row[2]
            Image = row[3]
            Size = row[4]
            VMName = row[5]
            Tenant = row[6]
            data = os.system("curl -X GET -H 'application/json; charset=utf-8' https://api2.numergy.com/")
            version = json.loads(data.read())
            Nversion = version["versions"]["id"]
            ImageSet = GetImageId(Image)
            SizeSet = GetSize(Size)
            APICom(url="https://api2.numergy.com/%s/%s/servers"%Nversion %Tenant,method="POST",header1="ContentType: application/json; charset=utf-8",header2="X-Auth-Token: %s"%Token,body='{"server": {"flavorRef": "%s","imageRef": "%s","name": "%s"}}'%SizeSet %ImageSet %VMName)
        elif "Google" in row[1]:
            Image = row[2]
            Region = row[3]
            Size = row[4]
            VMName = row[5]
            Project = row[6]
            credentials = GoogleCredentials.get_application_default()
            compute = discovery.build('compute','V1',credentials=credentials)
            create_instance(compute=compute,project=Project,zone=Region,name=VMName,image=Image)
        elif "Rackspace" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
            Tenant = row[7]
            ImageSet = GetImageId(Image)
            SizeSet = GetSize(Size)
            Body = '{"server": {"name": "%s","imageRef": "%s", "flavorRef": "%s"}}'%VMName %ImageSet %SizeSet
            APICom(url="https://servers.api.rackspacecloud.com/v1.0/010101/v2/%s/servers"%Tenant,method="POST",header1="ContentType: application/json",header2="X-Auth-Token: %s"%Token,body=Body)
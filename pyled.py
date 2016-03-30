import csv
import spur
import os

def PacMan(package):
    packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk add","emerge","lin","cast","niv-env","xpbs","snappy"
    for i in packman:
        shell = spur.LocalShell()
        if ((shell.run([i])).output) in i:
            if i in "apt-get": shell.run([i, "install", "-y", package])
            elif i in "yum" : shell.run([i, "install", "-y", package])
            elif i in "zypper" : shell.run([i, "install", "-y", package])
            elif i in "slackpkg" : shell.run([i, "install", "-y", package])
            elif i in "equo" : shell.run([i, "install", "-y", package])
            elif i in "snappy" : shell.run([i, "install", "-y", package])
            elif i in "slapt-get" : shell.run([i, "--install", "-y", package])
            elif i in "pacman" : shell.run([i, "-S", package])
            elif i in "conary" : shell.run([i, "update", "-y", package])
            elif i in "apk" : shell.run([i, "add", "-y", package])
            elif i in "nix-env" : shell.run([i, "-i", "-y", package])
            elif i in "xpbs" : shell.run([i, "-install", "-y", package])
            else: shell.run([i, package])

def APICom(url, header1, header2, method, body):
    os.system("curl -X %s -H %s -H %s -d %s %s", % method, header1, header2, body, url)

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
            shell = spur.SshShell(
                Hostname = hostip,
                username = login,
                password = passw,
                port = sshport
            )
            package = row[5]
            PacMan (package)

    else:
        if "Amazon" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
        elif "DigitalOcean" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
            ImageSet = GetImageId(Image)
            SizeSet = GetSize(Size)
            RegionSet = GetRegions(Region)
            APICom(url="https://api.digitalocean.com/v2/droplets",method="POST",header1="Content-Type: application/json",header2="Authorization: Bearer %s"%Token,body='{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'%VMName %ImageSet %RegionSet %SizeSet)
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
        elif "Google" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
            Project = row[7]
        elif "Rackspace" in row[1]:
            Token = row[2]
            Image = row[3]
            Region = row[4]
            Size = row[5]
            VMName = row[6]
            Project = row[7]
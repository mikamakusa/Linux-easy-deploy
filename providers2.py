import boto
import requests


class Provider(object):
    @classmethod
    def Numergy(cls, AccessKey, SecretKey, TenantId, Image, OsVer, OsRole, Flavor, ServerName, ServerId, action):
        request = requests.get("https://api2.numergy.com/")
        data = request.json()
        for i in (data['versions']['version']):
            if "CURRENT" in i['status']:
                _version = i['id']
        global _version
        body = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "%s","secretKey": "%s" },"tenantId": "%s"}}' % (
            AccessKey, SecretKey, TenantId)
        request = requests.post("https://api2.numergy.com/%s/tokens" % _version, data=body)
        data = request.json()
        _token = (data['access']['token']['id'])
        global _token
        request = requests.get("https://api2.numergy.com/%s/%s/images" % (_version, TenantId),
                               headers={"X-Auth-Token": "%s" % _token})
        data = request.json()
        if Image.get("Windows") and OsVer.get("2008"):
            if OsRole.get("IIS"):
                ImgKey = "Win2008 R2 IIS"
            elif OsRole.get("MSSQL"):
                ImgKey = "Win2008 R2 MSSQL ENT"
            else:
                ImgKey = "Win2008 R2 STD 64"
        elif Image.get("Windows") and OsVer.get("2012"):
            if OsRole.get("SQL"):
                ImgKey = "Win2012 R2 STD SQL 2014 STD"
            else:
                ImgKey = "Win2012 R2 STD"
        elif Image.get("CentOS") and OsVer.get("6"):
            if OsRole.get("mysql"):
                ImgKey = "Cen6 mysql"
            else:
                ImgKey = "Cen6"
        elif Image.get("RedHat") and OsVer.get("5"):
            if OsRole.get("mysql"):
                ImgKey = "Red5 mysql"
            elif OsRole.get("lamp"):
                ImgKey = "Red5 LAMP"
            else:
                ImgKey = "Red5"
        elif Image.get("RedHat") and OsVer.get("6"):
            if OsRole.get("mysql"):
                ImgKey = "Red6_mysql"
            elif OsRole.get("lamp"):
                ImgKey = "Red6 LAMP"
            else:
                ImgKey = "Red6_64"
        elif Image.get("Ubuntu") and OsVer.get("12"):
            if OsRole.get("mysql"):
                ImgKey = "ubu12 mysql"
            elif OsRole.get("lamp"):
                ImgKey = "ubu12 LAMP"
            else:
                ImgKey = "ubu12"
        elif Image.get("Ubuntu") and OsVer.get("14"):
            if OsRole.get("mysql"):
                ImgKey = "ubu14 mysql"
            elif OsRole.get("lamp"):
                ImgKey = "ubu14 LAMP"
            else:
                ImgKey = "ubu14"
        elif Image.get("Debian") and OsVer.get("7"):
            ImgKey = "Deb7"
        elif Image.get("Debian") and OsVer.get("8"):
            ImgKey = "Deb8"
        else:
            return "error"
        for i in (data['images']):
            if ImgKey in i['name']:
                ImageId = i['id']
                global ImageId
        request = requests.get("https://api2.numergy.com/%s/%s/images" % (_version, TenantId),
                               headers={"X-Auth-Token": "%s" % _token})
        data = request.json()
        for i in (data["flavors"]):
            if Flavor in i["name"]:
                FlavorId = i['id']
                global FlavorId
        if action.get("Insert"):
            _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                FlavorId, ImageId, ServerName)
            requests.post("https://api2.numergy.com/%s/%s/servers" % (_version, TenantId),
                          headers={"X-Auth-Token": "%s" % _token}, data=_body)
        elif action.get("Reboot"):
            _body = '{"reboot": {"type": "SOFT"}}'
            requests.post("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s/reboot" % (_version, TenantId, ServerId),
                          data=_body, headers={"X-Auth-Token": "%s" % _token})
        elif action.get("Remove"):
            requests.delete("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s" % (_version, TenantId, ServerId),
                            headers={"X-Auth-Token": "%s" % _token})
        elif action.get("Rebuild"):
            _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                FlavorId, ImageId, ServerName)
            requests.post("https://api2.numergy.com/%s/%s/servers/%s" % (_version, TenantId, ServerId),
                          headers={"X-Auth-Token": "%s" % _token}, data=_body)
        else:
            return 'error'

    @classmethod
    def Cloudwatt(cls, Username, Password, TenantId, Image, Flavor, ServerId, ServerName, Number, ServPass, action):
        _body = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='%s'><passwordCredentials username='%s' password='%s'/></auth>" % (
            TenantId, Username, Password)
        request = requests.post("https://identity.fr1.cloudwatt.com/v2/tokens", data=_body)
        data = request.json()
        token = data['access']['token']['id']
        global token

        request = requests.get("https://compute.fr1.cloudwatt.com/v2/%s/images" % TenantId,
                               headers={"X-Auth-Token": "%s" % (token)})
        data = request.json()
        for i in (data['images']):
            if Image in i['name']:
                ImageId = i['id']
                global ImageId

        request = requests.get("https://compute.fr1.cloudwatt.com/v2/%s/flavors" % TenantId,
                               headers={"X-Auth-Token": "%s" % (token)})
        data = request.json()
        for i in (data['flavors']):
            if Flavor in i['name']:
                FlavorId = i['id']
                global FlavorId

        if action.get("insert"):
            ## Get Security Group
            _body = '{"security_group":{"name":"Security","description":"SecGroup"}}'
            request = requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                                    headers={"X-Auth-Token": "%s" % (token)}, data=_body)
            data = request.json()
            SecGroup = data['security_group']['name']
            ## Get Network Id
            _body = '{"network":{"name": "network1", "admin_state_up": true}}'
            request = requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                                    headers={"X-Auth-Token": "%s" % (token)}, data=_body)
            data = request.json
            NetId = data['network']['id']
            _body = '{"subnet":{"network_id":"%s","ip_version":4,"cidr":"192.168.0.0/24"}}' % (NetId)
            requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                          headers={"X-Auth-Token": "%s" % (token)}, data=_body)
            global NetId, SecGroup
            ## SSHKey & instance creation
            if ImageId not in "Win":
                _body = '{"keypair":{"name":"cle"}}'
                request = requests.post("https://network.fr1.cloudwatt.com/v2/%s/os-keypairs",
                                        headers={"X-Auth-Token": "%s" % (token)}, data=_body)
                data = request.json()
                Key = data['keypair']
                _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"22","ethertype":"IPv4","port_range_max":"22","protocol":"tcp","security_group_id":"%s"}}' % (
                    SecGroup)
                requests.post("https://network.fr1.cloudwatt.com/v2/security-group-rules",
                              headers={"X-Auth-Token": "%s" % (token)}, data=_body)
                _body = '{"server":{"name":"%s","key_name":"cle","imageRef":"%s","flavorRef":"%s","max_count":%s,"min_count":1,"networks":[{"uuid":"%s"}],"metadata": {"admin_pass": "%s"},"security_groups":[{"name":"default"},{"name":"%s"}]}}' % (
                    ServerName, ImageId, FlavorId, Number, NetId, ServPass, SecGroup)
                request = requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers" % TenantId,
                                        headers={"X-Auth-Token": "%s" % (token)}, data=_body)
                data = request.json()
                ServerId = data['server']['id']
            else:
                _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"3389","ethertype":"IPv4","port_range_max":"3389","protocol":"tcp","security_group_id":"%s"}}' % (
                    SecGroup)
                request = requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers" % TenantId,
                                        headers={"X-Auth-Token": "%s" % (token)}, data=_body)
                data = request.json()
                ServerId = data['server']['id']
            ## Public Network Interface Id
            request = requests.get("https://network.fr1.cloudwatt.com/v2/networks",
                                   headers={"X-Auth-Token": "%s" % (token)})
            data = request.json()
            for i in data['networks']:
                if "public" in i['name']:
                    NetId = i['id']
            ## Floatting IP
            _body = '{"floatingip":{"floating_network_id":"%s"}}' % (NetId)
            request = requests.post("https://network.fr1.cloudwatt.com/v2/floatingips",
                                    headers={"X-Auth-Token": "%s" % (token)}, data=_body)
            data = request.json()
            IP = data['floatinip']['floating_ip_address']
            ## Commit IP to Server
            _body = '{"addFloatingIp":{"address":"%s"}}' % (IP)
            requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/action" % (TenantId, ServerId),
                          headers={"X-Auth-Token": "%s" % (token)}, data=_body)
        elif action.get("Remove"):
            requests.delete("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s" % (TenantId, ServerId),
                            headers={"X-Auth-Token": "%s" % (token)})
        elif action.get("Reboot"):
            requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/reboot" % (TenantId, ServerId),
                          headers={"X-Auth-Token": "%s" % (token)})
        elif action.get("Rebuild"):
            request = requests.get("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/detail" % (TenantId, ServerId),
                                   headers={"X-Auth-Token": "%s" % (token)})
            data = request.json()
            for i in data['servers']:
                IP = i['addresses']['private']['addr']
                ImageId = i['image']['id']
                ServerName = i['name']
                global IP
            _body = '{"rebuild": {"imageRef": "%s","name": "%s","adminPass": "%s","accessIPv4": "%s"}}' % (
                ImageId, ServerName, ServPass, IP)
            requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/rebuild" % (TenantId, ServerId),
                          headers={"X-Auth-Token": "%s" % (token)}, data=_body)
        else:
            return ('error')

    @classmethod
    def Rackspace(cls, username, apikey, TenantId, Image, Flavor, ServerName, ServerId, action):
        request = requests.get("https://compute.fr1.cloudwatt.com/")
        data = request.json()
        for i in (data['version']['version']):
            if "2" in i['id']:
                version = i['id']
                global version

        _body = '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"%s","apiKey":"%s"}}}' % (username, apikey)
        request = requests.post("https://identity.api.rackspacecloud.com/%s/tokens" % version, data=_body)
        data = request.json()
        Token = data['access']['token']['id']
        global Token

        request = requests.get("https://lon.servers.api.rackspacecloud.com/v2/%s/images" % (TenantId),
                               headers={"Authorization": "Bearer %s" % (Token)})
        data = request.json()
        for i in (data['images']):
            if Image in i['name']:
                ImageId = i['id']
                global ImageId

        request = requests.get("https://lon.servers.api.rackspacecloud.com/v2/%s/flavors" % (TenantId),
                               headers={"Authorization": "Bearer %s" % (Token)})
        data = request.json()
        for i in (data['flavors']):
            if Flavor in i['name']:
                FlavorId = i['id']
                global FlavorId

        if action.get("insert"):  ## Server Creation
            _body = '{"server": {"name": "%s","imageRef": "%s","flavorRef": "%s"}}' % (ServerName, ImageId, FlavorId)
            requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers" % (TenantId),
                          headers={"Authorization": "Bearer %s" % (Token)}, data=_body)
        elif action.get("Remove"):
            requests.delete("https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s" % (TenantId, ServerId),
                            headers={"Authorization": "Bearer %s" % (Token)})
        elif action.get("Reboot"):
            _body = '{"reboot": {"type": "SOFT"}}'
            requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s/reboot" % (TenantId, ServerId),
                          data=_body, headers={"Authorization": "Bearer %s" % (Token)})
        elif action.get("Rebuild"):
            _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                FlavorId, ImageId, ServerName)
            requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s" % (TenantId, ServerId),
                          data=_body, headers={"Authorization": "Bearer %s" % (Token)})
        else:
            return ("error")

    @classmethod
    def DigitalOcean(cls, Token, Image, OsVer, Region, Size, ServerName, ServerId, action):
        def generate_RSA(bits=2048):
            '''
            Generate an RSA keypair with an exponent of 65537 in PEM format
            param: bits The key length in bits
            Return private key and public key
            '''
            from Crypto.PublicKey import RSA
            new_key = RSA.generate(bits, e=65537)
            public_key = new_key.publickey().exportKey("PEM")
            private_key = new_key.exportKey("PEM")
            return private_key, public_key

        Key = generate_RSA(bits=2048)

        _body = '{"name":"SSH key","public_key":"%s"}' % Key
        requests.post("https://api.digitalocean.com/v2/account/keys",
                      headers={"Authorization": "Bearer %s" % Token}, data=_body)
        data = requests.get("https://api.digitalocean.com/v2/account/keys",
                            headers={"Authorization": "Bearer %s" % Token})
        KeyId = data['ssh_keys']['id']
        global KeyId

        request = requests.get("https://api.digitalocean.com/v2/images",
                               headers={"Authorization": "Bearer %s" % Token})
        data = request.json()
        if Image.get("Ubuntu"):
            if OsVer.get("15.10"):
                Imgkey = "ubuntu-15-10-x64"
            elif OsVer.get("14.04"):
                Imgkey = "ubuntu-14-04-x64"
            else:
                Imgkey = "ubuntu-12-04-x64"
        if Image.get("FreeBSD"):
            if OsVer.get("10.1"):
                Imgkey = "freebsd-10-1-x64"
            else:
                Imgkey = "freebsd-10-2-x64"
        if Image.get("Fedora"):
            if OsVer.get("23"):
                Imgkey = "fedora-23-x64"
            else:
                Imgkey = "fedora-22-x64"
        if Image.get("Debian"):
            Imgkey = "debian-8-x64"
        if Image.get("CoreOs"):
            Imgkey = "coreos-beta"
        if Image.get("CentOS"):
            if OsVer.get("5"):
                Imgkey = "centos-5-8-x64"
            elif OsVer.get("6"):
                Imgkey = "centos-6-5-x64"
            else:
                Imgkey = "centos-7"
            global Imgkey
        for i in data['images']:
            if Imgkey in i['slug']:
                ImageId = i['id']
                global ImageId

        request = requests.get("https://api.digitalocean.com/v2/sizes",
                               headers={"Authorization": "Bearer %s"} % Token)
        data = request.json()
        for i in data['sizes']:
            if Size in i['slug'] and "True" in i['available']:
                SizeId = i['slug']
                global SizeId

        request = requests.get("https://api.digitalocean.com/v2/regions",
                               headers={"Authorization": "Bearer %s"} % Token)
        data = request.json()
        for i in data['regions']:
            if Region in i['slug'] and "True" in i['available']:
                RegionId = i['slug']
                global RegionId

        if action.get("insert"):
            _body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": null}' % (
                ServerName, RegionId, SizeId, ImageId, KeyId)
            requests.post("https://api.digitalocean.com/v2/droplets", headers={"Authorization": "Bearer %s"} % Token,
                          data=_body)
        elif action.get("Remove"):
            requests.delete("https://api.digitalocean.com/v2/droplets/%s" % ServerId,
                            headers={"Authorization": "Bearer %s"} % Token)
        elif action.get("Reboot"):
            _body = '{"type":"reboot"}'
            requests.post("https://api.digitalocean.com/v2/droplets/%s" % ServerId,
                          headers={"Authorization": "Bearer %s"} % Token, data=_body)
        elif action.get("Rebuild"):
            request = requests.get("https://api.digitalocean.com/v2/images",
                                   headers={"Authorization": "Bearer %s"} % Token)
            data = request.json()
            for i in data['images']:
                if Image in i['slug']:
                    ImageId = i['id']
            _body = '{"type":"rebuild","image":"%s"}' % ImageId
            requests.post("https://api.digitalocean.com/v2/droplets/%s/actions" % ServerId,
                          headers={"Authorization": "Bearer %s"} % Token, data=_body)
        else:
            return 'error'

    @classmethod
    def Google(cls, Image, Project, Token, Region, Size, ServerId, ServerName, action):

        request = requests.get(
            "https://www.googleapis.com/compute/v1/projects/%s/%s-cloud/global/images" % (Project, Image),
            header={"Authorization": "Bearer %s"} % Token)
        data = request.json()
        for i in data['items']:
            if Image in data['selfLink']:
                ImageId = data['selfLink'][-1]
                global ImageId

        request = requests.get("https://www.googleapis.com/compute/v1/projects/%s/regions" % (Project),
                               header={"Authorization": "Bearer %s"} % Token)
        data = request.json()
        for i in data['items']:
            if Region in data['items']:
                RegionId = data['selfLink']
                global RegionId

        request = requests.get(
            "https://www.googleapis.com/compute/v1/projects/%s/zones/%s/machineType" % (Project, RegionId),
            header={"Authorization": "Bearer %s"} % Token)
        data = request.json()
        for i in data['items']:
            if Size in data['items']:
                SizeId = data['selfLink']
                global SizeId

        if action.get("Insert"):
            _body = '{"name": "%s","machineType": "%s","networkInterfaces": [{"accessConfigs": [{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],"network": "global/networks/default"}],"disks": [{"autoDelete": "true","boot": "true","type": "PERSISTENT","initializeParams": {"sourceImage": "%s"}}]}' % (
                ServerName, SizeId, ImageId)
            requests.post("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances" % (Project, RegionId),
                          header={"Authorization": "Bearer %s"} % Token, data=_body)

        elif action.get("Remove"):
            requests.delete("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s" % (
                Project, RegionId, ServerId), header={"Authorization": "Bearer %s"} % Token)
        elif action.get("Reboot"):
            requests.post("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/reset" % (
                Project, RegionId, ServerId), header={"Authorization": "Bearer %s"} % Token)
        else:
            return "error"

    @classmethod
    def Amazon(cls, AccessKey, SecretKey, Region, Image, OsVer, OsRole, Number, ServerId, action):
        
        connect = boto.connect_ec2(aws_access_key_id=AccessKey, aws_secret_access_key=SecretKey)
        global connect

        global Imgkey
        if Image.get("Windows") and OsVer.get("2003"):
            if OsRole.get("SQL"):
                Imgkey = "Windows_Server-2003-R2_SP2-English-64Bit-SQL_2005_SP4_Express-2016.03"
            else:
                Imgkey = "Windows_Server-2003-R2_SP2-English-64Bit-Base-2016.03"
        if Image.get("Windows") and OsVer.get("2008"):
            if OsRole.get("SQL"):
                Imgkey = "Windows_Server-2008-R2_SP1-English-64Bit-SQL_2012_SP2_Express-2016.03"
            elif OsRole.get("Sharepoint"):
                Imgkey = "Windows_Server-2008-R2_SP1-English-64Bit-SharePoint_2010_SP2_Foundation-2016.03"
            else:
                Imgkey = "Windows_Server-2008-R2_SP1-English-64Bit-Base-2016.03"
        if Image.get("Windows") and OsVer.get("2012"):
            if OsRole.get("SQL"):
                Imgkey = "Windows_Server-2012-R2_RTM-English-64Bit-SQL_2014_SP1_Express-2016.03"
            else:
                Imgkey = "Windows_Server-2012-R2_RTM-English-64Bit-Base-2016.03"
        if Image.get("CentOS") and OsVer.get("7"):
            if OsRole.get("SQL"):
                Imgkey = "MariaDB-10.1.13-CentOS-7-x86_64"
            elif OsRole.get("docker"):
                Imgkey = "Centos71_docker18"
            else:
                Imgkey = "CentOS Atomic Host 7 x86_64 HVM EBS 1603_01"
        if Image.get("CentOS") and OsVer.get("6"):
            Imgkey = "RightImage_CentOS_6.6_x64"
        if Image.get("Debian") and OsVer.get("8"):
            if OsRole.get("SQL"):
                Imgkey = "MariaDB-10.1.13-Debian-8-Jessie-x86_64"
            else:
                Imgkey = "debian-jessie-amd64-hvm-2016-04"
        if Image.get("Gentoo"): 
            Imgkey = "gentoo-20160320"
        if Image.get("Ubuntu"):
            if OsRole.get("docker"):
                Imgkey = "3E-ubuntu-14.04-docker"
            elif OsRole.get("apache"):
                Imgkey = "usp-1.7.16-apache2.4-mp-server-ubuntu-14.04-amd64-paravirtual-2016"
            elif OsRole.get("SQL"):
                Imgkey = "MariaDB-10.0.24-Ubuntu-14.04-x86_64-0fb33ae5"
            else:
                Imgkey = "images/ubuntu-trusty-14.04-amd64-server-201604"
        AWS_Image = connect.get_all_images(filter={
            'virtualization_type': 'hvm',
            'state': 'available',
            'name': '%s'
        })[0] % Imgkey
        for i in AWS_Image:
            if Imgkey in i.name:
                ImageId = i.id
                global ImageId

        if action.get("insert"):
            connect.run_instances(ImageId, min_count=1, max_count=Number, instance_type='m1.small')
        elif action.get("Remove"):
            connect.terminate_instances(instance_ids=ServerId)
        elif action.get("Reboot"):
            connect.stop_instances(instance_ids=ServerId)
        else:
            return "error"
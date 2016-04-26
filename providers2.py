import boto
import requests
import ovh
import hashlib
from ArubaCloud.PyArubaAPI import CloudInterface
from ArubaCloud.objects import SmartVmCreator, ProVmCreator

URL_Numergy = "https://api2.numergy.com/"
URL_Cloudwatt = "https://compute.fr1.cloudwatt.com/v2/"
URL_Net_Cloudwatt = "https://network.fr1.cloudwatt.com/v2/"
URL_Google = "https://www.googleapis.com/compute/v1/projects/"
URL_Rackspace = "https://lon.servers.api.rackspacecloud.com/v2/"
URL_Digitalocean = "https://api.digitalocean.com/v2/"
URL_Ovh = "https://eu.api.ovh.com/1.0/"


class Provider(object):
    @classmethod
    class Server(object):
        @classmethod
        def numergy(cls, accesskey, secretkey, tenantid, image, app, flavor, servername, action, serverid=None):
            global ImageId, FlavorId, _version
            request = requests.get(URL_Numergy)
            data = request.json()
            for i in (data['versions']['version']):
                if "CURRENT" in i['status']:
                    _version = i['id']

            body = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "%s","secretKey": "%s" },"tenantId": "%s"}}' % (
                accesskey, secretkey, tenantid)
            request = requests.post(URL_Numergy+"%s/tokens" % _version, data=body)
            data = request.json()
            _token = (data['access']['token']['id'])

            if "Windows" in image:
                if app is None:
                    imgkey = ''.join((list(image.split()[0])[:3])) + image.split()[1] + " " + image.split()[2] + " " + \
                             image.split()[3] + " " + image.split()[4]
                else:
                    imgkey = ''.join((list(image.split()[0])[:3])) + image.split()[1] + " " + image.split()[
                        2] + " " + app
            else:
                if app is not None:
                    imgkey = ''.join((list(image.split()[0])[:3])) + image.split()[-1] + " " + app
                else:
                    imgkey = ''.join((list(image.split()[0])[:3])) + image.split()[-1]

            request = requests.get(URL_Numergy+"%s/%s/images" % (_version, tenantid),
                                               headers={"X-Auth-Token": "%s" % _token})
            data = request.json()
            for i in (data['images']):
                if imgkey in i['name']:
                    ImageId = i['id']

            request = requests.get(URL_Numergy+"%s/%s/flavors" % (_version, tenantid),
                                   headers={"X-Auth-Token": "%s" % _token})
            data = request.json()
            for i in (data["flavors"]):
                if flavor in i["name"]:
                    FlavorId = i['id']

            if action.get("Insert"):
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    FlavorId, ImageId, servername)
                requests.post(URL_Numergy+"%s/%s/servers" % (_version, tenantid),
                              headers={"X-Auth-Token": "%s" % _token}, data=_body)
            elif action.get("Reboot"):
                _body = '{"reboot": {"type": "SOFT"}}'
                requests.post(
                    URL_Numergy+"%s/%s/servers/%s/reboot" % (_version, tenantid, serverid),
                    data=_body, headers={"X-Auth-Token": "%s" % _token})
            elif action.get("Remove"):
                requests.delete("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s" % (_version, tenantid, serverid),
                                headers={"X-Auth-Token": "%s" % _token})
            elif action.get("Rebuild"):
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    FlavorId, ImageId, servername)
                requests.post(URL_Numergy+"%s/%s/servers/%s" % (_version, tenantid, serverid),
                              headers={"X-Auth-Token": "%s" % _token}, data=_body)
            else:
                return 'error'

        @classmethod
        def cloudwatt(cls, username, password, tenantid, image, flavor,
                      servername, number, servpass, action, serverid=None):
            global ImageId, IP, FlavorId
            _body = "<?xml version='1.0' encoding='UTF-8'?>" \
                    "<auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='%s'>" \
                    "<passwordCredentials username='%s' password='%s'/></auth>" % (tenantid, username, password)
            request = requests.post("https://identity.fr1.cloudwatt.com/v2/tokens", data=_body)
            data = request.json()
            token = data['access']['token']['id']

            request = requests.get(URL_Cloudwatt+"%s/images" % tenantid,
                                   headers={"X-Auth-Token": "%s" % token})
            data = request.json()
            for i in (data['images']):
                if image in i['name']:
                    ImageId = i['id']

            request = requests.get(URL_Cloudwatt+"%s/flavors" % tenantid,
                                   headers={"X-Auth-Token": "%s" % token})
            data = request.json()
            for i in (data['flavors']):
                if flavor in i['name']:
                    FlavorId = i['id']

            if action.get("insert"):
                # Get Security Group
                _body = '{"security_group":{"name":"Security","description":"SecGroup"}}'
                request = requests.post(URL_Net_Cloudwatt+"security-groups",
                                        headers={"X-Auth-Token": "%s" % token}, data=_body)
                data = request.json()
                secgroup = data['security_group']['name']
                # Get Network Id
                _body = '{"network":{"name": "network1", "admin_state_up": true}}'
                request = requests.post(URL_Net_Cloudwatt+"security-groups",
                                        headers={"X-Auth-Token": "%s" % token}, data=_body)
                data = request.json()
                netid = data['network']['id']
                _body = '{"subnet":{"network_id":"%s","ip_version":4,"cidr":"192.168.0.0/24"}}' % netid
                requests.post(URL_Net_Cloudwatt+"security-groups",
                              headers={"X-Auth-Token": "%s" % token}, data=_body)

                # SSHKey & instance creation
                if ImageId not in "Win":
                    _body = '{"keypair":{"name":"cle"}}'
                    request = requests.post(URL_Net_Cloudwatt+"%s/os-keypairs",
                                            headers={"X-Auth-Token": "%s" % token}, data=_body)
                    data = request.json()
                    key = data['keypair']
                    _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"22",' \
                            '"ethertype":"IPv4","port_range_max":"22","protocol":"tcp","security_group_id":"%s"}}' \
                            % secgroup
                    requests.post(URL_Net_Cloudwatt+"security-group-rules",
                                  headers={"X-Auth-Token": "%s" % token}, data=_body)
                    _body = '{"server":{"name":"%s","key_name":"%s","imageRef":"%s","flavorRef":"%s",' \
                            '"max_count":%s,"min_count":1,"networks":[{"uuid":"%s"}],' \
                            '"metadata": {"admin_pass": "%s"},"security_groups":[{"name":"default"},' \
                            '{"name":"%s"}]}}' % (servername, key, ImageId, FlavorId, number, netid, servpass, secgroup)
                    request = requests.post(URL_Cloudwatt+"%s/servers" % tenantid,
                                            headers={"X-Auth-Token": "%s" % token}, data=_body)
                    data = request.json()
                    serverid = data['server']['id']
                else:
                    _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"3389",' \
                            '"ethertype":"IPv4","port_range_max":"3389","protocol":"tcp",' \
                            '"security_group_id":"%s"}}' % secgroup
                    request = requests.post(URL_Cloudwatt+"%s/servers" % tenantid,
                                            headers={"X-Auth-Token": "%s" % token}, data=_body)
                    data = request.json()
                    serverid = data['server']['id']
                # Public Network Interface Id
                request = requests.get(URL_Net_Cloudwatt+"networks",
                                       headers={"X-Auth-Token": "%s" % token})
                data = request.json()
                for i in data['networks']:
                    if "public" in i['name']:
                        netid = i['id']
                # Floatting IP
                _body = '{"floatingip":{"floating_network_id":"%s"}}' % netid
                request = requests.post(URL_Net_Cloudwatt+"floatingips",
                                        headers={"X-Auth-Token": "%s" % token}, data=_body)
                data = request.json()
                IP = data['floatingip']['floating_ip_address']
                # Commit IP to Server
                _body = '{"addFloatingIp":{"address":"%s"}}' % IP
                requests.post(URL_Cloudwatt+"%s/servers/%s/action" % (tenantid, serverid),
                              headers={"X-Auth-Token": "%s" % token}, data=_body)
            elif action.get("Remove"):
                requests.delete(URL_Cloudwatt+"%s/servers/%s" % (tenantid, serverid),
                                headers={"X-Auth-Token": "%s" % token})
            elif action.get("Reboot"):
                requests.post(URL_Cloudwatt+"%s/servers/%s/reboot" % (tenantid, serverid),
                              headers={"X-Auth-Token": "%s" % token})
            elif action.get("Rebuild"):
                request = requests.get(
                    URL_Cloudwatt+"%s/servers/%s/detail" % (tenantid, serverid),
                    headers={"X-Auth-Token": "%s" % token})
                data = request.json()
                for i in data['servers']:
                    IP = i['addresses']['private']['addr']
                    ImageId = i['image']['id']
                    servername = i['name']

                _body = '{"rebuild": {"imageRef": "%s","name": "%s","adminPass": "%s","accessIPv4": "%s"}}' % (
                    ImageId, servername, servpass, IP)
                requests.post(URL_Cloudwatt+"%s/servers/%s/rebuild" % (tenantid, serverid),
                              headers={"X-Auth-Token": "%s" % token}, data=_body)
            else:
                return "error"

        @classmethod
        def rackspace(cls, username, apikey, tenantid, image, flavor, servername, action, serverid=None):
            global ImageId, FlavorId
            _body = '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"%s","apiKey":"%s"}}}' % (username, apikey)
            request = requests.post("https://identity.api.rackspacecloud.com/v2.0/tokens", data=_body)
            data = request.json()
            token = data['access']['token']['id']

            request = requests.get(URL_Rackspace+"%s/images" % tenantid,
                                   headers={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in (data['images']):
                if image in i['name']:
                    ImageId = i['id']

            request = requests.get(URL_Rackspace+"%s/flavors" % tenantid,
                                   headers={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in (data['flavors']):
                if flavor in i['name']:
                    FlavorId = i['id']

            if action.get("insert"):  # Server Creation
                _body = '{"server": {"name": "%s","imageRef": "%s","flavorRef": "%s"}}' % (
                    servername, ImageId, FlavorId)
                requests.post(URL_Rackspace+"%s/servers" % tenantid,
                              headers={"Authorization": "Bearer %s" % token}, data=_body)
            elif action.get("Remove"):
                requests.delete(URL_Rackspace+"%s/servers/%s" % (tenantid, serverid),
                                headers={"Authorization": "Bearer %s" % token})
            elif action.get("Reboot"):
                _body = '{"reboot": {"type": "SOFT"}}'
                requests.post(
                    URL_Rackspace+"%s/servers/%s/reboot" % (tenantid, serverid),
                    data=_body, headers={"Authorization": "Bearer %s" % token})
            elif action.get("Rebuild"):
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    FlavorId, ImageId, servername)
                requests.post(URL_Rackspace+"%s/servers/%s" % (tenantid, serverid),
                              data=_body, headers={"Authorization": "Bearer %s" % token})
            else:
                return "error"

        @classmethod
        def digitalocean(cls, token, distribution, application, region, size, servername,
                         action, number=None, serverid=None):
            global ImageId, SizeId, RegionId, key, imkey, _body

            def generate_rsa(bits=2048):

                """
                Generate an RSA keypair with an exponent of 65537 in PEM format
                param: bits The key length in bits
                Return private key and public key
                :param bits:
                """

                from Crypto.PublicKey import RSA
                new_key = RSA.generate(bits, e=65537)
                public_key = new_key.publickey().exportKey("PEM")
                private_key = new_key.exportKey("PEM")
                return private_key, public_key

            key = generate_rsa(bits=2048)

            _body = '{{"name":"SSH key","public_key":"{0:s}"}}'.format(key)
            requests.post(URL_Digitalocean+"account/keys",
                          headers={"Authorization": "Bearer %s" % token}, data=_body)
            data = requests.get(URL_Digitalocean+"account/keys",
                                headers={"Authorization": "Bearer %s" % token})

            keyid = data.json()['ssh_keys']['id']

            if distribution is not None:
                request = requests.get(URL_Digitalocean+"images",
                                       headers={"Authorization": "Bearer %s" % token})
                data = request.json()
                if distribution.split()[2] is not None:
                    imgkey = distribution.split()[0] + "-" + distribution.split()[1] + "-" + distribution.split()[2]
                elif distribution.split()[2] is None:
                    imgkey = distribution.split()[0] + "-" + distribution.split()[1] + "-"
                else:
                    imgkey = "coreos-beta"

                for i in data['images']:
                    if imgkey in i['slug']:
                        ImageId = i['id']

            elif application is not None:
                request = requests.get(URL_Digitalocean+"images",
                                       headers={"Authorization": "Bearer %s" % token})
                data = request.json()
                for i in data['application']:
                    if application in i:
                        ImageId = i['id']

            request = requests.get(URL_Digitalocean+"sizes",
                                   headers={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in data['sizes']:
                if size in i['slug'] and "True" in i['available']:
                    SizeId = i['slug']

            request = requests.get(URL_Digitalocean+"regions",
                                   headers={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in data['regions']:
                if region in i['slug'] and "True" in i['available']:
                    RegionId = i['slug']

            if number is not None:
                _body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": "%s",' \
                        '"backups": false,"ipv6": true,"user_data": null,"private_networking": null}' \
                        % (servername, RegionId, SizeId, ImageId, keyid)
                return _body
            else:
                i = 0
                n1 = ""
                while i != (int(number)-1):
                    n1 += '"'+servername + str(i)+'"'+", "
                    _body = '{"name": [%s, "%s"],"region": "%s","size": "%s","image": "%s","ssh_keys": "%s",' \
                        '"backups": false,"ipv6": ' \
                        'true,"user_data": null,"private_networking": null}' \
                            % (n1, servername+str(i+1), region,size, ImageId, key)
                    return _body

            if action.get("insert"):

                requests.post(URL_Digitalocean+"droplets",
                              headers={"Authorization": "Bearer %s" % token},
                              data=_body)
            elif action.get("Remove"):
                requests.delete(URL_Digitalocean+"droplets/%s" % serverid,
                                headers={"Authorization": "Bearer %s" % token})
            elif action.get("Reboot"):
                _body = '{"type":"reboot"}'
                requests.post(URL_Digitalocean+"droplets/%s" % serverid,
                              headers={"Authorization": "Bearer %s" % token}, data=_body)
            elif action.get("Rebuild"):
                request = requests.get(URL_Digitalocean+"images",
                                       headers={"Authorization": "Bearer %s" % token})
                data = request.json()
                for i in data['images']:
                    if distribution in i['slug']:
                        ImageId = i['id']
                _body = '{"type":"rebuild","image":"%s"}' % ImageId
                requests.post(URL_Digitalocean+"droplets/%s/actions" % serverid,
                              headers={"Authorization": "Bearer %s" % token}, data=_body)
            else:
                return 'error'

        @classmethod
        def google(cls, image, project, token, region, size, servername, action, serverid=None):
            global RegionId, ImageId, SizeId
            request = requests.get(
                URL_Google+"%s/%s-cloud/global/images" % (project, image),
                header={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in data['items']:
                if image in data['selfLink']:
                    ImageId = data['selfLink'][-1]

            request = requests.get(URL_Google+"%s/regions" % project,
                                   header={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in data['items']:
                if region in data['items']:
                    RegionId = data['selfLink']

            request = requests.get(
                URL_Google+"%s/zones/%s/machineType" % (project, RegionId),
                header={"Authorization": "Bearer %s" % token})
            data = request.json()
            for i in data['items']:
                if size in data['items']:
                    SizeId = data['selfLink']

            if action.get("Insert"):
                _body = '{"name": "%s","machineType": "%s","networkInterfaces": [{"accessConfigs": ' \
                        '[{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],"network": "global/networks/default"}],' \
                        '"disks": [{"autoDelete": "true","boot": "true","type": "PERSISTENT","initializeParams": ' \
                        '{"sourceImage": "%s"}}]}' % (servername, SizeId, ImageId)
                requests.post(
                    URL_Google+"%s/zones/%s/instances" % (project, RegionId),
                    header={"Authorization": "Bearer %s" % token}, data=_body)

            elif action.get("Remove"):
                requests.delete(URL_Google+"%s/zones/%s/instances/%s" % (
                    project, RegionId, serverid), header={"Authorization": "Bearer %s" % token})
            elif action.get("Reboot"):
                requests.post(URL_Google+"%s/zones/%s/instances/%s/reset" % (
                    project, RegionId, serverid), header={"Authorization": "Bearer %s" % token})
            else:
                return "error"

        @classmethod
        def amazon(cls, accesskey, secretkey, image, number, action, serverid=None):

            connect = boto.connect_ec2(aws_access_key_id=accesskey, aws_secret_access_key=secretkey)

            group = connect.create_security_group(name="SecGroup")
            group.authorize('tcp', 22, 22, '0.0.0.0/0')
            group.authorize('tcp', 3389, 3389, '0.0.0.0/0')

            if action.get("insert"):
                connect.run_instances(image_id=image, min_count=1, max_count=number, instance_type='m1.small',
                                      security_groups=group)
            elif action.get("Remove"):
                connect.terminate_instances(instance_ids=serverid)
            elif action.get("Reboot"):
                connect.stop_instances(instance_ids=serverid)
            else:
                return "error"

        @classmethod
        def ovh(cls, applicationkey, secretkey, endpoint, region, image, flavor, servername, action, serverid=None):
            global time, FlavorId, ImageId
            client = ovh.Client(application_key=applicationkey, application_secret=secretkey, endpoint=endpoint)
            ck = client.new_consumer_key_request()
            consumerkey = (ck.request())['consumerKey']
            d = requests.get(URL_Ovh+"auth/time")
            for i in d:
                time = i

            s1 = hashlib.sha1()
            s1.update("+".join([applicationkey, consumerkey, "GET", "https://eu.api.ovh.com/1.0/cloud/project", time]))
            sig = "$1$" + s1.hexdigest()
            queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time, "X-Ovh-Consumer": consumerkey,
                            "X-Ovh-Signature": sig, "Content-type": "application/json"}
            service = requests.post(URL_Ovh+"cloud/project", headers=queryheaders)

            s1 = hashlib.sha1()
            s1.update("+".join(
                [applicationkey, consumerkey, "GET", URL_Ovh+"cloud/project/%s/image" % service,
                 time]))
            sig = "$1$" + s1.hexdigest()
            queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time, "X-Ovh-Consumer": consumerkey,
                            "X-Ovh-Signature": sig, "Content-type": "application/json"}
            request = requests.get(URL_Ovh+"cloud/project/%s/image" % service, headers=queryheaders)
            data = request.json()
            for i in data:
                if image in i['name'] and endpoint in i['Region']:
                    ImageId = i['id']

            # Get FlavorId
            s1 = hashlib.sha1()
            s1.update("+".join(
                [applicationkey, consumerkey, "GET", URL_Ovh+"cloud/project/%s/flavor" % service,
                 time]))
            sig = "$1$" + s1.hexdigest()
            queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time, "X-Ovh-Consumer": consumerkey,
                            "X-Ovh-Signature": sig, "Content-type": "application/json"}
            request = requests.get(URL_Ovh+"cloud/project/%s/flavor" % service, headers=queryheaders)
            data = request.json()
            for i in data:
                if flavor in i['name'] and endpoint in i['region']:
                    FlavorId = i['id']

            # Instance actions
            if action.get("Insert"):
                s1 = hashlib.sha1()
                s1.update("+".join([applicationkey, consumerkey, "GET",
                                    URL_Ovh+"cloud/project/%s/instance" % service, time]))
                sig = "$1$" + s1.hexdigest()
                queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time,
                                "X-Ovh-Consumer": consumerkey, "X-Ovh-Signature": sig,
                                "Content-type": "application/json"}
                _body = '{"flavorId": %s,"imageId": "%s","monthlyBilling": false,"name": "%s","region": "%s"}' % (
                    FlavorId, ImageId, servername, region)
                requests.post(URL_Ovh+"cloud/project/%s/instance" % service, headers=queryheaders,
                              body=_body)
            elif action.get("Remove"):
                s1 = hashlib.sha1()
                s1.update("+".join([applicationkey, consumerkey, "GET",
                                    URL_Ovh+"cloud/project/%s/instance" % service, time]))
                sig = "$1$" + s1.hexdigest()
                queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time,
                                "X-Ovh-Consumer": consumerkey, "X-Ovh-Signature": sig,
                                "Content-type": "application/json"}
                requests.delete(URL_Ovh+"cloud/project/%s/instance/%s" % (service, serverid),
                                headers=queryheaders)
            elif action.get("Reboot"):
                s1 = hashlib.sha1()
                s1.update("+".join([applicationkey, consumerkey, "GET",
                                    URL_Ovh+"cloud/project/%s/instance" % service, time]))
                sig = "$1$" + s1.hexdigest()
                queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time,
                                "X-Ovh-Consumer": consumerkey, "X-Ovh-Signature": sig,
                                "Content-type": "application/json"}
                requests.post(URL_Ovh+"cloud/project/%s/instance/%s/reboot" % (service, serverid),
                              headers=queryheaders)
            elif action.get("Rebuild"):
                s1 = hashlib.sha1()
                s1.update("+".join([applicationkey, consumerkey, "GET",
                                    URL_Ovh+"cloud/project/%s/instance" % service, time]))
                sig = "$1$" + s1.hexdigest()
                queryheaders = {"X-Ovh-Application": applicationkey, "X-Ovh-Timestamp": time,
                                "X-Ovh-Consumer": consumerkey, "X-Ovh-Signature": sig,
                                "Content-type": "application/json"}
                requests.post(URL_Ovh+"cloud/project/%s/instance/%s/reinstall" % (service, serverid),
                              headers=queryheaders)

        @classmethod
        def aruba(cls, action, region, username, password, image, flavor, servername, servpass, number=None, stype=None,
                  cpu=None, ram=None, disk=None):
            global templ, imageid, flavorid
            connect = CloudInterface(dc=region)
            connect.login(username=username, password=password)
            if None in stype:
                templ = region.find_template(hv=4)
            else:
                if "lowcost" in stype:
                    templ = region.find_template(hv=3)
                elif "hyperv" in stype:
                    templ = region.find_template(hv=1)
                elif "vmware" in stype:
                    templ = region.find_template(hv=2)
                for t in templ:
                    if image in t.id_code and "True" in t.enabled:
                        imageid = t.template_id
            size = {"small", 'medium', 'large', 'extra large'}
            for i in size:
                if flavor in i:
                    return flavorid
                else:
                    Exception("error")
            if action.get("Insert"):
                if stype is None:
                    if number is None:
                        c = SmartVmCreator(name=servername,
                                           admin_password=servpass,
                                           template_id=imageid,
                                           auth_obj=connect.auth)
                        c.set_type(size=flavorid)
                        c.commit(url=connect.wcf_baseurl, debug=True)
                    else:
                        i = 0
                        while i < int(number):
                            i += 1
                            c = SmartVmCreator(name=servername + i,
                                               admin_password=servpass,
                                               template_id=imageid,
                                               auth_obj=connect.auth)
                            c.set_type(size=flavorid)
                            c.commit(url=connect.wcf_baseurl, debug=True)
                            time.sleep(60)
            else:
                if number is None:
                    ip = connect.purchase_ip()
                    pvm = ProVmCreator(name=servername,
                                       admin_password=servpass,
                                       template_id=imageid,
                                       auth_obj=connect.auth)
                    pvm.set_cpu_qty(int(cpu))
                    pvm.set_ram_qty(int(ram))
                    pvm.add_public_ip(public_ip_address_resource_id=ip.resid, primary_ip_address=True)
                    pvm.add_virtual_disk(int(disk))
                    pvm.commit(url=connect.wcf_baseurl, debug=True)
                else:
                    i = 0
                    while i < int(number):
                        i += 1
                        ip = connect.purchase_ip()
                        pvm = ProVmCreator(name=servername + i,
                                           admin_password=servpass,
                                           template_id=imageid,
                                           auth_obj=connect.auth)
                        pvm.set_cpu_qty(int(cpu))
                        pvm.set_ram_qty(int(ram))
                        pvm.add_public_ip(public_ip_address_resource_id=ip.resid, primary_ip_address=True)
                        pvm.add_virtual_disk(int(disk))
                        pvm.commit(url=connect.wcf_baseurl, debug=True)
                        time.sleep(60)

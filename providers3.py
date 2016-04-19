import boto
import requests
import ovh
import hashlib


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


class provider(object):
    name = {'Provider1': 'Amazon',
            'Provider2': 'Cloudwatt',
            'Provider3': 'DigitalOcean',
            'Provider4': 'Google',
            'Provider5': 'Numergy',
            'Provider6': 'OVH',
            'Provider7': 'Rackspace'}

    def __init__(self, name):
        self.name = name

    def get_name(self):
        return self.name


class token(provider):
    accesskey = None
    secretkey = None
    tenantid = None
    username = None
    password = None
    apikey = None
    applicationkey = None
    endpoint = None
    Token = None
    project = None

    # ConsumerKey = None
    # sig = None
    # service = None
    # time = None

    def __init__(self, name):
        """

        :param name:
        """
        super(token, self).__init__(name)
        self.Token = None
        self.accesskey = None
        self.secretkey = None
        self.tenantid = None
        self.username = None
        self.password = None
        self.apikey = None
        self.applicationkey = None
        self.endpoint = None
        self.project = None
        # self.token = None
        # self.ConsumerKey = None
        # self.sig = None
        # self.service = None
        # self.time = None

    if provider.get_name() == 'Numergy':
        def get_version(self):
            request = requests.get("https://api2.numergy.com/")
            data = request.json()
            for i in (data['versions']['version']):
                if "CURRENT" in i['status']:
                    version = i['id']
                    return version

    def get_token(self):
        if provider.get_name() == 'Amazon':
            connect = boto.connect_ec2(aws_access_key_id=self.accesskey, aws_secret_access_key=self.secretkey)
            return connect
        elif provider.get_name() == 'Cloudwatt':
            _body = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='%s'><passwordCredentials username='%s' password='%s'/></auth>" % (
                self.tenantid, self.username, self.password)
            request = requests.post("https://identity.fr1.cloudwatt.com/v2/tokens", data=_body)
            data = request.json()
            token = data['access']['token']['id']
            return token
        elif provider.get_name() == 'Numergy':
            body = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "%s","secretKey": "%s" },"tenantId": "%s"}}' % (
                self.accesskey, self.secretkey, self.tenantid)
            request = requests.post("https://api2.numergy.com/%s/tokens" % self.get_version(), data=body)
            data = request.json()
            token = (data['access']['token']['id'])
            return token
            # return version
        elif provider.get_name() == 'OVH':
            client = ovh.Client(application_key=self.applicationkey, application_secret=self.secretkey,
                                endpoint=self.endpoint)
            ck = client.new_consumer_key_request()
            ConsumerKey = (ck.request())['consumerKey']
            return ConsumerKey
        elif provider.get_name() == 'DigitalOcean' or 'Google':
            return self.Token

    if provider.get_name() == 'OVH':
        def get_service(self):
            s1 = hashlib.sha1()
            s1.update(
                "+".join(
                    [self.applicationkey, self.get_token(), "GET", "https://eu.api.ovh.com/1.0/cloud/project", token.get_time()]))
            sig = "$1$" + s1.hexdigest()
            queryHeaders = {"X-Ovh-Application": self.applicationkey, "X-Ovh-Timestamp": token.get_time(),
                            "X-Ovh-Consumer": self.get_token(),
                            "X-Ovh-Signature": sig, "Content-type": "application/json"}
            service = requests.post("https://eu.api.ovh.com/1.0/cloud/project", headers=queryHeaders)
            return service

        def get_time(self):
            d = requests.get("https://eu.api.ovh.com/1.0/auth/time")
            for i in d:
                time = i
                return time

    if provider.get_name() == 'Google':
        def get_project(self):
            return self.project


class image(provider):
    imgname = None
    project = None

    # appname = None

    def __init__(self, imgname, name):
        """

        :param imgname:
        :param name:
        """
        super(image, self).__init__(name)
        self.imgname = None
        self.project = None
        # appname = None

    def get_name(self):
        return self.imgname

    def get_project(self):
        return self.project

    def getimageid(self):
        if provider.get_name() == "Cloudwatt":
            request = requests.get("https://compute.fr1.cloudwatt.com/v2/%s/images" % token.tenantid,
                                   headers={"X-Auth-Token": "%s" % (token.get_token())})
            data = request.json()
            for i in (data['images']):
                if self.imgname in i['name']:
                    ImageId = i['id']
                    return ImageId
        elif provider.get_name() == "DigitalOcean":
            request = requests.get("https://api.digitalocean.com/v2/images",
                                   headers={"Authorization": "Bearer %s" % token.get_token()})
            data = request.json()
            if self.imgname.split()[2] is None:
                imgkey = (self.imgname).split()[0] + "-" + (self.imgname).split()[1]
            elif (self.imgname).split()[2] is not None:
                imgkey = (self.imgname).split()[0] + "-" + (self.imgname).split()[1] + "-" + (self.imgname).split()[2]
            else:
                imgkey = "coreos-beta"
            for i in data['images']:
                if imgkey in i['slug']:
                    ImageId = i['id']
                    return ImageId
        elif provider.get_name() == "Google":
            request = requests.get(
                "https://www.googleapis.com/compute/v1/projects/%s/%s-cloud/global/images" % (
                    self.project, self.imgname),
                header={"Authorization": "Bearer %s"} % token.get_token())
            data = request.json()
            for i in data['items']:
                if self.imgname in i['selfLink']:
                    ImageId = i['selfLink'][-1]
                    return ImageId
        elif provider.get_name() == 'Numergy':
            if 'Windows' in self.imgname:
                ImgKey = ''.join((list((self.imgname).split()[0])[:3])) + (self.imgname).split()[1] + " " + \
                         (self.imgname).split()[2] + " " + \
                         (self.imgname).split()[3] + " " + (self.imgname).split()[4]
            else:
                ImgKey = ''.join((list((self.imgname).split()[0])[:3])) + (self.imgname).split()[-1]
            request = requests.get("https://api2.numergy.com/%s/%s/images" % (token.get_version(), token.tenantid),
                                   headers={"X-Auth-Token": "%s" % token.get_token()})
            data = request.json()
            for i in (data['images']):
                if ImgKey in i['name']:
                    ImageId = i['id']
                    return ImageId
        elif provider.get_name() == 'OVH':
            s1 = hashlib.sha1()
            s1.update("+".join([token.applicationkey, token.get_token(), "GET",
                                "https://eu.api.ovh.com/1.0/cloud/project/%s/image" % token.get_service(), token.get_time()]))
            sig = "$1$" + s1.hexdigest()
            queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(),
                            "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig,
                            "Content-type": "application/json"}
            image = requests.get("https://eu.api.ovh.com/1.0/cloud/project/%s/image" % token.get_service(),
                                 headers=queryHeaders)
            for i in image:
                if self.imgname in i['name'] and token.endpoint in i['Region']:
                    ImageId = i['id']
                    global ImageId
        elif provider.get_name() == "Rackspace":
            request = requests.get("https://lon.servers.api.rackspacecloud.com/v2/%s/images" % (token.tenantid),
                                   headers={"Authorization": "Bearer %s" % (token.get_token())})
            data = request.json()
            for i in (data['images']):
                if self.imgname in i['name']:
                    ImageId = i['id']
                    global ImageId


class region(provider):
    regname = None

    def __init__(self, regname, name):
        """

        :param regname:
        :param name:
        :return:
        """
        super(region, self).__init__(name)
        self.regname = None

    def get_name(self):
        return self.regname

    def regionid(self):
        if provider.get_name() == "DigitalOcean":
            request = requests.get("https://api.digitalocean.com/v2/regions",
                                   headers={"Authorization": "Bearer %s"} % token.get_token())
            data = request.json()
            for i in data['regions']:
                if self.regname in i['slug'] and "True" in i['available']:
                    RegionId = i['slug']
                    global RegionId
        elif provider.get_name() == "Google":
            request = requests.get("https://www.googleapis.com/compute/v1/projects/%s/regions" % (image.project),
                                   header={"Authorization": "Bearer %s"} % token.get_token())
            data = request.json()
            for i in data['items']:
                if self.regname in i['items']:
                    RegionId = i['selfLink']
                    global RegionId
        elif provider.get_name() == "OVH":
            s1 = hashlib.sha1()
            s1.update("+".join([token.applicationkey, token.get_token(), "GET",
                                "https://eu.api.ovh.com/1.0/cloud/project/%s/region" % token.get_service(), token.get_time()]))
            sig = "$1$" + s1.hexdigest()
            queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(),
                            "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig,
                            "Content-type": "application/json"}
            region = requests.get("https://eu.api.ovh.com/1.0/cloud/project/%s/region" % token.get_service(),
                                  headers=queryHeaders)
            for i in region:
                if list(self.regname)[0] in list(i)[0]:
                    idregion = i
                    return idregion


class flavor(provider):
    flaname = None

    def __init__(self, flaname, name):
        """

        :param flaname:
        :param name:
        :return:
        """
        super(flavor, self).__init__(name)
        self.flaname = None

    def get_name(self):
        return self.flaname

    def flavorid(self):
        if provider.get_name() == 'Cloudwatt':
            request = requests.get("https://compute.fr1.cloudwatt.com/v2/%s/flavors" % token.tenantid,
                                   headers={"X-Auth-Token": "%s" % (token.get_token())})
            data = request.json()
            for i in (data['flavors']):
                if self.flaname in i['name']:
                    FlavorId = i['id']
                    return FlavorId

        elif provider.get_name() == 'DigitalOcean':
            request = requests.get("https://api.digitalocean.com/v2/sizes",
                                   headers={"Authorization": "Bearer %s"} % token.get_token())
            data = request.json()
            for i in data['sizes']:
                if self.flaname in i['slug'] and "True" in i['available']:
                    FlavorId = i['slug']
                    return FlavorId

        elif provider.get_name() == 'Google':
            request = requests.get(
                "https://www.googleapis.com/compute/v1/projects/%s/zones/%s/machineType" % (
                    image.project, region.regionid()),
                header={"Authorization": "Bearer %s"} % token.get_token())
            data = request.json()
            for i in data['items']:
                if self.flaname in data['items']:
                    FlavorId = data['selfLink']
                    return FlavorId
        elif provider.get_name() == 'OVH':
            s1 = hashlib.sha1()
            s1.update("+".join([token.applicationkey, token.get_token(), "GET",
                                "https://eu.api.ovh.com/1.0/cloud/project/%s/flavor" % token.get_service(), token.get_time()]))
            sig = "$1$" + s1.hexdigest()
            queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(),
                            "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig,
                            "Content-type": "application/json"}
            flavor = requests.get("https://eu.api.ovh.com/1.0/cloud/project/%s/flavor" % token.get_service(),
                                  headers=queryHeaders)
            for i in flavor:
                if self.flaname in i['name'] and region.regionid in i['region']:
                    FlavorId = i
                    return FlavorId


class action(provider):
    aname = {'Insert': 'Insert',
             'Reboot': 'Reboot',
             'Remove': 'Remove',
             'Rebuild': 'Rebuild'}

    def __init__(self, aname, name):
        """

        :param aname:
        :param name:
        :return:
        """
        super(action, self).__init__(self, name)
        self.aname = aname

    def get_aname(self):
        return self.aname


class server(provider):
    servername = None
    serverid = None
    number = None
    servpass = None
    image = None

    def __init__(self, servername, serverid, number, servpass, image, name):
        """

        :param servername:
        :param serverid:
        :param number:
        :param name:
        :return:
        """
        super(server, self).__init__(name)
        self.servername = servername
        self.serverid = serverid
        self.number = number
        self.servpass = servpass
        self.image = image

    def get_name(self):
        return self.servername

    def get_id(self):
        return self.serverid

    def get_num(self):
        return self.number

    def saction(self):
        if provider.get_name() == 'Amazon':
            group = token.get_token().create_security_group(name="SecGroup")
            group.authorize('tcp', 22, 22, '0.0.0.0/0')
            group.authorize('tcp', 3389, 3389, '0.0.0.0/0')
            if action.get_aname() == 'Insert':
                token.get_token().run_instances(image.getimageid(), min_count=1, max_count=self.number, instance_type='m1.small',
                                                security_groups=group)
            elif action.get_aname() == 'Remove':
                token.get_token().terminate_instances(instance_ids=self.serverid)
            elif action.get_aname() == 'Reboot':
                token.get_token().stop_instances(instance_ids=self.serverid)
        if provider.get_name() == 'Cloudwatt':
            if action.get_aname() == 'Insert':
                _body = '{"security_group":{"name":"Security","description":"SecGroup"}}'
                request = requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                                        headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                data = request.json()
                SecGroup = data['security_group']['name']
                ## Get Network Id
                _body = '{"network":{"name": "network1", "admin_state_up": true}}'
                request = requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                                        headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                data = request.json
                NetId = data['network']['id']
                _body = '{"subnet":{"network_id":"%s","ip_version":4,"cidr":"192.168.0.0/24"}}' % (NetId)
                requests.post("https://network.fr1.cloudwatt.com/v2/security-groups",
                              headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                global NetId, SecGroup
                ## SSHKey & instance creation
                if image.getimageid() not in "Win":
                    _body = '{"keypair":{"name":"cle"}}'
                    request = requests.post("https://network.fr1.cloudwatt.com/v2/%s/os-keypairs",
                                            headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                    data = request.json()
                    Key = data['keypair']
                    _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"22","ethertype":"IPv4","port_range_max":"22","protocol":"tcp","security_group_id":"%s"}}' % (
                        SecGroup)
                    requests.post("https://network.fr1.cloudwatt.com/v2/security-group-rules",
                                  headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                    _body = '{"server":{"name":"%s","key_name":"cle","imageRef":"%s","flavorRef":"%s","max_count":%s,"min_count":1,"networks":[{"uuid":"%s"}],"metadata": {"admin_pass": "%s"},"security_groups":[{"name":"default"},{"name":"%s"}]}}' % (
                        self.servername, image.getimageid(), flavor.flavorid(), self.number, NetId, self.servpass,
                        SecGroup)
                    request = requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers" % token.tenantid,
                                            headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                    data = request.json()
                    ServerId = data['server']['id']
                else:
                    _body = '{"security_group_rule":{"direction":"ingress","port_range_min":"3389","ethertype":"IPv4","port_range_max":"3389","protocol":"tcp","security_group_id":"%s"}}' % (
                        SecGroup)
                    request = requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers" % token.tenantid,
                                            headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                    data = request.json()
                    ServerId = data['server']['id']
                ## Public Network Interface Id
                request = requests.get("https://network.fr1.cloudwatt.com/v2/networks",
                                       headers={"X-Auth-Token": "%s" % (token.get_token())})
                data = request.json()
                for i in data['networks']:
                    if "public" in i['name']:
                        NetId = i['id']
                ## Floatting IP
                _body = '{"floatingip":{"floating_network_id":"%s"}}' % (NetId)
                request = requests.post("https://network.fr1.cloudwatt.com/v2/floatingips",
                                        headers={"X-Auth-Token": "%s" % (token.get_token())}, data=_body)
                data = request.json()
                IP = data['floatinip']['floating_ip_address']
                global IP
                ## Commit IP to Server
                _body = '{"addFloatingIp":{"address":"%s"}}' % (IP)
                requests.post("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/action" % (token.tenantid, ServerId),
                              headers={"X-Auth-Token": "%s" % (token)}, data=_body)
            elif action.get_aname() == 'Remove':
                requests.delete("https://compute.fr1.cloudwatt.com/v2/%s/servers/%s" % (token.tenantid, self.serverid),
                                headers={"X-Auth-Token": "%s" % token.get_token()})
            elif action.get_aname() == 'Reboot':
                requests.post(
                    "https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/reboot" % (token.tenantid, self.serverid),
                    headers={"X-Auth-Token": "%s" % (token.get_token())})
            elif action.get_aname() == 'Rebuild':
                request = requests.get(
                    "https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/detail" % (token.tenantid, self.serverid),
                    headers={"X-Auth-Token": "%s" % (token.get_token())})
                data = request.json()
                for i in data['servers']:
                    IP = i['addresses']['private']['addr']
                    ImageId = i['image']['id']
                    ServerName = i['name']
                    global IP, ImageId, ServerName
                _body = '{"rebuild": {"imageRef": "%s","name": "%s","adminPass": "%s","accessIPv4": "%s"}}' % (
                    ImageId, ServerName, self.servpass, IP)
                requests.post(
                    "https://compute.fr1.cloudwatt.com/v2/%s/servers/%s/rebuild" % (token.tenantid, self.serverid),
                    headers={"X-Auth-Token": "%s" % (token)}, data=_body)
        elif provider.get_name() == 'DigitalOcean':
            if action.get_aname() == 'Insert':
                Key = generate_RSA(bits=2048)
                _body = '{"name": "%s","region": "%s","size": "%s","image": "%s","ssh_keys": "%s","backups": false,"ipv6": true,"user_data": null,"private_networking": null}' % (
                    self.servername, region.regionid(), flavor.flavorid(), image.getimageid(), Key)
                requests.post("https://api.digitalocean.com/v2/droplets",
                              headers={"Authorization": "Bearer %s"} % token.get_token(),
                              data=_body)
            elif action.get_aname() == 'Remove':
                requests.delete("https://api.digitalocean.com/v2/droplets/%s" % self.serverid,
                                headers={"Authorization": "Bearer %s"} % token.get_token())
            elif action.get_aname() == 'Reboot':
                _body = '{"type":"reboot"}'
                requests.post("https://api.digitalocean.com/v2/droplets/%s" % self.serverid,
                              headers={"Authorization": "Bearer %s"} % token.get_token(), data=_body)
            elif action.get_aname() == 'Rebuild':
                request = requests.get("https://api.digitalocean.com/v2/images",
                                       headers={"Authorization": "Bearer %s"} % token.get_token())
                data = request.json()
                for i in data['images']:
                    if self.image in i['slug']:
                        ImageId = i['id']
                _body = '{"type":"rebuild","image":"%s"}' % ImageId
                requests.post("https://api.digitalocean.com/v2/droplets/%s/actions" % self.serverid,
                              headers={"Authorization": "Bearer %s"} % token.get_token(), data=_body)
        elif provider.get_name() == 'Google':
            if action.get_aname() == 'Insert':
                _body = '{"name": "%s","machineType": "%s","networkInterfaces": [{"accessConfigs": [{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],"network": "global/networks/default"}],"disks": [{"autoDelete": "true","boot": "true","type": "PERSISTENT","initializeParams": {"sourceImage": "%s"}}]}' % (
                    self.servername, flavor.flavorid(), image.getimageid())
                requests.post(
                    "https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances" % (
                    token.get_project(), region.regionid()),
                    header={"Authorization": "Bearer %s"} % token.get_token(), data=_body)
            elif action.get_aname() == 'Reboot':
                requests.post("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s/reset" % (
                    token.get_project(), region.regionid(), self.serverid), header={"Authorization": "Bearer %s"} % token.get_token())
            elif action.get_aname() == 'Remove':
                requests.delete("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s" % (
                    token.get_project(), region.regionid(), self.serverid), header={"Authorization": "Bearer %s"} % token.get_token())
        elif provider.get_name() == 'Numergy':
            if action.get_aname() == 'Insert':
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    flavor.flavorid(), image.getimageid(), self.servername)
                requests.post("https://api2.numergy.com/%s/%s/servers" % (token.get_version(), token.tenantid),
                              headers={"X-Auth-Token": "%s" % token.get_token()}, data=_body)
            elif action.get_name() == 'Reboot':
                _body = '{"reboot": {"type": "SOFT"}}'
                requests.post(
                    "https://compute.fr1.cloudwatt.com/%s/%s/servers/%s/reboot" % (token.get_version(), token.tenantid, self.serverid),
                    data=_body, headers={"X-Auth-Token": "%s" % token.get_token()})
            elif action.get_aname() == 'Remove':
                requests.delete("https://compute.fr1.cloudwatt.com/%s/%s/servers/%s" % (token.get_version(), token.tenantid, self.serverid),
                                headers={"X-Auth-Token": "%s" % token.get_token()})
            elif action.get_aname() == 'Rebuild':
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    flavor.flavorid(), image.getimageid(), self.servername)
                requests.post("https://api2.numergy.com/%s/%s/servers/%s" % (token.get_version(), token.tenantid, self.serverid),
                              headers={"X-Auth-Token": "%s" % token.get_token()}, data=_body)
        elif provider.get_name() == '':
            if action.get_aname() == 'Insert':
                s1 = hashlib.sha1()
                s1.update("+".join([token.applicationkey, token.get_token(), "GET", "https://eu.api.ovh.com/1.0/cloud/project/%s/instance"%token.get_service(),token.get_time()]))
                sig = "$1$" + s1.hexdigest()
                queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(), "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig, "Content-type": "application/json"}
                _body = '{"flavorId": %s,"imageId": "%s","monthlyBilling": false,"name": "%s","region": "%s"}'% (flavor.flavorid(), image.getimageid(), self.servername, region.regionid())
                requests.post("https://eu.api.ovh.com/1.0/cloud/project/%s/instance"%token.get_service(),headers=queryHeaders,body=_body)
            elif action.get_aname() == 'Remove':
                s1 = hashlib.sha1()
                s1.update("+".join([token.applicationkey, token.get_token(), "GET", "https://eu.api.ovh.com/1.0/cloud/project/%s/instance"%token.get_service(),token.get_time()]))
                sig = "$1$" + s1.hexdigest()
                queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(), "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig, "Content-type": "application/json"}
                requests.delete("https://eu.api.ovh.com/1.0/cloud/project/%s/instance/%s"%(token.get_service(), self.serverid),headers=queryHeaders)
            elif action.get_aname() == 'Reboot':
                s1 = hashlib.sha1()
                s1.update("+".join([token.applicationkey, token.get_token(), "GET", "https://eu.api.ovh.com/1.0/cloud/project/%s/instance"%token.get_service(),token.get_time()]))
                sig = "$1$" + s1.hexdigest()
                queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(), "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig, "Content-type": "application/json"}
                requests.post("https://eu.api.ovh.com/1.0/cloud/project/%s/instance/%s/reboot"%(token.get_service(), self.serverid),headers=queryHeaders)
            elif action.get_aname() == 'Rebuild':
                s1 = hashlib.sha1()
                s1.update("+".join([token.applicationkey, token.get_token(), "GET", "https://eu.api.ovh.com/1.0/cloud/project/%s/instance"%token.get_service(),token.get_time()]))
                sig = "$1$" + s1.hexdigest()
                queryHeaders = {"X-Ovh-Application": token.applicationkey, "X-Ovh-Timestamp": token.get_time(), "X-Ovh-Consumer": token.get_token(), "X-Ovh-Signature": sig, "Content-type": "application/json"}
                requests.post("https://eu.api.ovh.com/1.0/cloud/project/%s/instance/%s/reinstall"%(token.get_service(), self.serverid),headers=queryHeaders)
        elif provider.get_name() == 'Rackspace':
            if action.get_aname() == 'Insert':
                _body = '{"server": {"name": "%s","imageRef": "%s","flavorRef": "%s"}}' % (
                self.servername, image.getimageid(), flavor.flavorid())
                requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers" % (token.tenantid),
                              headers={"Authorization": "Bearer %s" % (token.get_token())}, data=_body)
            elif action.get_aname() == 'Remove':
                requests.delete("https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s" % (token.tenantid, self.serverid),
                                headers={"Authorization": "Bearer %s" % (token.get_token())})
            elif action.get_aname() == 'Reboot':
                _body = '{"reboot": {"type": "SOFT"}}'
                requests.post(
                    "https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s/reboot" % (token.tenantid, self.serverid),
                    data=_body, headers={"Authorization": "Bearer %s" % (token.get_token())})
            elif action.get_aname() == 'Rebuild':
                _body = '{"server": {"flavorRef": %s,"imageRef": %s,"name": %s,"password_delivery": API}}' % (
                    flavor.flavorid(), ImageId, ServerName)
                requests.post("https://lon.servers.api.rackspacecloud.com/v2/%s/servers/%s" % (token.tenantid, self.serverid),
                              data=_body, headers={"Authorization": "Bearer %s" % (token.get_token())})
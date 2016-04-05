function GNU_Install {
    Param(
        [Parameter(Mandatory=$true,position = 0)][string]$IP,
        [Parameter(Mandatory=$true,Position = 1)][string]$Username,
        [Parameter(Mandotory=$true,Position = 2)][string]$Password,
        [Parameter(Mandatory=$true,Position = 3)][string]$Port,
        [Parameter(Mandatory=$true,Position = 4)][ValidateSet("Install","Remove","Upgrade")]$Action,
        [Parameter(Mandatory=$false,Position = 5)][string]$Package
    )

    ## Import SSH Module
    if ((Get-Command -All) -notmatch "New-SSHSession"){
        iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
    } 
    Import-Module Posh-SSH

    $credentials = New-Object System.Management.Automation.PSCredential($username,$password)
    
    $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk","emerge","lin","cast","nix","xbps-install"

    foreach ($i in $packman) {
        if ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /usr/bin") -match $i) {#apt-get | yum | zypper | equo | pacman | emerge | xbps-install
            switch ($Action) {
                "Install" {
                    switch ($i) {
                        "apt-get" {return "$i install -y"}
                        "yum" {return "$i install -y"}
                        "zypper" {return "$i install -y"}
                        "equo" {return "$i install -y"}
                        "pacman" {return "$i -S"}
                        "emerge" {return "$i "}
                        "xbps-install" {return "$i -y"}
                    }
                }
                "Remove" {
                    switch ($i) {
                        "apt-get" {return "$i remove -y"}
                        "yum" {return "$i erase -y"}
                        "zypper" {return "$i remove -y"}
                        "equo" {return "$i remove -y"}
                        "pacman" {return "$i -R"}
                        "emerge" {return "$i -Ac"}
                        "xbps-install" {return "xbps-remove -y"}
                    }
                }
                "Upgrade" {
                    switch ($i) {
                        "apt-get" {return "$i install -y"}
                        "yum" {return "$i update -y"}
                        "zypper" {return "$i update -t package -y"}
                        "equo" {return "$i install -y"}
                        "pacman" {return "$i -S"}
                        "emerge" {return "$i "}
                        "xbps-install" {return "xbps-install -u -y"}
                    }
                }
                default {}
            }
        }
        elseif ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /usr/sbin") -match $i){
            switch ($Action) { #slackpkg | urpmi | cast
                "Install" {
                    switch ($i) { 
                        "slackpkg" {return "$i install -y"}
                        "urpmi" {return "$i -y"}
                        "cast" {return "$i -y"}
                    }
                }
                "Remove" {
                    switch ($i) { #slackpkg | urpmi | cast
                        "slackpkg" {return "$i remove -y"}
                        "urpmi" {return "urpme -y"}
                        "cast" {return "dispel -y"}
                    }
                }
                "Upgrade" {
                    switch ($i) { #slackpkg | urpmi | cast
                        "slackpkg" {return "$i upgrade -y"}
                        "urpmi" {return "$i -y"}
                        "cast" {return "$i -y"}
                    }
                }
                default {}
            }
        }
        elseif ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /etc") -match $i) {
            switch ($Action) {
                "Install" { #apk | nix
                    switch ($i) {
                        "apk" {return "$i add -y"}
                        "nix" {return "nix-env -i -y"}
                    }
                }
                "Remove" { #apk | nix
                    switch ($i) {
                        "apk" {return "$i del -y"}
                        "nix" {return "nix-env -e -y"}
                    }
                }
                "Remove" { #apk | nix
                    switch ($i) {
                        "apk" {return "$i add -upgrade -y"}
                        "nix" {return "nix-env -u -y"}
                    }
                }
                default {}
            }
        }
        else {return "Operation Impossible"}
    } 
    New-SSHSession -ComputerName $IP -Credentials $credentials -Port $Port
    Invoke-SSHCommand -SessionId (Get-SSHSession).SessionId -Command "$Action $Package"
}
function Provider {
    Param(
        [Parameter(Mandatory=$true,position = 0)][string]$Name,
        [Parameter(Mandatory=$true,Position = 1)][string]$VMName,
        [Parameter(Mandotory=$true,Position = 2)][string]$Image,
        [Parameter(Mandatory=$true,Position = 3)][string]$Size,
        [Parameter(Mandatory=$true,Position = 4)][string]$Region,
        [Parameter(Mandatory=$false,Position = 5)][string]$Password,
        [Parameter(Mandatory=$false,Position = 6)][string]$Number,
        [Parameter(Mandatory=$false,Position = 7)][string]$Token,
        [Parameter(Mandatory=$false,Position = 8)][string]$Tenant,
        [Parameter(Mandatory=$false,Position = 9)][string]$Username,
        [Parameter(Mandatory=$false,Position = 10)][string]$Password,
        [Parameter(Mandatory=$false,Position = 11)][string]$APIKey,
        [Parameter(Mandatory=$false,Position = 12)][string]$Project,
        [Parameter(Mandatory=$false,Position = 13)][string]$AccessKey,
        [Parameter(Mandatory=$false,Position = 14)][string]$SecretKey
    )
    switch ($Name) {
        "Cloudwatt" {
            # Token
            [xml]$auth = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='$Tenant'><passwordCredentials username='$Username' password='$Password'/></auth>"
            [xml]$TokenRequest = Invoke-WebRequest -Uri "https://identity.fr1.cloudwatt.com/v2.0/tokens" -ContentType "application/json" -Method Post -Headers @{"Accept" = "application/json"} -Body $auth
            $Token = $TokenRequest.access.token.id
            $Version = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/ -Method Get).content | ConvertFrom-Json).versions).id
            # Image
            $ImageSet = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/images -Method Get -Headers @{"X-Auth-Token" = '"'+$Token+'"'}).content | ConvertFrom-Json).images | where name -EQ "$Image").id
            # Size
            $SizeSet = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/flavors -Method Get -Headers @{"X-Auth-Token" = '"'+$Token+'"'}).content | ConvertFrom-Json).flavors | where name -Match "$Size").id
            # Security Group
            $SGroup = (((Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/v2.0/security-groups -Method Post -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body '{"security_group":{"name":"Security","description":"SecGroup"}}').content | ConvertFrom-Json).security_group).name
            # Network
            $NetworkId = (((Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/v2.0/security-groups -Method Post -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body '{"network":{"name": "network1", "admin_state_up": true}}').content | ConvertFrom-Json).network).id
            Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/v2.0/security-groups -Method Post -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body '{"subnet":{"network_id":"'$NetworkId'","ip_version":4,"cidr":"192.168.0.0/24"}}'
            # SSH (Keys & Auth) & Instance creation
            if ($Image -match "CoreOS" -or "CentOS" -or "Debian" -or "Ubuntu" -or "OpenSuse" -or "Fedora") {
                # Key
                $Key = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/os-keypairs -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Post -Body '{"keypair":{"name":"cle"}}').content | ConvertFrom-Json).keypair)
                Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/$Version/security-group-rules -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Post -Body '{"security_group_rule":{"direction":"ingress","port_range_min":"22","ethertype":"IPv4","port_range_max":"22","protocol":"tcp","security_group_id":"'+$SgroupId+'"}}'
                Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/servers -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Post -Body '{"server": {"name": "'+$VMName+'","imageRef": "'+$ImageSet+'","flavorRef": "'+$SizeSet+'","metadata": {"My Server Name": "'+$VMName+'"},"personality": [{"path": "~/.ssh/authorized_keys","contents": "'+$Key+'"}]}}'
            }
            else {
                Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/$Version/security-group-rules -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Post -Body '{"security_group_rule":{"direction":"ingress","port_range_min":"3389","ethertype":"IPv4","port_range_max":"3389","protocol":"tcp","security_group_id":"'$SgroupId'"}}'
                Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/servers -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Post -Body '{"server":{"name":"'+$VMName+'","key_name":"cle","imageRef":"'+$ImageSet+'","flavorRef":"'+$SizeSet+'","max_count":'+$Number+',"min_count":1,"networks":[{"uuid":"'+$NetworkId+'"}],"metadata": {"admin_pass": "'+$Password+'"},"security_groups":[{"name":"default"},{"name":"'+$Sgroup+'"}]}}'
            }
        }
        "Numergy" {
            # Token
            $Nversion = ((Invoke-WebRequest -Uri "https://api2.numergy.com/" -ContentType "application/json; charset=utf-8" -Method Get | ConvertFrom-Json).versions | select -Property id,status -Last 1).id
            $Tbody = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "'+$AccessKey+'","secretKey": "'+$SecretKey+'" },"tenantId": "'+$tenantId+'" } }'
            $Token = (((((Invoke-WebRequest -Uri "https://api2.numergy.com/V3.0/tokens" -ContentType "application/json; charset=utf-8" -Method Post -Body $TBody) | ConvertFrom-Json).access).token).id)
            # Size
            $SizeSet = ((((Invoke-WebRequest -Uri http://api2.numergy.com/$Version/$Tenant/flavors -Headers @{"ContentType" = "application/json; charset=utf-8";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Get).content) | ConvertFrom-Json).flavors | where name -EQ "$Size").id
            # Image
            $ImageSet = ((((Invoke-WebRequest -Uri http://api2.numergy.com/$Version/$Tenant/images -Headers -Headers @{"ContentType" = "application/json; charset=utf-8";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Get).content) | ConvertFrom-Json).images | where name -EQ "$Image").id
            # Instance creation
            $Uri = https://api2.numergy.com/$Nversion/$TenantID/servers
            $Body = '{"server": {"flavorRef": "'+$SizeSet+'","imageRef": "'+$ImageSet+'","name": "'+$VMName+'"}}'
            Invoke-WebRequest -Uri https://api2.numergy.com/$Nversion/$TenantID/servers -Method Post -Headers @{"ContentType" = "application/json; charset=utf-8";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body $Body
        }
        "Rackspace" {
            # Token
            $Token = (((((Invoke-WebRequest -Uri "https://identity.api.rackspacecloud.com/v2.0/tokens" -ContentType "application/json" -Body "'"+'{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'+$Username+'","apiKey":"'+$apiKey+'"}}}'+"'") | ConvertFrom-Json).access).token).id)
            # Size 
            $SizeSet = ((((Invoke-WebRequest -Uri https://dfw.servers.api.rackspacecloud.com/v2/$Tenant/flavors -Headers -Headers @{"ContentType" = "application/json; charset=utf-8";"X-Auth-Token" = '"'+$TokenSet+'"'} -Method Get).content) | ConvertFrom-Json).flavors | where name -EQ "$Size").id
            # Image
            $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/windows-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
            # Instance creation
            $Body = '{"server": {"name": "'+$Name+'","imageRef": "'+$ImageSet+'","flavorRef": "'+$sizeSet+'"}}'
            Invoke-WebRequest -Uri https://servers.api.rackspacecloud.com/v1.0/010101/v2/$Tenant/servers -Method Post -Headers @{"ContentType" = "application/json";"X-Auth-Token" = $TokenSet;"X-Auth-Project-Id" = $VMName} -Body $Body
        }
        "DigitalOcean" {
            # Image
            $ImageSet = ((((((Invoke-WebRequest -Uri https://api.digitalocean.com/v2/images -Headers @{"Authorization" = "Bearer $Token"} -Method Get).content) | ConvertFrom-Json).images)| where slug -match "$Image").id)
            # Region
            $RegionSet = ((((((Invoke-WebRequest -Uri https://api.digitalocean.com/v2/regions -Headers @{"Authorization" = "Bearer $Token"} -Method Get).content) | ConvertFrom-Json).regions) | where available -Match "True" | where slug -match "$Region").slug)
            # Size
            $SizeSet = ((((((Invoke-WebRequest -Uri https://api.digitalocean.com/v2/sizes -Headers @{"Authorization" = "Bearer $Token"} -Method Get).content) | ConvertFrom-Json).sizes) | where available -Match "True" | where slug -match "$Size" ).slug)
            # Instance creation
            if ($Number -gt 1) {
                switch ($Number) {
                        2 {$body = '{"name": ["'+$VMName[0]+'","'+$VMName[1]+'"],"region": "'+$RegionSet+'","size": "'+$SizeSet+'","image": "'+$ImageSet+'","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'}
                        3 {$body = '{"name": ["'+$VMName[0]+'","'+$VMName[1]+'","'+$VMName[2]+'"],"region": "'+$RegionSet+'","size": "'+$SizeSet+'","image": "'+$ImageSet+'","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'}
                        4 {$body = '{"name": ["'+$VMName[0]+'","'+$VMName[1]+'","'+$VMName[2]+'","'+$VMName[3]+'"],"region": "'+$RegionSet+'","size": "'+$SizeSet+'","image": "'+$ImageSet+'","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'}
                        5 {$body = '{"name": ["'+$VMName[0]+'","'+$VMName[1]+'","'+$VMName[2]+'","'+$VMName[3]+'","'+$VMName[4]+'"],"region": "'+$RegionSet+'","size": "'+$SizeSet+'","image": "'+$ImageSet+'","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'}
                        default {}
                    }
                Invoke-WebRequest -Uri https://api.digitalocean.com/v2/droplets -Method POST -Headers @{"Content-Type" = "application/json";"Authorization" = "Bearer $Token"} -Body $body 
                }
            else {
                $body = '{"name": "'+$VMName+'","region": "'+$RegionSet+'","size": "'+$SizeSet+'","image": "'+$ImageSet+'","ssh_keys": null,"backups": false,"ipv6": true,"user_data": null,"private_networking": null}'
                Invoke-WebRequest -Uri https://api.digitalocean.com/v2/droplets -Method POST -Headers @{"Content-Type" = "application/json";"Authorization" = "Bearer $Token"} -Body $body  
                }
            }
        }
        "Google" {
            # Image
            switch ($Image) {
                "debian" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/debian-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                "centos" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/centos-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                "opensuse" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/opensuse-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                "red(-)hat" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/rhel-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                "ubuntu" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects$Project/ubuntu-os-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                "Windows" {
                    $ImageSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/windows-cloud/global/images -Headers @{"Authorization" = "Bearer " + $Token} -Method Get ).content | ConvertFrom-Json).items | where selfLink -Match "$Image" | select -Last 1)
                }
                default {}
            }
            # Size
            $SizeSet = ((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/zones/$Region/machineType -Method Get -Headers @{"Authorization" = "Bearer " + $Token}).content | ConvertFrom-Json | where name -Match $Size).selfLink
            # Region
            $RegionSet = (((Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/regions -Headers @{"Authorization" = "Bearer " + $Token} -Method Get).content | ConvertFrom-Json | where items -Match "$Region" ).items)
            # Instance creation
            $Body = '{
                "name": "'+$VMName+'",
                "machineType": "'+$SizeSet+'",
                "networkInterfaces": 
                    [{"accessConfigs": 
                        [{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],
                    "network": "global/networks/default"}],
                    "disks": 
                    [{"autoDelete": "true",
                        "boot": "true",
                        "type": "PERSISTENT",
                        "initializeParams": 
                        {"sourceImage": "'+$ImageSet+'"}
                    }]
                }'
            Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/zones/$Zone/instances?key=$Key -Method POST -Headers @{"ContentType" = "application/json";"Content-Type" = "application/x-www-form-urlencoded";"Authorization" = "Bearer " + $Token} -body $Body
        }
        default {}
    }
}
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
        [Parameter(Mandatory=$false,Position = 5)][string]$Token,
        [Parameter(Mandatory=$false,Position = 5)][string]$Tenant,
        [Parameter(Mandatory=$false,Position = 5)][string]$Username,
        [Parameter(Mandatory=$false,Position = 5)][string]$Password
    )
    switch ($Name) {
        "Cloudwatt" {
            [xml]$auth = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='$Tenant'><passwordCredentials username='$Username' password='$Password'/></auth>"
            [xml]$TokenRequest = Invoke-WebRequest -Uri "https://identity.fr1.cloudwatt.com/v2.0/tokens" -ContentType "application/json" -Method Post -Headers @{"Accept" = "application/json"} -Body $auth
            $Token = $TokenRequest.access.token.id
            $Version = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/ -Method Get).content | ConvertFrom-Json).versions).id
            $ImageSet = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/images -Method Get -Headers @{"X-Auth-Token" = '"'+$Token+'"'}).content | ConvertFrom-Json).images | where name -EQ "$Image").id
            $SizeSet = (((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/flavors -Method Get -Headers @{"X-Auth-Token" = '"'+$Token+'"'}).content | ConvertFrom-Json).flavors | where name -Match "$Size").id
            [xml]$InsCreate = "<?xml version='1.0' encoding='UTF-8'?><server xmlns='http://docs.openstack.org/compute/api/v1.1' imageRef='$ImageSet' flavorRef='$SizeSet' name='$VMName'></server>" 
            Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/servers -Method Post -ContentType "application/json" -Headers @{"Accept" = "application/json";"X-Auth-Token"= "$Token"}
            $ServerId = ((Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/servers -Method Post -ContentType "application/json" -Headers @{"Accept" = "application/json";"X-Auth-Token"= "$Token"} -Body $InsCreate | ConvertFrom-Json).server).id
            $NetId = ((((Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/$Version/networks -ContentType "application/json" -Method GET -Headers @{"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'}) | ConvertFrom-Json).networks).id | where {$_.name -match "public"})
            $IP = (((Invoke-WebRequest -Uri https://network.fr1.cloudwatt.com/$Version/floatingips -ContentType "application/json" -Method Post -Headers @{"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body "'"+"{"+"floatingip"+':'+'{'+'"'+"floating_network_id"+'"'+':'+'"'+$NetId+'"}}'+"'" | ConvertFrom-Json).floatingip).floating_ip_address)
            Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/$Version/$Tenant/servers/$ServerId/action -Method Post -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body "'{"+'addFloatingIp":{"address":"'+$IP+'"}}'+"'"
        }
    }
}
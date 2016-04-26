# Version 1
function Package {
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
    
    ## Package Manager available for linux distributions
    $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk","emerge","lin","cast","nix","xbps-install"
    foreach ($i in $packman) {
        #apt-get | yum | zypper | equo | pacman | emerge | xbps-install
        if ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /usr/bin") -match $i) {
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
        #slackpkg | urpmi | cast
        elseif ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /usr/sbin") -match $i){
            switch ($Action) { 
                "Install" {
                    switch ($i) { 
                        "slackpkg" {return "$i install -y"}
                        "urpmi" {return "$i -y"}
                        "cast" {return "$i -y"}
                    }
                }
                "Remove" {
                    switch ($i) { 
                        "slackpkg" {return "$i remove -y"}
                        "urpmi" {return "urpme -y"}
                        "cast" {return "dispel -y"}
                    }
                }
                "Upgrade" {
                    switch ($i) { 
                        "slackpkg" {return "$i upgrade -y"}
                        "urpmi" {return "$i -y"}
                        "cast" {return "$i -y"}
                    }
                }
                default {}
            }
        }
        #apk | nix
        elseif ((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /etc") -match $i) {
            switch ($Action) {
                "Install" { 
                    switch ($i) {
                        "apk" {return "$i add -y"}
                        "nix" {return "nix-env -i -y"}
                    }
                }
                "Remove" { 
                    switch ($i) {
                        "apk" {return "$i del -y"}
                        "nix" {return "nix-env -e -y"}
                    }
                }
                "Remove" { 
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
    
    Invoke-SSHCommand -SessionId (Get-SSHSession).SessionId -Command "$Action $Package"
}
function PacMan ($file) {
    $IP = ((import-Csv $file -Delimiter ";").IP)
            $Username = ((import-Csv $file -Delimiter ";").Username)
            $Password = ((import-Csv $file -Delimiter ";").Password)
            $Port = ((import-Csv $file -Delimiter ";").Port)
            $Action = ((import-Csv $file -Delimiter ";").Action)
            $Package = ((import-Csv $file -Delimiter ";").Package)
            $credentials = New-Object System.Management.Automation.PSCredential($username,$password)
            foreach ($i in ((import-Csv $file -Delimiter ";").IP)) {
                New-SSHSession -ComputerName $IP -Credentials $credentials -Port $Port
                Package -IP $i -Username $Username -Password $Password -Port $Port -Action $Action -Package $Package
}
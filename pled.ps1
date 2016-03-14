############ Powershell Linux Easy Deploy ############
$version = "1.0"
####### Import SSH module #######
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
#################################
####### Custom Functions ########
####### Example Inventory file #########
## IP;Port;Packages;
## 192.168.99.100;32768;vim;
## ;;curl;
## ;;wget;
## ;;java;
### It will install vim, curl, wget and java on the host 192.168.99.100 (ssh port 32768)
####### Action available in inventory file
## Install | Remove | Search | UpSystem (a.k.a : Update System) | UpPackage (a.k.a : Update package list)
########################################
function PacMan {
    $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman -S","conary","apk add","emerge","lin","cast","niv-env -i","xpbs-install","snappy"
    if ($Action -match "Install") {
        foreach ($p in $packman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "apt-get"-or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {
                    return $p+" install -y"}           
                elseif ($p -match "slapt-get") {
                    return $p+" --install -y"}
                else {return $p} 
            }
        }
    }
    elseif ($Action -match "Remove") {
        foreach ($p in $packman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "apt-get"-or "zypper" -or "slackpkg" -or "slap-get" -or "equo" -or "snappy" -or "netpkg") {
                    return $p+" remove -y"
                }
                elseif ($p -match "yum") {
                    return $p+" erase -y"
                }
                elseif ($p -match "slapt-get") {
                    return $p+" --remove -y"
                }
                else {return $p} 
            }
        }
    }
    elseif ($Action -match "Search") {
        foreach ($p in $pacman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "apt-get") {
                    return "apt-cache"
                }
                elseif ($p -match "zypper") {
                    return $p+" search -t pattern"
                }
                elseif ($p -match "yum" -or "equo" -or "slackpkg" -or "apk" -or "snappy") {
                    return $p+"search"
                }
                elseif ($p -match "urpmi") {
                    return "urpmq -fuzzy"
                }
                elseif ($p -match "netpkg") {
                    return $p+"list | grep"
                }
                elseif ($p -match "conary") {
                    return $p+" query"
                }
                elseif ($p -match "Pacman") {
                    return $p+"s"
                }
                elseif ($p -match "emerge") {
                    return $p+" --search"
                }
                elseif ($p -match "lin") {
                    return "lvu search"
                }
                elseif ($p -match "cast") {
                    return "gaze search"
                }
                elseif ($p -match "nix-env") {
                    return "nix-env -qa"
                }
                else {
                    return "xbps-query -Rs"
                }
            }
        }
        
    }
    elseif ($Action -match "UpSystem") {
        foreach ($p in $packman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "zypper" -or "yum" -or "snappy") {return $p+" update -y"}
                elseif ($p -match "apt" -or "netpkg" -or "equo" -or "apk" ) {return $p+" upgrade -y"}
                elseif ($p -match "urpmi") {return $p+" --auto-select"}
                elseif ($p -match "slapt-get") {return $p+" --upgrade"}
                elseif ($p -match "slackpkg") {return $p+" upgrade-all"}
                elseif ($p -match "pacman") {return $p+"u"}
                elseif ($p -match "conary") {return $p+" updateall"}
                elseif ($p -match "emerge") {return $p+" -NuDa world"}
                elseif ($p -match "lin") {return "lunar update"}
                elseif ($p -match "cast") {return "sorcery upgrade"}
                elseif ($p -match "nix") {return "nix-env -u"}
                else {return "xbps-install -u"}
            }
        }
    }
    elseif ($Action -match "UpPackage") {
        foreach ($p in $packman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "zypper") {return $p+" refresh -y"}
                elseif ($p -match "yum") {return $p+" check-update"}
                elseif ($p -match "apt" -or "equo" -or "apk" -or "slackpkg") {return $p+" update -y"}
                elseif ($p -match "urpmi") {return $p+".update -a"}
                elseif ($p -match "slapt-get") {return $p+" --update"}
                elseif ($p -match "pacman") {return $p+"y"}
                elseif ($p -match "emerge") {return $p+" --sync"}
                elseif ($p -match "lin") {return "lin moonbase"}
                elseif ($p -match "cast") {return "scribe update"}
                elseif ($p -match "nix") {return "nix-channel --update"}
                else {return "xbps-install -u"}
            }
        }
    }
    else {}
}
#######       Code       ########
Write-Host "Powershell Linux Easy Deploy $version"
do {
    [int]$menu0 = 0
    while ($menu0 -lt 1 -or $menu0 -gt 2) {
        Write-Host "1. Auto deploy"
        Write-Host "2. Manual deploy"
        Write-Host "3. Quitter"
        [int]$menu0 = Read-Host "Votre choix ?"
    }
    switch($menu0){
        1 {
            $file = Read-Host "Fichier d'inventaire"
            foreach ($i in ((Import-Csv $file -Delimiter ";" | select -Property IP).IP)) {
                New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port)
                $pacman = PacMan -Action Install
                $Action = (Import-Csv $file -Delimiter ";").Action
                foreach ($p in ((Import-Csv .\Classeur1.csv -Delimiter ";").Packages)) {
                    (Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman $p").Output
                }
            }
        }
        2{
            $nb = Read-Host "Nombre d'hôtes"
            do {
                $ip = Read-Host "Adresse ip du serveur distant"
                $port = Read-Host "port ssh"
                New-SSHSession -ComputerName $ip -Port $port
            }
            while ($nb -notmatch ((Get-SSHSession).SessionId).Count)
            Write-Host "Liste des sessions SSH ouvertes"
            Get-SSHSession
            $id = Read-Host "Entrez l'id de la session"
            $pacman = PacMan -Action Install
            $package = Read-Host "Quel package ?"
            $Action = "Souhaitez-vous : Install | Remove | Search | UpSystem | UpPackage "
            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman $p").Output
        }
        3{
            foreach ($i in (Get-SSHSession).Index) {
                Remove-SSHSession -SessionId $i
            }
            exit
        }
    }
}
while ($menu -notmatch "3")
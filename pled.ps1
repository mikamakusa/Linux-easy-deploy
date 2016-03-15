############ Powershell Linux Easy Deploy ###############
$version = "1.0"
################### Import SSH module ###################
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
#########################################################
################### Custom Functions ####################
############### Example Inventory file ##################
## IP;Port;User;Password;Packages;Action
## 192.168.99.100;32768;root;$pPsd34n0;vim;Install
## ;;;;curl;Remove
## ;;;;wget;Search
## ;;;;java;Install
## 192.168.99.110;32769;;;;UpSystem
### It will install vim and Java, Remove curl, Search wget on the host 192.168.99.100 (ssh port 32768)
### And make an upgrade system for 192.168.99.110
####### Action available in inventory file
## Install | Remove | Search | UpSystem (a.k.a : Update System) | UpPackage (a.k.a : Update package list)
#########################################################
function PacMan {
    $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman -S","conary","apk add","emerge","lin","cast","niv-env -i","xpbs-install","snappy"
        foreach ($item in packman) {
        if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$item").ExitStatus -notmatch "127")) {
            if ($Action -match "Install") {
                if ($item -match "apt-get" -or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {return $item+" install -y"}
                elseif ($item -match "slapt-get") {return $item+" --install -y"}
                elseif ($item -match "pacman") {return $item+" -S"}
                elseif ($item -match "conary") {return $item+" update"}
                elseif ($item -match "apk") {return $item+" add"}
                elseif ($item -match "nix-env") {return $item+" -i"}
                elseif ($item -match "xpbs") {return $item+"-install"}
                else {return $item}
            }
            elseif ($Action -match "Remove") {
                if ($item -match "apt-get"-or "zypper" -or "slackpkg" -or "equo" -or "snappy" -or "netpkg") {return $item+" remove -y"}
                elseif ($item -match "yum" -or "conary") {return $item+" erase -y"}
                elseif ($item -match "slapt-get") {return $item+" --remove -y"}
                elseif ($item -match "urpmi") {return "urpme"}
                elseif ($item -match "pacman") {return $item+" -R"}
                elseif ($item -match "apk") {return $item+" del"}
                elseif ($item -match "emerge") {return $item+" -aC"}
                elseif ($item -match "lin") {return "lrm"}
                elseif ($item -match "cast") {return "dispel"}
                elseif ($item -match "nix-env") {return $item+" -e"}
                elseif ($item -match "xpbs") {return $item+"-remove"}
                else {}
            }
            elseif ($Action -match "Search") {
                if ($item -match "apt-get") {return "apt-cache"}
                elseif ($item -match "zypper") {return $item+" search -t pattern"}
                elseif ($item -match "yum" -or "equo" -or "slackpkg" -or "apk" -or "snappy") {return $item+"search"}
                elseif ($item -match "urpmi") {return "urpmq -fuzzy"}
                elseif ($item -match "netpkg") {return $item+"list | grep"}
                elseif ($item -match "conary") {return $item+" query"}
                elseif ($item -match "Pacman") {return $item+" -S"}
                elseif ($item -match "emerge") {return $item+" --search"}
                elseif ($item -match "lin") {return "lvu search"}
                elseif ($item -match "cast") {return "gaze search"}
                elseif ($item -match "nix-env") {return "nix-env -qa"}
                else {return "xbps-query -Rs"}
            }
            elseif ($Action -match "UpSystem") {
                if ($item -match "zypper" -or "yum" -or "snappy") {return $item+" update -y"}
                elseif ($item -match "apt" -or "netpkg" -or "equo" -or "apk" ) {return $item+" upgrade -y"}
                elseif ($item -match "urpmi") {return $item+" --auto-select"}
                elseif ($item -match "slapt-get") {return $item+" --upgrade"}
                elseif ($item -match "slackpkg") {return $item+" upgrade-all"}
                elseif ($item -match "pacman") {return $item+" -Su"}
                elseif ($item -match "conary") {return $item+" updateall"}
                elseif ($item -match "emerge") {return $item+" -NuDa world"}
                elseif ($item -match "lin") {return "lunar update"}
                elseif ($item -match "cast") {return "sorcery upgrade"}
                elseif ($item -match "nix") {return "nix-env -u"}
                else {return "xbps-install -u"}
            }
            elseif ($Action -match "UpPackage") {
                if ($item -match "zypper") {return $item+" refresh -y"}
                elseif ($item -match "yum") {return $item+" check-update"}
                elseif ($item -match "apt" -or "equo" -or "apk" -or "slackpkg") {return $item+" update -y"}
                elseif ($item -match "urpmi") {return $item+".update -a"}
                elseif ($item -match "slapt-get") {return $item+" --update"}
                elseif ($item -match "pacman") {return $item+" -Sy"}
                elseif ($item -match "emerge") {return $item+" --sync"}
                elseif ($item -match "lin") {return "lin moonbase"}
                elseif ($item -match "cast") {return "scribe update"}
                elseif ($item -match "nix") {return "nix-channel --update"}
                else {return "xbps-install -u"}
            }
            else {return "Erreur - Commande inconnue ou non reférencée"}
        }
    }
}
################### Code ########################
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
                $password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
                $username = (Import-Csv $file -Delimiter ";").Username
                $credentials = New-Object System.Management.Automation.PSCredential($username,$password) 
                New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port) -Credential $credentials
                $pacman = PacMan
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
            $pacman = PacMan
            $package = Read-Host "Quel package ?"
            $Action = "Souhaitez-vous : Install | Remove | Search | UpSystem | UpPackage "
            if ($package -match " ") {
                $Action = "UpSystem"
                (Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman").Output
            }
            else {
                Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman $package"
            }
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
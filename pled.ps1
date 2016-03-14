############ Powershell Linux Easy Deploy ############
$version = "1.0"
####### Import SSH module #######
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
#################################
####### Custom Functions ########
######  Package Manager - Action Install & Remove ###### 
function PacMan {
    Param (
        [Parameter(Mandatory=$true)][ValidateSet("Install","Remove")][string]$Action
    )
    $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman -S","conary","apk add","emerge","lin","cast","niv-env -i","xpbs-install","snappy"
    if ($Action -match "Install") {
        foreach ($p in $packman) {
            if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$p").ExitStatus -notmatch "127")) {
                if ($p -match "apt-get"-or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {
                return $p+" install -y"
            }
            elseif ($p -match "slapt-get") {
                return $p+" --install -y"
            }
            else {return $p} 
            }
        }
    }
    else {
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
            $package = Read-Host "Quel package à installer ?"
            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman install -y $p").Output
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
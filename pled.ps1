############ Powershell Linux Easy Deploy ############
$version = "1.0"
####### Import SSH module #######
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
#################################
####### Custom Functions ########
function PacMan {
    $hversion = (Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "ls /etc").Output
    if ($hversion -match "os-release") {
        if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "cat /etc/os-release").Output) -match "ID=ubuntu") {"apt-get"}
        Elseif (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "cat /etc/os-release").Output) -match "centos") {"yum"}
        Elseif (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "cat /etc/os-release").Output) -match "suse") {"zipper"}
        Elseif(((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "cat /etc/os-release").Output) -match "gentoo") {"emerge"}
        #(Invoke-SSHCommand -SessionId $sid -Command "cat /etc/os-release").Output -match "slackware" {""}      
        else {"Version de linux inconnue"}
    }
    elseif ($hversion -match "arch-release") {"pacman -Syu"}
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
                $pacman = PacMan
                foreach ($p in ((Import-Csv .\Classeur1.csv -Delimiter ";").Packages)) {
                    (Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman install -y $p").Output
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
            $package = Read-Host "Quel package à installer ?"
            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$pacman install -y $p").Output
        }
        3{
            foreach ($i in (Get-SSHSession).Index) {
                Remove-SSHSession -SessionId $i
            }
            exit}
    }
}
while ($menu -notmatch "3")
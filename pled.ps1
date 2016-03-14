############ Powershell Linux Easy Deploy ############
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
}
#######       Code       ########
$file = Read-Host "Fichier d'inventaire"
foreach ($host in ((Import-Csv $file -Delimiter ";" | select -Property IP).IP)) {
    New-SSHSession -ComputerName '"'+$host+'"'
    $package = PacMan
    Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command $package ((Import-Csv $file -Delimiter ";" | select -Property Packages).Packages)
}

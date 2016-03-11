############ Powershell Linux Easy Deploy ############
####### Import SSH module #######
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
#################################
####### Custom Functions #######
function GetPackage {
    ## List available packages
}
function DeployPackage {
    ## Install package
}
function RemovePackage {
    ## Uninstall package
}
####### Code #######
$nb = Read-Host "Combien d'hôtes à déployer ?"
for ($i = 0;$i -le $nb;$i ++){
    $Uri = Read-Host "Adresse IP"
    New-SShSession -ComputerName -$Uri 
}
Get-SSHSession

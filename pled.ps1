############ Powershell Linux Easy Deploy ###############
$version = "1.2"
################### Import SSH module ###################
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")} 
Import-Module Posh-SSH 
###########################################################################
####################### Custom Functions ##################################
############### Example Inventory file - Package ##########################
## IP;Port;User;Password;Type;Name;Action
## 192.168.99.100;32768;root;$pPsd34n0;Package;vim;Install
## ;;;;;curl;Remove
## ;;;;;wget;Search
## ;;;;;java;Install
## 192.168.99.110;32769;;;;;UpSystem
### It will install Packages named vim and Java, Remove curl, Search wget on the host 192.168.99.100 (ssh port 32768)
### And make an upgrade system for 192.168.99.110
####### Action available in inventory file
## Install | Remove | Search | UpSystem (a.k.a : Update System) | UpPackage (a.k.a : Update package list)
############### Example Inventory file - Roles & Packages ##################
## IP;Port;User;Password;Type;Name;Packages;Action
## 192.168.99.100;32768;root;$pPsd34n0;Role;LEMP;Nginx
## ;;;;;;mysql
## ;;;;;;php
## 192.168.99.110;32769;root;$mlkDE46;Packages;vim;Install
### It will install LEMP role with nginx, mysql and PHP on 192.168.99.100
### It will install vim package on 192.168.99.110
###########################################################################
function PacMan {
    if (((Import-Csv $file -Delimiter ";").Type) -match "Package") {
        $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk add","emerge","lin","cast","niv-env","xpbs","snappy"
            foreach ($item in packman) {
                if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$item").ExitStatus -notmatch "127")) {
                    foreach ($p in ((Import-Csv $file -Delimiter ";").Packages)) {
                        $Action = (Import-Csv $file -Delimiter ";").Action
                        if ($Action -match "Install") {
                            if ($item -match "apt-get" -or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {return $item+" install -y "+$p}
                            elseif ($item -match "slapt-get") {return $item+" --install -y "+$p}
                            elseif ($item -match "pacman") {return $item+" -S "+$p}
                            elseif ($item -match "conary") {return $item+" update "+$p}
                            elseif ($item -match "apk") {return $item+" add "+$p}
                            elseif ($item -match "nix-env") {return $item+" -i "+$p}
                            elseif ($item -match "xpbs") {return $item+"-install "+$p}
                            else {return $item+" "+$p}
                        }
                        elseif ($Action -match "Remove") {
                            if ($item -match "apt-get"-or "zypper" -or "slackpkg" -or "equo" -or "snappy" -or "netpkg") {return $item+" remove -y "+$p}
                            elseif ($item -match "yum" -or "conary") {return $item+" erase -y "+$p}
                            elseif ($item -match "slapt-get") {return $item+" --remove -y "+$p}
                            elseif ($item -match "urpmi") {return "urpme "+$p}
                            elseif ($item -match "pacman") {return $item+" -R "+$p}
                            elseif ($item -match "apk") {return $item+" del "+$p}
                            elseif ($item -match "emerge") {return $item+" -aC "+$p}
                            elseif ($item -match "lin") {return "lrm "+$p}
                            elseif ($item -match "cast") {return "dispel "+$p}
                            elseif ($item -match "nix-env") {return $item+" -e "+$p}
                            elseif ($item -match "xpbs") {return $item+"-remove "+$p}
                            else {}
                        }
                        elseif ($Action -match "Search") {
                            if ($item -match "apt-get") {return "apt-cache "+$p}
                            elseif ($item -match "zypper") {return $item+" search -t pattern "+$p}
                            elseif ($item -match "yum" -or "equo" -or "slackpkg" -or "apk" -or "snappy") {return $item+"search "+$p}
                            elseif ($item -match "urpmi") {return "urpmq -fuzzy "+$p}
                            elseif ($item -match "netpkg") {return $item+"list | grep "+$p}
                            elseif ($item -match "conary") {return $item+" query "+$p}
                            elseif ($item -match "Pacman") {return $item+" -S "+$p}
                            elseif ($item -match "emerge") {return $item+" --search "+$p}
                            elseif ($item -match "lin") {return "lvu search "+$p}
                            elseif ($item -match "cast") {return "gaze search "+$p}
                            elseif ($item -match "nix-env") {return " -qa "+$p}
                            else {return "xbps-query -Rs "+$p}
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
                            elseif ($item -match "nix-env") {return "-u"}
                            else {return "xbps-install -u"}
                        }
                        elseif ($Action -match "UpPackage") {
                            if ($item -match "zypper") {return $item+" refresh -y "+$p}
                            elseif ($item -match "yum") {return $item+" check-update "+$p}
                            elseif ($item -match "apt" -or "equo" -or "apk" -or "slackpkg") {return $item+" update -y "+$p}
                            elseif ($item -match "urpmi") {return $item+".update -a "+$p}
                            elseif ($item -match "slapt-get") {return $item+" --update "+$p}
                            elseif ($item -match "pacman") {return $item+" -Sy "+$p}
                            elseif ($item -match "emerge") {return $item+" --sync "+$p}
                            elseif ($item -match "lin") {return "lin moonbase "+$p}
                            elseif ($item -match "cast") {return "scribe update "+$p}
                            elseif ($item -match "nix-env") {return "nix-channel --update "+$p}
                            else {return "xbps-install -u "+$p}
                        }
                        else {return "Erreur - Commande inconnue ou non reférencée"}
                    }
                }
        }
    }
    elseif (((Import-Csv $file -Delimiter ";").Type) -match "Role") {
        $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk add","emerge","lin","cast","niv-env","xpbs","snappy"
        foreach ($item in $packman) {
            if (((Invoke-SSHCommand -SessionId((Get-SSHSession).SessionId) -Command "$item").ExitStatus -notmatch "127")) {
                foreach ($p in ((Import-Csv $file -Delimiter ";").Packages)) {
                    if ($item -match "apt-get" -or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {return $item+" install -y"+$p}
                    elseif ($item -match "slapt-get") {return $item+" --install -y"+$p}
                    elseif ($item -match "pacman") {return $item+" -S"+$p}
                    elseif ($item -match "conary") {return $item+" update"+$p}
                    elseif ($item -match "apk") {return $item+" add"+$p}
                    elseif ($item -match "nix-env") {return $item+" -i"+$p}
                    elseif ($item -match "xpbs") {return $item+"-install"+$p}
                    else {return $item+" "+$p}
                }
            }
        }
    }
    elseif (((Import-Csv $file -Delimiter ";").Type) -match "Docker") {
        if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker").ExitStatus -notmatch "127")) {          
            $Action = (Import-Csv $file -Delimiter ";").Action
            if ($Action -match "Deploy"){
                $Image = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").Image)){}else{((Import-Csv $file -Delimiter ";").Image)} 
                $Mode = if (((Import-Csv $file -Delimiter ";").Mode) -match "daemon"){"-dit"}else{"-a=['STDIN'] -a=['STDOUT'] -a=['STDERR']"}
                $CName = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").CName)){}else{"--name "+((Import-Csv $file -Delimiter ";").CName)}
                $Network = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").Network)){}else{"--net="+'"'+((Import-Csv $file -Delimiter ";").Network)+'"'}
                $AddHost = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").AddHost)){}else{"--add-hosts "+((Import-Csv $file -Delimiter ";").AddHost)}
                $DNS = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").DNS)){}else{"--dns=["+((Import-Csv $file -Delimiter ";").DNS)+']'}
                $Restart = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").RestartPolicies)){}else{"--restart="+((Import-Csv $file -Delimiter ";").RestartPolicies)}
                $EnPoint = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").EntryPoint)){}else{"--entrypoint="+((Import-Csv $file -Delimiter ";").EntryPoint)}
                $CMD = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").CMD)){}else{"--restart="+((Import-Csv $file -Delimiter ";").CMD)}
                $PExpose =  if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").PortsExpose)){}else{"--expose=["+((Import-Csv $file -Delimiter ";").PortsExpose)+']'}
                $PPublish = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").PortsPublish)){}else{"-P=["+((Import-Csv $file -Delimiter ";").PortsPublish)+']'}
                $Volume = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").Volumes)){}else{"-v "+((Import-Csv $file -Delimiter ";").Volumes)}
                $Link = if ([string]::IsNullOrWhiteSpace((Import-Csv $file -Delimiter ";").Links)){}else{"--link "+((Import-Csv $file -Delimiter ";").Links)}
                Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker run" $Restart $Mode $PExpose $PPublish $AddHost $Network $DNS $CName $Link $Volume $EnPoint $Image $CMD
            }
            if ($Action -match "Build") {
                Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "Docker Build -t "+((Import-Csv $file -Delimiter ";").IName)+" ."
            }
            if ($Action -match "Stop") {
                Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker stop "+((Import-Csv $file -Delimiter ";").CId)
            }
            if ($Action -match "Remove") {
                Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker rm "+((Import-Csv $file -Delimiter ";").CId)
            }
        }
        else {(Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "curl -sSL https://get.docker.com/ | sh")}
    }
    else {}
}
################### Code ########################
Write-Host "Powershell Linux Easy Deploy $version"
$file = Read-Host "Fichier d'inventaire"
foreach ($i in ((Import-Csv $file -Delimiter ";" | select -Property IP).IP)) {
    $password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
    $username = (Import-Csv $file -Delimiter ";").Username
    $credentials = New-Object System.Management.Automation.PSCredential($username,$password) 
    New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port) -Credential $credentials
    PacMan
}
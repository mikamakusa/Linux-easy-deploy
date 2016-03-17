Add-Type -AssemblyName System.IO.Compression.FileSystem
$version = "1.3"
## Import SSH Module
if (Get-Command | Where {$_.Name -notmatch "New-SShSession"}){
    iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
} 
Import-Module Posh-SSH 
## Import predefined functions
function Install-MSIFile {
    [CmdletBinding()]
    Param(
        [parameter(mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][ValidateNotNullorEmpty()][string]$msiFile,
        [parameter()][ValidateNotNullorEmpty()][string]$targetDir
        )
    if (!(Test-Path $msiFile)){
        throw "Path to the MSI File $($msiFile) is invalid. Please supply a valid MSI file"
    }
    $arguments = @(
        "/i"
        "`"$msiFile`""
        "/qn"
        "/norestart"
    )
    if ($targetDir){
        if (!(Test-Path $targetDir)){
            throw "Path to the Installation Directory $($targetDir) is invalid. Please supply a valid installation directory"
        }
        $arguments += "INSTALLDIR=`"$targetDir`""
    }
    Write-Verbose "Installing $msiFile....."
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -eq 0){
        Write-Verbose "$msiFile has been successfully installed"
    }
    else {
        Write-Verbose "installer exit code  $($process.ExitCode) for file  $($msifile)"
    }
}
function Unzip {
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
## Custom functions
function Check_AWS_tools{
    if (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2012") -or (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2008") -and (($Host).Version).Major -match "5")) {
        if ((Get-Command -ListAvailable) -notmatch "AWSPowerShell") {
            Invoke-WebRequest -Uri "http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi" -Outfile "c:\AWSToolsAndSDKForNet.msi"
            Install-MSIFile "c:\AWSToolsAndSDKForNet.msi"
            Remove-Item "c:\AWSToolsAndSDKForNet.msi"
        }
    }
    else {
        if ((Get-ChildItem "C:\Windows\System32\") -notmatch "ec2-api-tools") {
            Invoke-WebRequest -Uri "http://www.amazon.com/gp/redirect.html/ref=aws_rc_ec2tools?location=http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip&token=A80325AA4DAB186C80828ED5138633E3F49160D9" -Outfile "c:\ec2-api-tools.zip"
            if ((($Host).Version).Major -match "5") {
                Expand-Archive -Path "c:\ec2-api-tools.zip" -DestinationPath "C:\Windows\System32\ec2-api-tools"
            }
            else {
                Unzip -zipfile "c:\ec2-api-tools.zip" -outpath"C:\Windows\System32\ec2-api-tools"
            }
        }
    }
}
function Get-ImageId {
    if (((Import-Csv $file -Delimiter ";").Name) -match "AWS") {
        $Image = ((Import-Csv $file -Delimiter ";").Image)
        if ($Image -match "Amazon") {return "ami-d22932be"}
        elseif ($Image -match "Red Hat") {return "ami-875042eb"}
        elseif ($Image -match "Suse") {return "ami-875042eb"}
        elseif ($Image -match "Ubuntu") {return "ami-87564feb"}
        elseif ($Image -match "Windows 2012") {return "ami-1135d17e"}
        elseif ($Image -match "Windows 2008") {return "ami-e135d18e"}
        else {}
    }
    Elseif if (((Import-Csv $file -Delimiter ";").Name) -match "DigitalOcean") {
        $Image = ((Import-Csv $file -Delimiter ";").Image)
        if ($Image -match "Debian") {return "15611095"}
        elseif ($Image -match "Ubuntu") {return "15621816"}
        elseif ($Image -match "CentOS") {return "16040476"}
        elseif ($Image -match "Fedora") {return "14238961"}
        elseif ($Image -match "FreeBSD") {return "13321858"}
        else {}
    }
}
Get-DORegions {
    $Region = ((Import-Csv $file -Delimiter ";").Region)
        if ($Region -match "New York") {return "nyc1"}
        elseif ($Region -match "Amsterdam") {return "ams1"}
        elseif ($Region -match "San Francisco") {return "sfo1"}
        elseif ($Region -match "Singapore") {return "sgp1"}
        elseif ($Region -match "London") {return "lon1"}
        else {}
}
Get-DOSize {
    $Size = ((Import-Csv $file -Delimiter ";").Size)
        if ($Size -match "small") {return "512mb"}
        elseif ($Size -match "medium") {return "1gb"}
        elseif ($Size -match "large") {return "2gb"}
        elseif ($Size -match "xl") {return "4gb"}
        elseif ($Size -match "xxl") {return "8gb"}
        else {}
}
function PacMan {
    if (((Import-Csv $file -Delimiter ";").Type) -match "Host") {
            foreach ($i in (Import-Csv -Delimiter ";").Name) {
                $username = (Import-Csv -Delimiter ";").Username
                $password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
                $credentials = New-Object System.Management.Automation.PSCredential($username,$password)
                New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port) -Credential $credentials
                if ((Import-Csv $file -Delimiter ";") -match "Package") {
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
                elseif ((Import-Csv $file -Delimiter ";") -match "Docker") {
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
            }
        }
    elseif (((Import-Csv $file -Delimiter ";").Type) -match "Provider") {
        if (((Import-Csv $file -Delimiter ";").Name) -match "AWS") {
            Check_AWS_tools
            if (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2012") -or (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2008") -and (($Host).Version).Major -match "4")) {
                foreach ($item in ((Import-Csv $file -Delimiter ";").InstanceTag)) {
                    $ImageSet = Get-ImageId
                    $AWSKey = New-EC2KeyPair -KeyName ((Import-Csv $file -Delimiter ";").Key)
                    $SGroup = New-EC2SecurityGroup -GroupName ((Import-Csv $file -Delimiter ";").SGroup)
                    New-EC2Instance -ImageId $Image -KeyName $AWSKey -SecurityGroupId $SGroup
                }
            }
            else {}
        }
        elseif (((Import-Csv $file -Delimiter ";").Name) -match "DigitalOcean"){ 
            foreach ($item in ((Import-Csv $file -Delimiter ";").Name)) {
                $Token = ((Import-Csv $file -Delimiter ";").Token)
                $Name = ((Import-Csv $file -Delimiter ";").Name)
                $ImageSet = Get-ImageId
                $RegionSet = Get-DORegions
                $SizeSet = Get-DOSize
                Invoke-WebRequest -Uri "https://api.digitalocean.com/v2/v2/droplets" -ContentType "application/json" -Method Get -Headers @{"Authorization" = "Bearer "+$Token} -Body '{"name":"'+$Name+'","region":"'+$RegionSet+'","size:"'+$SizeSet+'","image":"'+$ImageSet+'","ssh_keys":null,"backups":false,"ipv6":true,"user_data":null,"private_networking":null}'  
            }
        }
        else{}
    }
}
################### Code ########################
Write-Host "PoSH Easy Deploy $version"
$file = Read-Host "Fichier d'inventaire"
foreach ($i in ((Import-Csv $file -Delimiter ";" | select -Property IP).IP)) {
    $password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
    $username = (Import-Csv $file -Delimiter ";").Username
    $credentials = New-Object System.Management.Automation.PSCredential($username,$password) 
    New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port) -Credential $credentials
    PacMan
}
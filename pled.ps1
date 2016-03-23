Add-Type -AssemblyName System.IO.Compression.FileSystem
$version = "1.3"
## Import SSH Module
    if ((Get-Command -All) -notmatch "New-SSHSession"){
        iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
    } 
#Import-Module Posh-SSH 
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
function Check_Wget {
    if ((Get-ChildItem "c:\Windows\System32") -notmatch "wget") {
    Invoke-WebRequest -Uri "https://eternallybored.org/misc/wget/current/wget64.exe" -OutFile "c:\Windows\System32\wget64.exe"
    Rename-Item -Path "c:\Windows\System32\wget64.exe" -NewName "c:\Windows\System32\wget.exe"}
}
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
function Get-ImageId ($file){
    $Image = ((Import-Csv $file -Delimiter ";").Image)
    $Name = ((Import-Csv $file -Delimiter ";").Name)
    switch ($Name) {
        "AWS" {
            switch ($Image) {
                "Amazon" {return "ami-d22932be"}
                "Red Hat" {return "ami-875042eb"}
                "Suse" {return "ami-875042eb"}
                "Ubuntu" {return "ami-87564feb"}
                "Windows 2012" {return "ami-1135d17e"}
                "Windows 2008" {return "ami-e135d18e"}
            }
        }
        "DigitalOcean" {
            switch ($Image) {
                "Debian" {return "15611095"}
                "Ubuntu" {return "15621816"}
                "CentOS" {return "16040476"}
                "Fedora" {return "14238961"}
                "FreeBSD" {return "13321858"}
                
            }
        }
        "Cloudwatt" {
            switch ($Image) {
                "Ubuntu" {return "edffd57d-82bf-4ffe-b9e8-af22563741bf"}
                "Suse" {return "e194b52d-cf80-4b05-9be3-56a2f3ba10ff"}
                "CentOS" {return "86e61ee3-078f-405d-8eab-210174d20159"}
                "Fedora" {return "f77e7c4b-3ba6-4f1d-b1eb-69d20d5beee6"}
                "Windows 2012" {return "ed01abf8-e6a8-4dcf-b9bb-d2dd0aefd503"}
                "Windows 2008" {return "3d014779-fa19-49c8-8310-6c9a163ed934"}
            }
        }
        "Numergy" {
            switch ($Image) {
                "Ubuntu" {return "41221dc8-29e3-11e4-857f-005056992152"}
                "Debian" {return "de8ff4bc-038c-11e5-bbd3-005056992152"}
                "CentOS" {return "aadf1726-a838-11e2-816d-005056992152"}
                "Red Hat" {return "aa56ee50-a838-11e2-816d-005056992152"}
                "Windows 2008" {return "902771bc-47bf-11e4-857f-005056992152"}
                "Windows 2012" {return "59bc519c-5846-11e3-8d40-005056992152"}
            }
        }
        "ArubaCloud" {
            switch ($Image) {
                "Ubuntu" {return "125"}
                "Debian" {return "17"}
                "CentOS" {return "29"}
                "Suse" {return "105"}
                "Windows 2008" {return "30"}
            }
        }
        "Google" {
            switch ($Image) {
                "Debian" {return "projects/debian-cloud/global/images/debian-8-jessie-v20160301"}
                "CentOS" {return "projects/centos-cloud/global/images/centos-7-v2016030"}
                "Suse" {return "projects/suse-cloud/global/images/opensuse-13-2-v20160222"}
                "Ubuntu" {return "projects/ubuntu-os-cloud/global/images/ubuntu-1510-wily-v20160315"}
                "Windows 2008" {return "projects/windows-cloud/global/images/windows-server-2008-r2-dc-v20160224"}
                "Windows 2012" {return "projects/windows-cloud/global/images/windows-server-2012-r2-dc-v20160224"}
            }
        }
        "Rackspace" {
            switch ($Image) {
                "Debian" {return "a10eacf7-ac15-4225-b533-5744f1fe47c1"}
                "CentOS" {return "c195ef3b-9195-4474-b6f7-16e5bd86acd0"}
                "Suse" {return "096c55e5-39f3-48cf-a413-68d9377a3ab6"}
                "Ubuntu" {return "5cebb13a-f783-4f8c-8058-c4182c724ccd"}
                "Windows 2008" {return "b9ea8426-8f43-4224-a182-7cdb2bb897c8"}
            }
        }
        default {}
    }
}
function Get-Regions ($file) {
    $Region = ((Import-Csv $file -Delimiter ";").Region)
    $Name = ((Import-Csv $file -Delimiter ";").Name)
    switch ($Name) {
        "DigitalOcean" {
            switch ($Region) {
                "New York" {return "nyc1"}
                "Amsterdam" {return "ams2"}
                "San Francisco" {return "sfo1"}
                "Singapore" {return "sgp1"}
                "London" {return "lon1"}
            }
        }
        "ArubaCloud" {
            switch ($Region) {
                "UK" {return "dc6"}
                "Germany" {return "dc5"}
                "France" {return "dc4"}
                "Czech Republic" {return "dc3"}
                "Italy2" {return "dc2"}
                "Italy1" {return "dc1"}
            }
        }
        "Google" {
            switch ($Region) {
                "Asia" {return "asia-east1-a"}
                "Europe" {return "europe-west1-b"}
                "US" {return "us-central1-a"}
            }
        }
    }
}
function Get-Size ($file) {
    $Size = ((Import-Csv $file -Delimiter ";").Size)
    $Name = ((Import-Csv $file -Delimiter ";").Name)
    switch ($Name) {
        "DigitalOcean" {
            switch ($Size) {
                "small" {return "512mb"}
                "medium" {return "1gb"}
                "large" {return "2gb"}
                "xl" {return "4gb"}
                "xxl" {return "8gb"}
            }
        }
        "Cloudwatt" {
            switch ($Size) {
                "small" {return "21"}
                "medium" {return "22"}
                "large" {return "23"}
                "xl" {return "24"}
                "xxl" {return "30"}
            }
        }
        "Numergy" {
            switch ($Size) {
                "XS" {return "bbe1760a-30ef-11e3-8d40-005056992152"}
                "S" {return "01c25006-a5c0-11e2-816d-005056992152"}
                "S+" {return "01c250a6-a5c0-11e2-816d-005056992152"}
                "L" {return "01c24ca0-a5c0-11e2-816d-005056992152"}
                "L+" {return "01c24f52-a5c0-11e2-816d-005056992152"}
                "XL" {return "01c25132-a5c0-11e2-816d-005056992152"}
            }
        }
        "ArubaCloud" {
            switch ($Size) {
                "S" {return "1"}
                "M" {return "2"}
                "L" {return "3"}
                "XL"{return "4"}
            }
        }
        "Google" {
            $Region = ((Import-Csv $file -Delimiter ";").Region)
            $Project = ((Import-Csv $file -Delimiter ";").Project)
            switch ($Region) {
                "asia-east1-a" {return "https://content.googleapis.com/compute/v1/projects/$Project/zones/asia-east1-a/machineTypes/f1-micro"}
                "europe-west1-b" {return "https://content.googleapis.com/compute/v1/projects/$Project/zones/europe-west1-b/machineTypes/f1-micro"}
                "us-central1-a" {return "https://content.googleapis.com/compute/v1/projects/$Project/zones/us-central1-a/machineTypes/f1-micro"}
            }
        }
        "Rackspace" {
            switch ($Size) {
                "small" {return "3"}
                "medium" {return "4"}
                "large" {return "5"}
                "xl" {return "6"}
                "xxl" {return "7"}
            }
        }
        default{}
    }
}
function Get-Token ($file) {
    $Name = ((Import-Csv $file -Delimiter ";").Name)
    switch ($Name) {
        "Cloudwatt" {
            $Tenant = ((Import-Csv $file -Delimiter ";").Tenant)
            $Username = ((Import-Csv -Delimiter ";").Username)
            $Password = ((Import-Csv -Delimiter ";").Password)
            [xml]$auth = "<?xml version='1.0' encoding='UTF-8'?><auth xmlns='http://docs.openstack.org/identity/v2.0' tenantName='$Tenant'><passwordCredentials username='$Username' password='$Password'/></auth>"
            [xml]$TokenRequest = Invoke-WebRequest -Uri "https://identity.fr1.cloudwatt.com/v2.0/tokens" -ContentType "application/json" -Method Post -Headers @{"Accept" = "application/json"} -Body $auth
            $Token = $TokenRequest.access.token.id
        }
        "Numergy" {
            $TenantId = ((Import-Csv $file -Delimiter ";").TenantId)
            $Accesskey = ((Import-Csv -Delimiter ";").AccessKey)
            $SecretKey = ((Import-Csv -Delimiter ";").SecretKey)
            $Nversion = ((Invoke-WebRequest -Uri "https://api2.numergy.com/" -ContentType "application/json; charset=utf-8" -Method Get | ConvertFrom-Json).versions | select -Property id,status -Last 1).id
            $Tbody = '{"auth": {"apiAccessKeyCredentials": {"accessKey": "'+$AccessKey+'","secretKey": "'+$SecretKey+'" },"tenantId": "'+$tenantId+'" } }'
            $Token = (((((Invoke-WebRequest -Uri "https://api2.numergy.com/V3.0/tokens" -ContentType "application/json; charset=utf-8" -Method Post -Body $TBody) | ConvertFrom-Json).access).token).id)
        }
        "OVH" {
            $AppKey = ((Import-Csv $file -Delimiter ";").ApplicationKey)
            $Uri = "https://eu.api.ovh.com/1.0/auth/credential"
            Invoke-WebRequest -Uri $Uri -ContentType "application/json" -Headers @{"X-Ovh-Application" = $AppKey} -Method Post -Body '{"accessRules":[{"method": "GET","path": "/*"}],"redirection":"https://www.mywebsite.com/"}'
        }
        "Google" {
        }
        "Rackspace" {
            $Tenant = ((Import-Csv $file -Delimiter ";").Tenant)
            $Username = ((Import-Csv -Delimiter ";").Username)
            $Password = ((Import-Csv -Delimiter ";").Password)
            $APIKey = ((Import-Csv -Delimiter ";").APIKey)
            $Token = (((((Invoke-WebRequest -Uri "https://identity.api.rackspacecloud.com/v2.0/tokens" -ContentType "application/json" -Body "'"+'{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'+$Username+'","apiKey":"'+$apiKey+'"}}}'+"'") | ConvertFrom-Json).access).token).id)
        }
        default {}
    }   
}
function Win_Role_Deploy {
    if ((Get-WMIObject -Class Win32_OperatingSystem).Caption -match "Windows 2008") {return "Add-WindowsFeature"}
    else {return "Install-WindowsFeature"}
}
function xml-commandv4 ($header, $body) {
    $location = (Get-Location).Path
    $filePath = "$location\command.xml"
    $xmlwriter = New-Object System.XMl.XmlTextWriter($filepath,$Null)
    $xmlwriter.WriteRaw("$header")
    $XmlWriter.WriteRaw("$Body")
    $XmlWriter.WriteRaw("</soapenv:Envelope>")
    $xmlWriter.Finalize
    $xmlWriter.Close()
}
function ArubaAPI ($command, $result, $dc, $apiversion, $instruction) {
    if ((Get-ChildItem "c:\Windows\System32") -notmatch "wget") {
        wget.exe -O $result -q --post-file=$command --header "SOAPAction: https://api.computing.cloud.it/WsEndUser/IWsEndUser/$instruction" --header "Content-Type: text/xml;charset=UTF-8" --no-check-certificate https://api.$dc.computing.cloud.it/WsEndUser/$apiversion/WsEndUser.svc/soap11
    }
}
## Main function
function PacMan {
    $Type = ((Import-Csv $file -Delimiter ";").Type)
    switch ($Type) {
        "Host" {
            $OS = ((Import-Csv $file -Delimiter ";").OS)
            switch ($OS) {
                "linux" {
                    foreach ($i in (Import-Csv $file -Delimiter ";").Name) {
                        $username = (Import-Csv $file -Delimiter ";").Username
                        $password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
                        $credentials = New-Object System.Management.Automation.PSCredential($username,$password)
                        New-SSHSession -ComputerName $i -Port ((Import-Csv $file -Delimiter ";").Port) -Credential $credentials
                        $Part = ((Import-Csv $file -Delimiter ";").Part)
                        switch ($Part) {
                            "Package" {
                                $packman = "apt-get","zypper","yum","urpmi","slackpkg","slapt-get","netpkg","equo","pacman","conary","apk add","emerge","lin","cast","niv-env","xpbs","snappy"
                                foreach ($item in $packman) {
                                    if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "$item").ExitStatus -notmatch "127")) {
                                        foreach ($p in ((Import-Csv $file -Delimiter ";").Packages)) {
                                            $Action = (Import-Csv $file -Delimiter ";").Action
                                            switch ($Action) {
                                                "Install" {
                                                    if ($item -match "apt-get" -or "zypper" -or "yum" -or "slackpkg" -or "equo" -or "snappy") {return $item+" install -y "+$p}
                                                    elseif ($item -match "slapt-get") {return $item+" --install -y "+$p}
                                                    elseif ($item -match "pacman") {return $item+" -S "+$p}
                                                    elseif ($item -match "conary") {return $item+" update "+$p}
                                                    elseif ($item -match "apk") {return $item+" add "+$p}
                                                    elseif ($item -match "nix-env") {return $item+" -i "+$p}
                                                    elseif ($item -match "xpbs") {return $item+"-install "+$p}
                                                    else {return $item+" "+$p}
                                                }
                                                "Remove" {
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
                                                "Search" {
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
                                                "UpSystem" {
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
                                                "UpPackage" {
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
                                                default {return "Erreur - Commande inconnue ou non reférencée"}
                                            }
                                        }
                                    }
                                }
                            }
                            "Docker" {
                                if (((Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker").ExitStatus -notmatch "127")) {          
                                    $Action = (Import-Csv $file -Delimiter ";").Action
                                    switch ($Action) {
                                        "Deploy"{
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
                                        "Build" {
                                            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "Docker Build -t "+((Import-Csv $file -Delimiter ";").IName)+" ."
                                        }
                                        "Stop" {
                                            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker stop "+((Import-Csv $file -Delimiter ";").CId)
                                        }
                                        "Remove" {
                                            Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "docker rm "+((Import-Csv $file -Delimiter ";").CId)
                                        }
                                    }
                                }
                                else {(Invoke-SSHCommand -SessionId ((Get-SSHSession).SessionId) -Command "curl -sSL https://get.docker.com/ | sh")}
                            }
                            #"Firewall" {}
                            default {}
                        }
                    }
                }
                "Windows" {
                    foreach ($i in (Import-Csv $file -Delimiter ";").Name) {
                        $Username = (Import-Csv $file -Delimiter ";").Username
                        $Password = ConvertTo-SecureString ((Import-Csv $file -Delimiter ";").Password) -AsPlainText -Force
                        $credentials = New-Object System.Management.Automation.PSCredential($Username,$Password)
                        EnterPSSession -ComputerName $i -Credentials $credentials
                        $Part = ((Import-Csv $file -Delimiter ";").Part)
                        switch ($Part) {
                            "Roles" {
                                $Role = ((Import-Csv $file -Delimiter ";").Role)
                                $Install = Win_Role_Deploy
                                switch ($Role) {
                                    "Domain" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name AD-domain-Services -IncludeAllSubFeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Certificate" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name AD-Certificate -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Federation" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name AD-Federation-Services -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Application Server" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name Application-Server -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Network" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name NPAS -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Print" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name Print-Services -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Remote" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name Remote-Desktop-Services -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Deployment" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name WDS -IncludeAllSubfeatures -IncludeManagementTools"
                                        }
                                    }
                                    "Web Server" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
                                        }
                                    }
                                    default {}
                                }
                            }
                            "Softwares" {
                                $SName = ((Import-Csv $file -Delimiter ";").SName)
                                switch ($SName) {
                                    "Exchange" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            Import-Module ServerManager
                                            "$Install Desktop-Experience, NET-Framework, NET-HTTP-Activation, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Web-Server, WAS-Process-Model, Web-Asp-Net, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI"
                                            "Shutdown -r -t 0" 
                                        }
                                    }
                                    "Sharepoint" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "Import-Module ServerManager"
                                            "$Install -Name Application-Server,Web-Server -IncludeAllSubFeatures -IncludeManagementTools"
                                            "Shutdown -r -t 0"
                                        }
                                    }
                                    "Skype" {
                                        Invoke-Command -Session $i -ScriptBlock {
                                            "$Install NET-Framework-Core, RSAT-ADDS, Windows-Identity-Foundation, Web-Server, Web-Static-Content, Web-Default-Doc, Web-Http-Errors, Web-Dir-Browsing, Web-Asp-Net, Web-Net-Ext, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Http-Logging, Web-Log-Libraries, Web-Request-Monitor, Web-Http-Tracing, Web-Basic-Auth, Web-Windows-Auth, Web-Client-Auth, Web-Filtering, Web-Stat-Compression, Web-Dyn-Compression, NET-WCF-HTTP-Activation45, Web-Asp-Net45, Web-Mgmt-Tools, Web-Scripting-Tools, Web-Mgmt-Compat, Server-Media-Foundation, BITS"
                                            "shutdown -r -t 0"
                                        }
                                    }
                                }
                            }
                            "Containers" {
                                if ((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2016") {
                                    Install-PackageProvider ContainerProvider -Force
                                    if ((Find-ContainerImage) -notmatch "NanoServer" -or "WindowsServerCore") {
                                        Install-ContainerImage -Name NanoServer
                                        Install-ContainerImage -Name WindowsServerCore
                                    }
                                    if ((Get-NetIPConfiguration).Name -notmatch "Virtual Switch") {
                                        New-VMSwitch -Name "Virtual Switch" -SwitchType NAT -NATSubnetAddress 172.16.0.0/12
                                        New-NetNat -Name ContainerNat -InternalIPInterfaceAddressPrefix "172.16.0.0/12"
                                    }
                                    foreach ($item in ((Import-Csv $file -Delimiter ";").CName)) {
                                        $CName = ((Import-Csv $file -Delimiter ";").CName)
                                        $CImage = ((Import-Csv $file -Delimiter ";").CImage)
                                        New-Container -Name $CName -ContainerImageName $CImage -SwitchName "Virtual Switch"
                                        Start-Container -Name $Cname
                                    }
                                }
                                else {return "Feature unavailable"}
                            }
                            "Firewall" {}
                            default {}
                        }
                    }
                }
            }
        }
        "Provider" {
            $Name = ((Import-Csv $file -Delimiter ";").Name)
            switch ($Name) {
                "AWS" {
                    Check_AWS_tools
                    if (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2012") -or (((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 2008") -and (($Host).Version).Major -match "4")) {
                        foreach ($item in ((Import-Csv $file -Delimiter ";").InstanceTag)) {
                            $ImageSet = Get-ImageId -file $file
                            $AWSKey = New-EC2KeyPair -KeyName ((Import-Csv $file -Delimiter ";").Key)
                            $SGroup = New-EC2SecurityGroup -GroupName ((Import-Csv $file -Delimiter ";").SGroup)
                            New-EC2Instance -ImageId $Image -KeyName $AWSKey -SecurityGroupId $SGroup
                        }
                    }
                    else {
                        $KeyPair = ((Import-Csv $file -Delimiter ";").Key)
                        $SGroup = ((Import-Csv $file -Delimiter ";").SGroup)
                        aws ec2 create-key-pair --key-name $KeyPair --query 'KeyMaterial' --output text > c:\MyKeyPair.pem
                        aws ec2 create-security-group --group-name $SGroup --description "My security group"
                        foreach ($item in ((Import-Csv $file -Delimiter ";").InstanceTag)) {
                            $ImageSet = Get-ImageId -file $file
                            aws ec2 run-instances --image-id $ImageSet --count 1 --instance-type t1.micro --key-name $KeyPair --security-groups $SGroup
                        }
                    }
                }
                "DigitalOcean" { 
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $Token = ((Import-Csv $file -Delimiter ";").Token)
                        $VMName = ((Import-Csv $file -Delimiter ";").VMName)
                        $ImageSet = Get-ImageId -file $file;$RegionSet = Get-Regions -file $file;$SizeSet = Get-Size -file $file
                        $body = '{
                          "name": "'+$VMName+'",
                          "region": "'+$RegionSet+'",
                          "size": "'+$SizeSet+'",
                          "image": "'+$ImageSet+'",
                          "ssh_keys": null,
                          "backups": false,
                          "ipv6": true,
                          "user_data": null,
                          "private_networking": null
                        }'
                        Invoke-WebRequest -Uri https://api.digitalocean.com/v2/droplets -Method POST -Headers @{"Content-Type" = "application/json";"Authorization" = "Bearer $Token"} -Body $body  
                    }
                }
                "Cloudwatt" {
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $TokenSet = Get-Token -file $file; $ImageSet = Get-ImageId -file $file; $SizeSet = Get-Size -file $file;$VMName = ((Import-Csv $file -Delimiter ";").VMName);$Tenant = ((Import-Csv $file -Delimiter ";").Tenant)
                        [xml]$InsCreate = "<?xml version='1.0' encoding='UTF-8'?><server xmlns='http://docs.openstack.org/compute/api/v1.1' imageRef='$ImageSet' flavorRef='$SizeSet' name='$VMName'></server>" 
                        Invoke-WebRequest -Uri "https://compute.fr1.cloudwatt.com/v2/$Tenant/servers" -Method Post -ContentType "application/json" -Headers @{"Accept" = "application/json";"X-Auth-Token"= "$Token"}
                        $ServerId = ((Invoke-WebRequest -Uri "https://compute.fr1.cloudwatt.com/v2/$Tenant/servers" -Method Post -ContentType "application/json" -Headers @{"Accept" = "application/json";"X-Auth-Token"= "$Token"} -Body $InsCreate | ConvertFrom-Json).server).id
                        $NetId = ((((Invoke-WebRequest -Uri "https://network.fr1.cloudwatt.com/v2/networks" -ContentType "application/json" -Method GET -Headers @{"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'}) | ConvertFrom-Json).networks).id | where {$_.name -match "public"})
                        $IP = (((Invoke-WebRequest -Uri "https://network.fr1.cloudwatt.com/v2/floatingips" -ContentType "application/json" -Method Post -Headers @{"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body "'"+"{"+"floatingip"+':'+'{'+'"'+"floating_network_id"+'"'+':'+'"'+$NetId+'"}}'+"'" | ConvertFrom-Json).floatingip).floating_ip_address)
                        Invoke-WebRequest -Uri https://compute.fr1.cloudwatt.com/v2/$Tenant/servers/$ServerId/action -Method Post -Headers @{"ContentType" = "application/json" ;"Accept" = "application/json";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body "'{"+'addFloatingIp":{"address":"'+$IP+'"}}'+"'"
                    }      
                }
                "Numergy" {
                    $Nversion = ((Invoke-WebRequest -Uri "https://api2.numergy.com/" -ContentType "application/json; charset=utf-8" -Method Get | ConvertFrom-Json).versions | select -Property id,status -Last 1).id
                    $TokenSet = Get-Token;$TenantID = ((Import-Csv $file -Delimiter ";").Tenant)
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $Uri = https://api2.numergy.com/$Nversion/$TenantID/servers
                        $ImageSet = Get-ImageId -file $file;$SizeSet = Get-Size -file $file;$Name = ((Import-Csv $file -Delimiter ";").VMName)
                        $Body = '{"server": {"flavorRef": "'+$SizeSet+'","imageRef": "'+$ImageSet+'","name": "'+$VMName+'"}}'
                        Invoke-WebRequest -Uri https://api2.numergy.com/$Nversion/$TenantID/servers -Method Post -Headers @{"ContentType" = "application/json; charset=utf-8";"X-Auth-Token" = '"'+$TokenSet+'"'} -Body $Body
                    }
                }
                ### Tested but not ok ###
                "Arubacloud" {
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $apiversion = "v2.8"
                        $Username = ((Import-Csv $file -Delimiter ";").Username);$Password = ((Import-Csv $file -Delimiter ";").Password)
                        $AdminPass = ((Import-Csv $file -Delimiter ";").AdminPass);$dcx = Get-Regions -file $file;$ImageSet = Get-ImageId -file $file;$SizeSet = Get-Size -file $file;$VMName = ((Import-Csv $file -Delimiter ";").VMName)
                        if ((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 7") {
                            $SOAPHeader = "<soap:Envelope xmlns:arub='http://schemas.datacontract.org/2004/07/Aruba.Cloud.Provisioning.Entities' xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:wsen='https://api.computing.cloud.it/WsEndUser'>
                                <soap:Header>
                                        <wsse:Security soap:mustUnderstand='true' xmlns:wsse='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' xmlns:wsu='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'><wsse:UsernameToken wsu:Id='UsernameToken-D73AFF2E1B956DC7A7145854908826214'>
                                        <wsse:Username>$Username</wsse:Username>
                                        <wsse:Password Type='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText'>$Password</wsse:Password>
                                        <wsse:Nonce EncodingType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary'>8vRx/zg0wCriFAUUPLcYdw==</wsse:Nonce>
                                        <wsu:Created>2016-03-21T08:31:28.262Z</wsu:Created>
                                    </wsse:UsernameToken>
                                </wsse:Security>
                            </soap:Header>
                            "
                            $BodyCreation = "<soap:Body>
                                <wsen:SetEnqueueServerCreation>
                                <wsen:server>
                                <arub:AdministratorPassword>$AdminPass</arub:AdministratorPassword>
                                <arub:Name>$VMName</arub:Name>
                                <arub:OSTemplateId>$ImageSet</arub:OSTemplateId>
                                <arub:SmartVMWarePackageID>$SizeSet</arub:SmartVMWarePackageID>
                                </wsen:server>
                                </wsen:SetEnqueueServerCreation>
                            </soap:Body>
                            "
                            $headers = @{"SOAPAction" = "https://api.computing.cloud.it/WsEndUser/IWsEndUser/SetEnqueueServerCreation"}
                            $instruction = "SetEnqueueServerCreation"
                            xml-commandv4 -header $SOAPHeader -body $BodyCreation | ArubaAPI -command command.xml -result result.xml -dc $dcx -apiversion $apiversion -instruction $instruction
                        }
                        else {
                            [xml]$SOAPBody = "<soap:Envelope xmlns:arub='http://schemas.datacontract.org/2004/07/Aruba.Cloud.Provisioning.Entities' xmlns:soap='http://www.w3.org/2003/05/soap-envelope' xmlns:wsen='https://api.computing.cloud.it/WsEndUser'><soap:Header><wsse:Security soap:mustUnderstand='true' xmlns:wsse='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' xmlns:wsu='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'><wsse:UsernameToken wsu:Id='UsernameToken-D73AFF2E1B956DC7A7145854908826214'><wsse:Username>$Username</wsse:Username><wsse:Password Type='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText'>$Password</wsse:Password><wsse:Nonce EncodingType='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary'>8vRx/zg0wCriFAUUPLcYdw==</wsse:Nonce><wsu:Created>2016-03-21T08:31:28.262Z</wsu:Created></wsse:UsernameToken></wsse:Security></soap:Header><soap:Body><wsen:SetEnqueueServerCreation><wsen:server><arub:AdministratorPassword>$AdminPass</arub:AdministratorPassword><arub:Name>$VMName</arub:Name><arub:OSTemplateId>$ImageSet</arub:OSTemplateId><arub:SmartVMWarePackageID>$SizeSet</arub:SmartVMWarePackageID></wsen:server></wsen:SetEnqueueServerCreation></soap:Body>"
                            $headers = @{"SOAPAction" = "https://api.computing.cloud.it/WsEndUser/IWsEndUser/SetEnqueueServerCreation"}
                            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
                            Invoke-WebRequest -Uri https://api.$dcx.computing.cloud.it/WsEndUser/$apiversion/WsEndUser.svc/soap11 -Method Post -ContentType "text/xml; charset=utf-8" -headers $headers -Body $SOAPBody
                        }
                    }
                }
                ### Tested but not ok ###
                "Google" {
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $Zone = Get-Regions -file $file;$ImageSet=Get-ImageId -file $file;$VMName = ((Import-Csv $file -Delimiter ";").VMName);$Project = ((Import-Csv $file -Delimiter ";").Project)
                        $SizeSet = Get-Size -file $file;$Key = ((Import-Csv $file -Delimiter ";").Key)
                        $headers = "@{'Content-Type': 'application/x-www-form-urlencoded'}"
                        $Body = '{
                                "name": "'+$VMName+'",
                                "machineType": "'+$SizeSet+'",
                                "networkInterfaces": 
                                    [{"accessConfigs": 
                                        [{"type": "ONE_TO_ONE_NAT","name": "External NAT"}],
                                    "network": "global/networks/default"}],
                                    "disks": 
                                    [{"autoDelete": "true",
                                        "boot": "true",
                                        "type": "PERSISTENT",
                                        "initializeParams": 
                                        {"sourceImage": "'+$Image+'"}
                                    }]
                                }'
                        Invoke-WebRequest -Uri https://www.googleapis.com/compute/v1/projects/$Project/zones/$Zone/instances?key=$Key -Method POST -Headers @{"ContentType" = "application/json";"Content-Type" = "application/x-www-form-urlencoded"} -body $Body
                    }
                }
                "Rackspace" {
                    foreach ($item in ((Import-Csv $file -Delimiter ";").VMName)) {
                        $ImageSet = Get-ImageId -file $file;$VMName = ((Import-Csv $file -Delimiter ";").VMName);$SizeSet = Get-Size -file $file;$TokenSet = Get-Token -file $file
                        $Tenant = ((Import-Csv $file -Delimiter ";").Tenant);$Username = ((Import-Csv -Delimiter ";").Username);$Password = ((Import-Csv -Delimiter ";").Password)
                        $APIKey = ((Import-Csv -Delimiter ";").APIKey)
                        $Body = '{
                            "server": {
                                "name": "'+$Name+'",
                                "imageRef": "'+$ImageSet+'", 
                                "flavorRef": "'+$sizeSet+'"
                                }
                            }'
                        Invoke-WebRequest -Uri https://servers.api.rackspacecloud.com/v1.0/010101/v2/$Tenant/servers -Method Post -Headers @{"ContentType" = "application/json";"X-Auth-Token" = $TokenSet;"X-Auth-Project-Id" = $VMName} -Body $Body 
                    }
                }
                default{}
            }
        }
    }
}
################### Code ########################
Write-Host "PoSH Easy Deploy $version"
$file = Read-Host "Fichier d'inventaire"
PacMan 
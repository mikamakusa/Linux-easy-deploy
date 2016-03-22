# Linux-easy-deploy
Deploy Packages/Roles/Docker containers on linux distributions with Powershell

# v1.3

## Deployment on Windows Server (2008 R2 - 2012 R2 - 2016) - Linux - Cloud Providers  
Linux distributions supported : Ubuntu, Debian, CentOS/Fedora/Red Hat, Suse, Mandriva, Slackware, Vector, Zenwalk, Sabayon, ArchLinux, rPath/Foresight, Alpine, Gentoo, Lunar, Source Mage, NixOS, Void  
Cloud Providers supported : ArubaCloud, CloudWatt, Numergy, Amazon WebServices, Digital Ocean, Google Compute Engine  

## Keywords needed
- **Type** : Host | Provider  
- **Type** \ **Host** : OS (Linux | Windows)  
- **Type** \ **Host** \ **OS** \ Linux** (Package | Docker | Firewall (wip)) - **Type \ Host \ Os \ Windows** (Roles | Softwares | Containers (only for Windows 2016) | Firewall)  
- **Type** \ **Host** \ **OS** \ **Linux** \ **Package** (**Action** : Install | Remove | Search | UpSystem | UpPackage) 
- **Type** \ **Host** \ **OS** \ **Linux** \ **Docker** (**Action** : Deploy | Build | Stop | Remove)  
- **Type** \ **Host** \ **Os** \ **Windows** \ **Part** (Roles | Software | Containers | Firewall)  
- **Type** \ **Host** \ **Os** \ **Windows** \ **Part** \ **Roles** (Domain | Certificate | Federation | Application Server | Network | Print | Remote | Deployment | Web Server)    
- **Type** \ **Host** \ **Os** \ **Windows** \ **Part** \ **Softwares** (Exchange | Sharepoint | Skype)  
- **Type** \ **Host** \ **Os** \ **Windows** \ **Part** \ **Containers** (Fore Windows 2016)
- **Type** \ **Host** \ **Os** \ **Windows** \ **Part** \ **Firewall** (WIP)
- **Type** \ **Provider** (PName)
- **Type** \ **Provider** \ **PName** (AWS | Digital Ocean | Cloudwatt | Numergy | Arubacloud | Google | Rackspace)

## Common keywords
Providers : Image | Name | Region | Size | Tenant | TenantId | AccessKey | SecretKey | Username | Password | Nversion

## Inventory file example - Packages(*.csv)

  IP;Port;User;Password;Type;Name;Action  
  192.168.99.100;32768;root;$pPsd34n0;Package;vim;Install  
  ;;;;;curl;Remove  
  ;;;;;wget;Search  
  ;;;;;java;Install  
  192.168.99.110;32769;root;$p#ez01as;Package;;UpSystem  

## Result
Connect to 192.168.99.100 / Port 32768 with username and password  
Check the Package Manager and install vim and Java, Remove curl, Search wget  
Connect to 192.168.99.10 / Port 32769 with username and password  
Check the Package Manager and do a System Upgrade  

## Inventory file example - Docker  
  IP;Port;User;Password;Type;Image;Mode;Cname;Network;AddHost;DNS;RestartPolicies;EntryPoint;CMD;PortsExpose;PortPublish;Volume;Link  
  192.168.99.100;32768;root;$pPsd34n0;Docker;ubuntu;daemon;test;;;;;;;80;;;  
  
  It will launch the following command : docker run -dit --expose=[80] --name test ubuntu  

##Inventory file example - Providers
    
    Type;Token;PName;Image;Region;Size
    Provider;zadzadzazafzgtjkukli:fjd,,h,;Digital Ocean;Ubuntu;Amsterdam;small

## How it works ?
Launch the script, enter the inventory file...and let's play !

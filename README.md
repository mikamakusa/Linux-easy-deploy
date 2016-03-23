# Linux-easy-deploy - 

Deploy : 

- Packages and Docker Container on Linux distributions
- Roles and services on Windows Server (And Windows Containers for Windows 2016)
- Cloud Instances on Cloud Providers Platforms) 

# v1.3

## Deployment on Windows Server (2008 R2 - 2012 R2 - 2016) - Linux - Cloud Providers  
Linux distributions supported : Ubuntu, Debian, CentOS/Fedora/Red Hat, Suse, Mandriva, Slackware, Vector, Zenwalk, Sabayon, ArchLinux, rPath/Foresight, Alpine, Gentoo, Lunar, Source Mage, NixOS, Void  
Cloud Providers supported : ArubaCloud, CloudWatt, Numergy, Amazon WebServices, Digital Ocean, Google Compute Engine  

## Keywords needed
- **Type** : Host | Provider  
- **Host** : OS (Linux | Windows)    
- **OS** : **Linux** (Package | Docker | Firewall (wip))     
- **Linux** : **Package** \ **Action** (Install | Remove | Search | UpSystem | UpPackage)  
- **Linux** : **Docker** \ **Action** (Deploy | Build | Stop | Remove)
- **Os** : **Windows** \ **Part** (Roles | Software | Containers | Firewall)    
- **Part** : **Roles** (Domain | Certificate | Federation | Application Server | Network | Print | Remote | Deployment | Web Server)      
- **Part** : **Softwares** (Exchange | Sharepoint | Skype)  
- **Part** : **Containers** (Fore Windows 2016)  
- **Part** : **Firewall** (WIP)  
- **Type** : **Provider** (Name)  
- **Provider** : **Name** (AWS | DigitalOcean | Cloudwatt | Numergy | Arubacloud | Google | Rackspace)  
For AWS  
- **InstanceTag** | **Image** | **Key** | **SGroup**  
For DigitalOcean  
- **VMName** | **Image** | **Region** | **Size**  
For Cloudwatt  
- **Token** | **Tenant** | **VMName** | **Image** | **Size**  
For Numergy  
- **Token** | **Tenant** | **VMName** | **Image** | **Size**  
For ArubaCloud  
- **Username** | **Password** | **VMName** | **AdminPass** | **Region** | **Image** | **Size**  
For Google  
- **Key** | **VMName** | **Image** | **Region** | **Size** | **Project**  
For Rackspace  
- **Tenant** | **APIKey** | **VMName** | **Username** | **Password** | **Image** | **Size** | **Token** 

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
    
Type;Name;Token;Region;Image;Size;VMName
Provider;DigitalOcean;################################################################;Amsterdam;Ubuntu;small;test1

## How it works ?
Launch the script, enter the inventory file...and let's play !

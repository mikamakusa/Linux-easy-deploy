# Linux-easy-deploy - 

Deploy : 

- Packages on Linux distributions (create Firewall rules - already functionnal for simple rules but work in progress)


# v1

## Deployment on Windows Server (2008 R2 - 2012 R2 - 2016) - Linux - Cloud Providers  
Linux distributions supported : Ubuntu, Debian, CentOS/Fedora/Red Hat, Suse, Mandriva, Slackware, Vector, Zenwalk, Sabayon, ArchLinux, rPath/Foresight, Alpine, Gentoo, Lunar, Source Mage, NixOS, Void  

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

## How it works ?
Launch the script, enter the inventory file...and let's play !

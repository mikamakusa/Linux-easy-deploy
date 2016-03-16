# Linux-easy-deploy
Deploy Packages/Roles/Docker containers on linux distributions with Powershell

# v1.2
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

## Action available in inventory file
Install | Remove | Search | UpSystem (a.k.a : System Update) | UpPackage (a.k.a : Package List Update)

## Inventory file example - Roles & Packages(*.csv)  
   IP;Port;User;Password;Type;Name;Packages;Action  
   192.168.99.100;32768;root;$pPsd34n0;Role;LEMP;Nginx  
   ;;;;;;mysql  
   ;;;;;;php  
   192.168.99.110;32769;root;$mlkDE46;Packages;vim;Install  
   It will install LEMP role with nginx, mysql and PHP on 192.168.99.100  
   It will install vim package on 192.168.99.110

## Inventory file example - Docker  
  IP;Port;User;Password;Type;Image;Mode;Cname;Network;AddHost;DNS;RestartPolicies;EntryPoint;CMD;PortsExpose;PortPublish;Volume;Link  
  192.168.99.100;32768;root;$pPsd34n0;Docker;ubuntu;daemon;test;;;;;;;80;;;  
  
  It will launch the following command : docker run -dit --expose=[80] --name test ubuntu  

## How it works ?
Launch the script, enter the inventory file...and let's play !

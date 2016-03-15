# Linux-easy-deploy
Deploy packages on linux distributions with Powershell

# v1.0
## Inventory file example (*.csv)

  IP;Port;User;Password;Packages;Action  
  192.168.99.100;32768;root;$pPsd34n0;vim;Install  
  ;;;;curl;Remove  
  ;;;;wget;Search  
  ;;;;java;Install  
  192.168.99.110;32769;root;a@d012l1AF;;UpSystem

## Result
Connect to 192.168.99.100 / Port 32768 with username and password  
Check the Package Manager and install vim and Java, Remove curl, Search wget  
Connect to 192.168.99.10 / Port 32769 with username and password  
Check the Package Manager and do a System Upgrade  

## Action available in inventory file
Install | Remove | Search | UpSystem (a.k.a : System Update) | UpPackage (a.k.a : Package List Update)

## How it works ?
Launch the script, select "auto Deploy" or "Manual Deploy"  
If "Auto Deploy", specify te inventory file.  
If "Manual Deploy", specify the host number, the ip addresses and the associated ports.  
Once connected, specify the package and the action applied to the package.

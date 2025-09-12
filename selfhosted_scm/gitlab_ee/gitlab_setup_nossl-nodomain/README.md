# hosting gitlab on docker compose 
- add docker compose file 
- add config folder
	- must contain gitlab.rb file
	- **UPDATE::** external_url 'http://gitlab.aes-core.com' 
	- backups,logs,data folder will automatically be created by docker compose/ make empty directories
	- docker compose up 
	- since no active domain is added, add http://gitlab.aes-core.com(your domain) vm_ip <-- /etc/hosts on your local computer

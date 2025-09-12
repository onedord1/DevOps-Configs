# hosting gitlab on docker compose 
- add docker compose file 
- add config folder
	- must contain gitlab.rb file
	- **UPDATE::** external_url 'https://gitlab.aes-core.com' 
	- backups,logs,data folder will automatically be created by docker compose/ make empty directories
	- generate ssl certs
	```
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout gitlab.aes-core.com.key \
		-out gitlab.aes-core.com.crt \
		-config gitlab-cert.conf

	```
	- docker compose up 
	- since no active domain is added, add https://gitlab.aes-core.com(your domain) vm_ip <-- /etc/hosts on your local computer




# ref https://docs.gitlab.com/omnibus/settings/ssl/
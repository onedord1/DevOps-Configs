# migrating gitlab server's data from old gitlab -> new gitlab


# 1. steps @old gitlab
-	stop docker containers (just to be safe that no new data is inserted on the fly)
-	execute
	-	`sudo tar -cvpzf gitlab_data_backup.tar.gz gitlab`
	-	this tars the gitlab directory(the parent directory where all the codes are hosted)
	-	

# 2. steps @new gitlab
-	create a new vm
-	install docker
-	transfer the tar file to this server
-	extract
	- `sudo tar -xvpzf gitlab_data_backup.tar.gz`
- docker compose up -d

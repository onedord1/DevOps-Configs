<!-- 
## installing gitlab cmds
sudo apt update && sudo apt install -y curl openssh-server ca-certificates tzdata perl
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://your-domain-or-ip" apt install gitlab-ee=15.11.13-ee.0
 -->

gitlab-com.gitlab.io/support/toolbox/upgrade-path/
15.8.1-ee -> 15.11.13 => 16.3.9 => 16.7.10 => 16.11.10 => 17.1.8(NOW) => 17.3.7 => 17.5.5 => 17.8.7 => 17.11.4 => 18.0.2
# upgrade
- check the next compatible version from this website  gitlab-com.gitlab.io/support/toolbox/upgrade-path/
- you will get all the intermediate images to reach the final version
- before upgrading do a manual backup
- docker exec id gitlab-backup create
- docker compose down(will not delete data/ as volume is mounted)
- update image tag to the next nearest version
- docker compose up -d
- repeat

# rollback

- do an upgrade (1.docker compose down 2.update image in compose file 3.docker compose up -d)
- system breaks
- docker compose down
- delete log and data directory
- update to the old image 
- docker compose up
- wait the fresh server to be started
- docker exec 
- gitlab-backup restore

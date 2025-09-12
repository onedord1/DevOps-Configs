# migrating projects from old gitlab -> new gitlab


- firstly list all the projects available in a txt file
	- execute the shell script 0-getProjects.sh
	- make sure that
		- response=$(curl  -sk  --header  "PRIVATE-TOKEN: $token"  "https://172.17.18.200/api/v4/projects?per_page=2000&page=1")
		- change page=1,2,3....(paginate) according to project count to get all the projects in the api response.

- then execute the shell script 1-createproject.sh
- this will loop through the list, clone the project from old server, change origin of the project, push the project to the new server
- upon execution of this script it will prompt you to give old git credential
- new git credential is already given in the code.
	- GITLAB_API_TOKEN="glpat-DZx_ta1L22nMB8QnEtCe"
	-	GITLAB_API_URL="http://gitlab.aes-core.com/api/v4"



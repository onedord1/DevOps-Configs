## Installing Grafana using Docker

**Pre-requisite:** We need to Docker installed on our system. If you don't have Docker installed, you can refer to [Docker Installation](https://www.tecmint.com/install-docker-and-run-docker-containers-in-linux/) guide.

- We can run our Grafana instance using the below docker command.

```bash
docker run -d -p 3000:3000 --name=grafana grafana/grafana-oss
```

- The above command will pull the Grafana OSS image from Docker Hub and run the Grafana container. We can access our Grafana instance using the URL `http://localhost:3000`. The default username and password is `admin`. We can change the password after login.

- For specific version of Grafana, we can use the below command.

```bash
docker run -d -p 3000:3000 --name=grafana grafana/grafana-oss:version
```

Date of notes: 04/07/2024
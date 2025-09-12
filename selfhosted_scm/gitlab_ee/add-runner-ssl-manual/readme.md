inside runner container:
get crt

- openssl s_client -showcerts -connect gitlab.aes-core.com:443 -servername gitlab.example.com < /dev/null 2>/dev/null | openssl x509 -outform PEM > crt.crt
register and generate config file
- gitlab-runner register --tls-ca-file=crt.crt
- executer: docker
- image: docker
run:
- gitlab-runner run

# runner can not reach the domain, since it is publicly not resolveable.
sol:
- add extra arg in runner config
```
  [runners.docker]
    ....
    extra_hosts = ["gitlab.aes-core.com:172.17.19.247"]
```


incase this extra host doesnt work 
https://akrabat.com/docker-compose-dns-entries/
check this
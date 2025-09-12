# collect-ship NGINX server logs
- these servers are external from kubernetes clusters
- make sure elasticsearch is exposed in loadbalancer

![enter image description here](./assets/arch-2.png)

## 1. install
- install fluentbit
	- https://docs.fluentbit.io/manual/installation/getting-started-with-fluent-bit

## ubuntu 22.04

```
curl -s https://packages.fluentbit.io/fluentbit.key | gpg --dearmor | sudo tee /usr/share/keyrings/fluentbit-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/jammy jammy main" | sudo tee /etc/apt/sources.list.d/fluentbit.list

sudo apt update
sudo apt install fluent-bit

```

- configure fluentbit
	- `cd /etc/fluent-bit/`
	- edit `fluent-bit.conf`
```
[SERVICE]
    Flush        5
    Daemon       Off
    Log_Level    info
    Parsers_File parsers.conf
[INPUT]
    Name              tail
    Path              /var/log/nginx/access.log
    Parser            nginx
    Tag               nginx.access
    DB                /var/log/flb_nginx.db
    Refresh_Interval  5
    Mem_Buf_Limit     10MB
[INPUT]
    Name              tail
    Path              /var/log/nginx/error.log
    Parser            nginx
    Tag               nginx.error
    DB                /var/log/flb_nginx_error.db
    Refresh_Interval  5
    Mem_Buf_Limit     10MB

[FILTER]
    Name record_modifier
    Match nginx.*
    Record hostname ${HOSTNAME}
[OUTPUT]
    Name  es
    Match nginx.*
    Host  172.17.19.61
    Port  9200
    TLS On
    TLS.Verify Off
    HTTP_User elastic
    HTTP_Passwd pas*sw****ord
    Index ${HOSTNAME}-nginx
    Type  _doc
    Suppress_Type_Name On
    Replace_Dots On
```
- start and enable
```
sudo systemctl enable fluent-bit
sudo systemctl restart fluent-bit
```



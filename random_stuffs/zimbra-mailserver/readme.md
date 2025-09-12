
---

# Zimbra Mail Server Setup Documentation

## General Information

| Key                  | Value              |
|----------------------|--------------------|
| **OS**               | Ubuntu 20          |
| **vCPU**             | 8                  |
| **RAM**              | 12 GB              |
| **Disk**             | 75 GB              |
| **Private IP**       | 172.17.19.253      |
| **Public IP**        | 115.127.156.168    |
| **Allowed Ports**    | 25, 587, 993, 995  |

---

## Installation

### Disk Layout
```bash
# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0                     7:0    0 91.9M  1 loop /snap/lxd/24061
loop1                     7:1    0 49.9M  1 loop /snap/snapd/18357
loop2                     7:2    0 63.3M  1 loop /snap/core20/1828
sda                       8:0    0   75G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    2G  0 part /boot
└─sda3                    8:3    0   73G  0 part 
  ├─ubuntu--vg-lv--root 253:0    0   10G  0 lvm  /
  ├─ubuntu--vg-lv--log  253:1    0   10G  0 lvm  /var/log
  └─ubuntu--vg-lv--opt  253:2    0   50G  0 lvm  /opt
sr0                      11:0    1  1.4G  0 rom
```

### Install Zimbra

```bash
apt update && apt upgrade -y
hostnamectl set-hostname mail.quickops.io
echo "172.17.19.253 mail.quickops.io mail" >> /etc/hosts

cd /opt
wget http://download.zextras.com/zcs-9.0.0_OSE_UBUNTU20_latest-zextras.tgz
tar -xvf zcs-9.0.0_OSE_UBUNTU20_latest-zextras.tgz
cd zcs-9.0.0_ZEXTRAS_20240927.UBUNTU20_64.20241001143114
./install.sh
# Do not install zimbra-dnscache
```

---

## Split DNS Setup

### Disable `systemd-resolved`
```bash
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved
rm -f /etc/resolv.conf
tee /etc/resolv.conf << END
nameserver 127.0.0.1
END
```

### Configure dnsmasq

```bash
apt install dnsmasq -y
> /etc/dnsmasq.conf
```

`/etc/dnsmasq.conf`:
```
# A record for mail.quickops.io
address=/mail.quickops.io/172.17.19.253

# MX record for quickops.io
mx-host=quickops.io,mail.quickops.io,10

# Upstream DNS
server=8.8.8.8
server=8.8.4.4
```

```bash
systemctl restart dnsmasq
systemctl enable --now dnsmasq
```

### Verify DNS
```bash
nslookup mail.quickops.io
```

---

## SSL Certificate

### DigitalOcean Token (DNS only)
```
dop_v1_61bb08703f49bb80606c1cb9f7d35157d4e28d8fb052d5358417699d88073d1d
```

### Generate Certificate

```bash
git clone https://github.com/acmesh-official/acme.sh.git
cd acme.sh
./acme.sh --set-default-ca --server letsencrypt
./acme.sh --register-account -m admin@quickops.io

export DO_API_KEY="dop_v1_61bb08703f49bb80606c1cb9f7d35157d4e28d8fb052d5358417699d88073d1d"
./acme.sh --issue --dns dns_dgon -d mail.quickops.io 
```

### Apply to Zimbra

```bash
cp -r /opt/zimbra/ssl/zimbra /opt/zimbra/ssl/zimbra.bak.$(date +%F)

wget -O /opt/zimbra/ssl/zimbra/commercial/isrgrootx1.pem https://letsencrypt.org/certs/isrgrootx1.pem

cat /root/.acme.sh/mail.quickops.io_ecc/ca.cer > /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt
cat /opt/zimbra/ssl/zimbra/commercial/isrgrootx1.pem >> /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt

cp /root/.acme.sh/mail.quickops.io_ecc/mail.quickops.io.key /opt/zimbra/ssl/zimbra/commercial/commercial.key
cp /root/.acme.sh/mail.quickops.io_ecc/mail.quickops.io.cer /opt/zimbra/ssl/zimbra/commercial/commercial.crt

chown -R zimbra:zimbra /opt/zimbra/ssl/zimbra/commercial/

/opt/zimbra/bin/zmcertmgr verifycrt comm \
    /opt/zimbra/ssl/zimbra/commercial/commercial.key \
    /opt/zimbra/ssl/zimbra/commercial/commercial.crt \
    /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt

/opt/zimbra/bin/zmcertmgr deploycrt comm \
    /opt/zimbra/ssl/zimbra/commercial/commercial.crt \
    /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt

zmcontrol restart
```

### Verify Certificate

```bash
echo | openssl s_client -connect mail.quickops.io:443 -servername mail.quickops.io 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

### Auto Renewal

`/opt/zimbra/ssl/renew_zimbra_cert.sh`:
```bash
#!/bin/bash
export DO_API_KEY="dop_v1_61bb08703f49bb80606c1cb9f7d35157d4e28d8fb052d5358417699d88073d1d"

/opt/acme.sh/acme.sh --renew -d mail.quickops.io --dns dns_dgon --ecc

if [ $? -ne 0 ]; then
    echo "Renewal failed. Exiting..."
    exit 1
fi

cp -r /opt/zimbra/ssl/zimbra /opt/zimbra/ssl/zimbra.bak.$(date +%F)

[ ! -f /opt/zimbra/ssl/zimbra/commercial/isrgrootx1.pem ] && \
wget -O /opt/zimbra/ssl/zimbra/commercial/isrgrootx1.pem https://letsencrypt.org/certs/isrgrootx1.pem

cat /root/.acme.sh/mail.quickops.io_ecc/ca.cer > /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt
cat /opt/zimbra/ssl/zimbra/commercial/isrgrootx1.pem >> /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt

cp /root/.acme.sh/mail.quickops.io_ecc/mail.quickops.io.key /opt/zimbra/ssl/zimbra/commercial/commercial.key
cp /root/.acme.sh/mail.quickops.io_ecc/mail.quickops.io.cer /opt/zimbra/ssl/zimbra/commercial/commercial.crt

chown -R zimbra:zimbra /opt/zimbra/ssl/zimbra/commercial/

su - zimbra -c "/opt/zimbra/bin/zmcertmgr verifycrt comm \
    /opt/zimbra/ssl/zimbra/commercial/commercial.key \
    /opt/zimbra/ssl/zimbra/commercial/commercial.crt \
    /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt"

su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm \
    /opt/zimbra/ssl/zimbra/commercial/commercial.crt \
    /opt/zimbra/ssl/zimbra/commercial/commercial_ca.crt"

su - zimbra -c "zmcontrol restart"
```

Set executable and cron:
```bash
chmod +x /opt/zimbra/ssl/renew_zimbra_cert.sh
crontab -e
0 2 * * * /opt/zimbra/ssl/renew_zimbra_cert.sh >> /var/log/zimbra_cert_renew.log 2>&1
```

---

## Zimbra Configuration Hardening

### Disable Clear Text Login
```bash
zmprov ms `zmhostname` zimbraMailClearTextPasswordEnabled FALSE
zmprov ms `zmhostname` zimbraImapCleartextLoginEnabled FALSE
zmprov ms `zmhostname` zimbraPop3CleartextLoginEnabled FALSE

zmcontrol restart
```

### Reject Unlisted Senders
```bash
zmprov mcf zimbraMtaSmtpdRejectUnlistedSender yes
zmmtactl restart
zmconfigdctl restart
```

### Bypass Spam Check for Internal Mail
```bash
zmprov ms `zmhostname` zimbraAmavisOriginatingBypassSA TRUE
zmamavisdctl restart
```

### Test Mail Flow

```bash
$ telnet mail.quickops.io 25
Trying 172.17.19.253...
Connected to mail.quickops.io.
Escape character is '^]'.
220 mail.quickops.io ESMTP Postfix
 mail from: user@quickops.io
503 5.5.1 Error: send HELO/EHLO first
ehlo mail.quickops.io
250-mail.quickops.io
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
mail from: jasim@quickops.io
250 2.1.0 Ok
rcpt to: admin@quickops.io
550 5.1.0 <jasim@quickops.io>: Sender address rejected: quickops.io
```

---

## DNS Records

### SPF
```
Type: TXT  
Host/Name: quickops.io  
Value: v=spf1 mx ip4:115.127.82.114 ?all
```

### DKIM

```bash
/opt/zimbra/libexec/zmdkimkeyutil -a -d quickops.io
```

### DMARC

```
_dmarc.quickops.io
v=DMARC1; p=none; rua=mailto:dmarc-reports@quickops.io; aspf=s;
```

### reverse dns

```
168.156.127.115.in-addr.arpa.  IN  PTR  mail.quickops.io.
```

---

## References

- [Zimbra Secure Configuration Guide](https://wiki.zimbra.com/wiki/SecureConfiguration)  
- [Zimbra Anti-Spam Strategies](https://wiki.zimbra.com/wiki/Anti-spam_Strategies)  
- [Rejecting False Mail From](https://wiki.zimbra.com/wiki/Rejecting_false_%22mail_from%22_addresses#Zimbra_Collaboration_8.5_and_above)




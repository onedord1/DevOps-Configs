**Well-documented `README.md`** for BIND authoritative + caching DNS setup, including benchmarking with `dnsperf`:

````markdown
# BIND DNS Server Setup for `anwargroup.io`

This guide provides a step-by-step setup for a **BIND DNS server** that is:

- **Authoritative** for the domain `anwargroup.io`
- **Caching / recursive** for external queries
- Benchmarkable using `dnsperf`

The setup is intended for small-scale environments (~100 users / 200 devices).

---

## 1. Install BIND and DNS utilities

```bash
sudo apt update
sudo apt install bind9 bind9utils bind9-doc bind9-dnsutils -y
````

* `bind9` → BIND DNS server
* `bind9utils` → CLI utilities like `rndc`
* `bind9-doc` → documentation
* `bind9-dnsutils` → tools like `dig`, `nslookup`

---

## 2. Configure Authoritative Zone

Edit `/etc/bind/named.conf.local`:

```bash
zone "anwargroup.io" {
    type master;
    file "/etc/bind/zones/db.anwargroup.io";
    allow-transfer { none; };   # prevent unauthorized zone transfers
};
```

* `type master` → this server is authoritative
* `allow-transfer { none; }` → disables AXFR/zone transfers

---

## 3. Create Zone Directory and Zone File

```bash
sudo mkdir -p /etc/bind/zones
```

Create `/etc/bind/zones/db.anwargroup.io`:

```bind
$TTL    3600
@       IN      SOA     ns1.anwargroup.io. admin.anwargroup.io. (
                        2025082701 ; Serial (YYYYMMDDnn format)
                        3600       ; Refresh
                        1800       ; Retry
                        604800     ; Expire
                        3600 )     ; Negative Cache TTL

; Name servers
        IN      NS      ns1.anwargroup.io.

; A records
ns1     IN      A       172.17.19.19
```

**Notes:**

* Replace `172.17.19.19` with your server’s public IP.
* Ensure **serial number** is updated whenever zone file changes.

---

## 4. Configure Global Options

Edit `/etc/bind/named.conf.options`:

```bind
options {
    directory "/var/cache/bind";

    recursion yes;             # enable caching for external queries
    allow-query { any; };      # allow all clients to query

    forwarders {               # upstream DNS servers for cache misses
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;    # enable DNSSEC validation
    auth-nxdomain no;          # simplify NXDOMAIN responses
    listen-on { any; };        # listen on all interfaces
};
```

---

## 5. Update Local Resolver

Ensure the server queries itself first:

```bash
cat /etc/resolv.conf
nameserver 127.0.0.1
```

---

## 6. Test Zone and Restart BIND

```bash
sudo named-checkzone anwargroup.io /etc/bind/zones/db.anwargroup.io
sudo systemctl restart bind9
dig @127.0.0.1 ns1.anwargroup.io
```

* `named-checkzone` → verifies zone file syntax
* `dig` → test DNS resolution locally

---

## 7. Benchmarking with `dnsperf`

### Install dnsperf

```bash
sudo apt install dnsperf -y
```

### Create query file `queries.txt`

```bash
cat > queries.txt <<EOF
www.anwargroup.io A
anwargroup.io A
ns1.anwargroup.io A
EOF
```

### Run benchmark

```bash
dnsperf -s 127.0.0.1 -d queries.txt -l 60 -Q 1000 -c 5
```

**Flags explained:**

* `-s 127.0.0.1` → DNS server to test
* `-d queries.txt` → file containing queries
* `-l 60` → test duration in seconds
* `-Q 1000` → simulate 1000 queries per second
* `-c 5` → number of concurrent clients

**Tips:**

* First run with **cold cache** (restart BIND, clear cache)
* Then run again for **warm cache** to see performance improvement
* Use `rndc stats` and `/var/cache/bind/named.stats` to monitor cache hits/misses

---

## References

* [BIND9 Administrator Reference Manual](https://bind9.readthedocs.io/)
* [dnsperf GitHub](https://github.com/DNS-OARC/dnsperf)

```

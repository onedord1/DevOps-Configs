## Securing Prometheus

We all know that security is very important for any software. We also need our Prometheus server secure to avoid any unauthorized access.<br>

**There are three ways to implement authentication and tls in Prometheus:**

1. Basic Authentication using Username and Password
2. OAuth
3. mTLS

We can use the above techniques to secure our API endpoints, Prometheus web UI by authenticating users and also we can secure components of prometheus like alertmanager, pushgateway, etc.

---

### Basic Authentication using Username and Password

We have to follow some steps to implement basic authentication in Prometheus:

1. Choose a `username` and `password`

2. **Bcrypt** the password. We can Bcrypt password using `Apache htpasswd` utility in Linux/Mac. For windows we can use [bcrypt-generator](https://www.bcrypt-generator.com/).
    - We can use the following command to bcrypt the password:
    ```bash
    htpasswd -nBC 10 "username" # C = Computing time, We need to set it 10 for Prometheus
    ```
    - Replace "username" with your username and it will ask you to enter the password. After entering the password you'll receive the bcrypt password.

3. Create a `web.yml` file in the same directory where the `prometheus.yml` file is present. There is no neccessary to keep your file name as `web.yml`, you can keep any name you want I jsut kept it as `web.yml`.
    ```yaml
    basic_auth_users:
      username: "bcrypt-password"
    ```

4. Pass the `web.yml` file to the Prometheus server. Based on your Operating System there sre some different ways to pass the `web.yml` file to the Prometheus server:

    - **For Windows**: We can pass the file as flags in Command Prompt. Example:
    ```cmd
    prometheus.exe --config.file=prometheus.yml --web.config.file=web.yml # If both files are in the same directory and you are currently in that particular directory
    ```

    - **For Linux**: We need to add the `--web.config.file=web.yml` flag in the `prometheus.service` file. Example:
    ```bash
    ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --web.config.file=/etc/prometheus/web.yml
    ```
**Best Practice:** Specifying the Absolute Path of the `web.yml` file is a good practice.

---

### Configuring `https` for Securing API Endpoints

1. For Configuring `https` we need to have a private key and certificate. We can generate a self-signed certificate using `openssl` utility in Linux/Mac. For windows we can use [openssl](https://slproweb.com/products/Win32OpenSSL.html). We can use self signed certificate for learning and testing purposes. For production we need to use valid certificate from Certificate Authority (CA).
    
    - Use the following command to generate a self-signed certificate:
    ```bash
    openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out prometheus.crt -keyout prometheus.key -subj "/C=IN/ST=Karnataka/L=Bangalore/O=Prometheus/CN=localhost"
    ```
    - Replace the values of `-subj` with your details.

2. Just like we created a file for basic authentication, we need to create a `web-secure.yml` file in the same directory where the `prometheus.yml` file is present. You can keep any name you want I just kept it as `web-secure.yml`.
    ```yaml
    tls_server_config:
      cert_file: "prometheus.crt" # If both `prometheus.crt` and `web-secure.yml` are in the same directory
      key_file: "prometheus.key" # If both `prometheus.key` and `web-secure.yml` are in the same directory
    ```
3. Just like we passed the `web.yml` file to Prometheus server, we need to pass the `web-secure.yml` file to the Prometheus server. Based on your Operating System there sre some different ways to pass the `web-secure.yml` file to the Prometheus server:

    - For Windows: We can pass the file as flags in Command Prompt. Example:
    ```cmd
    prometheus.exe --config.file=prometheus.yml --web.config.file=web-secure.yml # If both files are in the same directory and you currently in that particular directory
    ```

    - For Linux: We need to add the `--web.config.file=web-secure.yml` flag in the `prometheus.service` file. Example:
    ```bash
    ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --web.config.file=/etc/prometheus/web-secure.yml
    ```

**Note:** We can keep the contents of both `web.yml` and `web-secure.yml` in the same file to enable both basic authentication and tls.

---

### Securing Prometheus Components

We can secure components of Prometheus like Node Exporter, Pushgateway, Alertmanager using the same methods we used to secure Prometheus.

#### Why we need to secure Node Exporter?

If we don't secure our Node Exporter, anyone can internet can access our Node Exporter and can see our system metrics if our Node Exporter is exposed to the internet.

#### Why we need to secure Pushgateway?

To avoid any malicious users to push some random metrics to our Pushgateway.

#### Why we need to secure Alertmanager?

If we don't secure our alertmanager, anyone can access our alertmanager and can see our alerts. They can create some fake alerts and they can also delete our alerts. So it is very important to secure our alertmanager.

### Steps to Secure the components of Prometheus

We are going to follow the same methods for all the components like Node Exporter, Pushgateway, Alertmanager to secure them. Except we also need to configure our application to push metrics for secured Pushgateway.

- Create a `web.yml` file.
```yaml
tls_server_config:
  cert_file: "node-exporter.crt" # If your node exporter configuration file and certificate files are in the same directory
  key_file: "node-exporter.key" # If your node exporter configuration file and certificate files are in the same directory

basic_auth_users:
  username: "bcrypt-password"
```

- Now we need to pass the `web.yml` file to our components config files. Based on your Operating System there sre some different ways to pass the `web.yml` file to the components:

    - **For Windows:** We can pass the file as flags in Command Prompt. Example:
    ```cmd
    component.exe --web.config.file=web.yml # If both files are in the same directory and you currently in that particular directory
    ```

    - **For Linux:** We need to add the `--web.config.file=web.yml` flag in the `component.service` file as per the component.
    ```bash
    ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/web.yml
    ```
Just restart the components to apply the changes. Now we access our component using `https` and username and password.

- Now we need to update `prometheus.yml` file for Prometheus to use our self signed certificates to reach the components.

```yaml
# For Node Exporter and Pushgateway
scrape_configs:
  - job_name: 'node-exporter'
    scheme: https
    tls_config:
      ca_file: 'node-exporter.crt' # Use the absolute path if the .crt file is in different directory
      server_name: 'localhost' # For self signed certificates we need to add our domain/server name
    basic_auth:
      username: "username"
      password: "password"
    static_configs:
      - targets: ['localhost:9100']

# For Alertmanager

alerting:
  alertmanagers:
    - scheme: https
        tls_config:
          ca_file: 'alertmanager.crt' # Use the absolute path if the .crt file is in different directory
          server_name: 'localhost' # For self signed certificates we need to add our domain/server name
        basic_auth:
          username: "username"
          password: "password"
    - static_configs:
        - targets: ['localhost:9093']
```

Now we can restart our Prometheus server to securely access our components using `https` and username/password.

---

### Configuring our Python Application to push metrics to the secured Pushgateway

To make our application to push metrics to the secured Pushgateway. We need to add the `basic_auth` and `tls_config` in the application configuration file.

```py
from prometheus_client import push_to_gateway, CollectorRegistry, Gauge, registry, utils
from prometheus_client import exposition # Importing the exposition module to use the basic_auth_handler
from prometheus_client.exposition import basic_auth_handler # Importing the basic_auth_handler to use the basic authentication

# We have to create a basic auth handler to authenticate the user
def auth_handler(url, method, timeout, headers, data):
   return basic_auth_handler(url, method, timeout, headers, data, "admin", "password")

registry = CollectorRegistry()

gauge = Gauge("python_push_to_gateway", "python_push_to_gateway", registry= registry)

while True:
    gauge.set_to_current_time()
    push_to_gateway("https://localhost:9091", job="Job A", registry = registry, handler=auth_handler) # Passing the auth_handler to authenticate the user
```
- Now we can run our application to push metrics to the secured Pushgateway. If we get any errors like your certificate is self-signed certificate. We can just introduce our self-signed certificate to python using the environment variable `SSL_CERT_FILE`. We can set the environment variable like this:
```bash
export SSL_CERT_FILE=/path/to/our/certificate/file
```

- Now our application can be able to push metrics to the secured Pushgateway.

Date of notes: 04/03/2024
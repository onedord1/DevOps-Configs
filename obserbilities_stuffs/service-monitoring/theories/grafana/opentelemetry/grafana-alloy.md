## Grafana Alloy 

Grafana Alloy is a grafana distribution of OLTP compatible opentelemetry collector and it is compatible with opentelemetry. It can collect metrics, logs, and traces from various sources like kubernetes, microservices, prometheus, linux, etc. It can also scale from single node of alloy to high availability cluster of alloy.

### Installation of Grafana Alloy on Linux(Debian/Ubuntu)

1. Add the GPG key and Package repository for Grafana Alloy

```bash
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```

2. Update the Repository and Install Grafana Alloy

```bash
sudo apt-get update
sudo apt-get install grafana-alloy
```

For other distributions, you can follow the [official documentation](https://grafana.com/docs/alloy/latest/set-up/install/).

### Configuration of Grafana Alloy

For configuring the Grafana Alloy, we have to edit the configuration file of alloy located at `/etc/alloy/config.yaml`. Normally it will be having some default configurations. We can edit the configuration file as per our requirements.

#### Example Configuration File for Exporting Metrics to Prometheus
```yaml
logging {
  level  = "debug"
  format = "logfmt"
}

otelcol.receiver.otlp "default" {
  http {}
  grpc {}

  output {
    metrics  = [otelcol.processor.batch.default.input]
  }
}

otelcol.processor.batch "default" {
  output {
    traces  = [otelcol.exporter.otlphttp.tempo.input]
  }
}

otelcol.exporter.prometheus "default" {
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.remote_write "default" {
  endpoint{
    url = "http://localhost:9090/api/v1/write"
  }
  basic_auth {
    username = "admin"
    password = "admin"
  }
}
```

Once updated the configuration file, we have to restart the alloy service to apply the changes and then we can access our grafana alloy web interface at `http://localhost:12345`.<br>

**Note:**
Now we need to Update our application or microservices to send the metrics to Grafana Alloy. We can use OpenTelemetry SDKs to instrument our code to send the metrics to Grafana Alloy. There are two protocols supported by OLTP Exporters to export the metrics. One is `HttpProtoBuf` and another one is `Grps`. We have to use the correct port number for these protocols accordingly in our application code. For `HttpProtoBuf` the port number is `4318` and for `Grps` the port number is `4317`.

Date of notes: 06/07/2024
## OpenTelemetry Introduction

***OpenTelemetry is a vendor-neutral, open-source observability framework by the Cloud Native Computing Foundation (CNCF). It can collect traces, metrics, and logs from various sources, process them, and export them to various backends like Prometheus, Jaeger, and Grafana.***

### OpenTelemetry Architecture

OpenTelemetry has **four stages**in its architecture:

1. **Sources**: The sources are the applications or microservices that generate telemetry data. The sources can be instrumented(Updated) to use OpenTelemetry SDKs to generate telemetry data and then we can use OTel SDK to push these metrics to OpenTelemetry Exporters. If we have access to source code, we can instrument the code to use OpenTelemetry SDKs. If we don't have access to source code, we can use Auto-instrumentation mechainsm, it will use the profiler capabilities of our language runtime to instrument the code.

2. **OpenTelemetry Exporters**: We can use OpenTelemetry Exporters to export the telemetry data to OpenTelemetry Collectors. OpenTelemetry Exporters includes OLTP exporter, Prometheus exporter, New Relic exporter, etc.

3. **OpenTelemetry Collector**: OpenTelemetry Collectors are used to collect metrics, logs and traces from OpenTelemetry Exporters and then it can Process, Aggregates, and Export the data to various backends like Prometheus, Jaeger, and Grafana.

4. **Backends**: The backends are systems that store and process and visualize the telemetry data. The backends can be Prometheus, Jaeger, Grafana, etc.


### How to setup OpenTelemetry 

We have to setup our Opentelemtry environment form right to left which means we have to setup the backends first, then OpenTelemetry Collector, then OpenTelemetry Exporters, and finally the sources.<br>

In order to send the metrics to Prometheus, we have use the concept called `remote write`. **Remote write is a feature of Prometheus that allows it to send metrics to other systems or other prometheus instances. We can use OpenTelemetry Collector to send the metrics to Prometheus using remote write.**

#### How Remote Write works

When Prometheus scrapes the metrics from targets, it stores the metrics in TSDB Disk and it also send copy of metrics to WAL (Write Ahead Log). Then WAL Watcher will read metrics from WAL and send the metrics to remote write endpoint. And then remote write endpoint will send the metrics to other systems or other prometheus instances.<br>

We can consider like OpenTelemetry Collector has a small Prometheus instance inside it. It will get the metrics from Exporter inside OpenTelemetry Collector and then it will send the metrics to Other systems or other Prometheus instances.<br>

The HTTP endpoint for prometheus to use remote write is `http://localhost:9090/api/v1/write`.

Date of notes: 06/07/2024
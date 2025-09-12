## WMI Exporter

There is no official Exporter by Prometheus for collecting metrics from Windows systems. But we can use the WMI Exporter to collect the metrics from Windows systems. WMI Exporter is a exporter for collecting metrics from Windows systems. It collects the metrics from the Windows Management Instrumentation(WMI) and exposes them to Prometheus. Then Prometheus will scrape the metrics from the WMI Exporter.

### Installation

1. Go to the [WMI Exporter GitHub page](https://github.com/prometheus-community/windows_exporter).

2. Scroll down to the `Installation` section and Click on the `releases_page` link. It will take you to the releases page of the WMI Exporter. Click on the latest release version. Now you can install the WMI Exporter by the downloading the `.exe` or `.msi` file based on your System Architecture and needs.

3. Once the download is completed, Run the `.exe` or `.msi` file to install the WMI Exporter. It will expose the metrics on the port `9182` by default but we can also change the port by passing the `--web.listen-address` flag.

4. Now the WMI Exporter is running and exposing the metrics on the port `9182`. We can access the metrics by visiting the URL `http://localhost:9182/metrics`.

5. If we want our Prometheus server to scrape the metrics from the WMI Exporter, we need to update the scraping configuration in the `prometheus.yml` file.

For Updating the scraping configuration in the `prometheus.yml` file, refer to the [Updating the Scraping Configuration in Prometheus Server](../data-collection/node-exporter.md) section.

### WMI

**WMI Stands for Windows Management Instrumentation. It is a infrastructure for managing data and operations on Windows-based operating systems**. We can use `WMI` to write scripts or applcations to automate administrative tasks on Windows-based operating systems. WMI provides a uniform environment for scripting and automating the management of Windows-based systems.

Date of notes: 01/07/2024
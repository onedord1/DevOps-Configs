## Grafana Introduction

### Why we need Grafana?

We all know that Prometheus is a monitoring tool that can be used to collect metrics from various systems. Also it comes with some basic visualization capabilities. **But the visualization capabilities of Prometheus are not so good. If we need to visualize our metrics in a more shopisticated way, prometheus is not a good option. In this case we can use Grafana to visualize our metrics in a more sophisticated way.**

### What is Grafana?

Grafana is an open-source platform for visualizing time series data. In `Grafana` we can connect to many time series data sources like `Prometheus`, `InfluxDB`, `Graphite`, etc. and visualize our data in a more sophisticated way. We can also create alerts in Grafana sometimes we need to create alerts in Grafana instead of Prometheus for some specific use cases like if we want to create alerts based on multiple data sources metrics. Grafana is also suitable for Large Organizations where we have multiple teams and also we have some good access control features in Grafana for different teams.

### How to Create Dashboards in Grafana

1. Go `Dashboards` -> Click on `New` -> Then from dropdown Click on `New dashboard` -> Click on `Add Visualization` -> Select the `Data Source` from the dropdown -> Enter the `Query` -> Click on `Run Query` -> Click on `Save` -> Enter the `Name` of the dashboard -> Select the folder where you want to save the dashboard -> You can add some description to dashboard if you want-> Click on `Save` button.

2. We can also add multiple panels and rows to dashboard by clicking on `Add Panel` and `Add Row` buttons.

3. We can also import and export dashboards in Grafana. To import a dashboard, we have to go to `Dashboards` -> Click on `New` -> Then from dropdown Click on `import` -> Enter the `Dashboard ID` or `URL` -> Click on `Load` -> Click on `Import` button.

### Some of the Basic Concepts in Grafana Dashboards

1. **Variables**: We can use `variables` in Grafana to make our dashboards more interactive and Dynamic. To add variables, we have to go to dashboard `Settings` -> `Variables` -> Click on `Add Variable` button.

2. **Thresholds**: We can set `thresholds` values in Grafana dashboards to visualize our data in a more sophisticated way. We can set thresholds by going to `Visualization` -> `Thresholds` Section on Right Side -> Click on `Add Threshold` button.

3. **Annotations**: We can add `annotations` to mark some specific points in our data. To add annotations, we have to go to dashboard `Settings` -> `Annotations` -> Click on `Add Variable` button.

Date of notes: 05/07/2024
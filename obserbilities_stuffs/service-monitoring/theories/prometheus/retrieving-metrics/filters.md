## Filters for Retrieving Metrics

We can retrieve metrics from Prometheus using filters. Filters are used to filter the metrics based on the metric name and labels. We can use filters to retrieve the metrics that match the filter criteria. If we don't use filters, Prometheus will return all the metrics that are available in the database.

### Syntax


The syntax for using filters in Prometheus is:


**<metric_name>{<label_name>=<label_value>, <label_name>=<label_value>, ...}**


### Operators available for filters

Prometheus supports the following operators for filters:

- **`=` (Equal)**: It will return metris that have the label value equal to the specified value.
- **`!=` (Not Equal)**: It will return metrics that have the label value not equal to the specified value.
- **`=~` (Regex Match)**: It works based on `regex` pattern. It will return metrics that have the label value that matches the regex pattern.
- **`!~` (Regex Not Match)**: Same as `=~` but it will return metrics that have the label value that does not match the regex pattern.

Date of notes: 01/07/2024
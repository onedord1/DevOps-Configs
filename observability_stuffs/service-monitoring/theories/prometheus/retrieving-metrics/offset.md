## Time Offset in Prometheus

In Prometheus, we can use the `offset` keyword to get the time offset of the metric. Let's say we want to know the value of the metric 5 minutes ago. We can use the `offset` keyword to get the value of the metric 5 minutes ago.

### Syntax

The syntax for using the `offset` keyword in Prometheus is:

**<metric_name>{<label_name>=<label_value>} offset <duration>**


### Example

Let's say we have a metric `http_requests_total` that has the following values:


**http_requests_total offset 5m**

The above expression will return the value of the `http_requests_total` metric 5 minutes ago.

Date of notes: 01/07/2024
## Monitoring and Telemtetry

### Why we need monitoring and telemetry?

Let's we have a application. That is either going to run on physical server or cloud server. Any way it's going to run on a server. Even if our application runs on Serverless, it's going to run on a server. **Every application will produce some logs. Logs are the information about the application. It can be error, warning, info, debug etc. Logs are going to be logged in log storage database.** Some of the log storgae databases are Elasticsearch, Splunk, Loggly, Logstash, Kibana etc. Logs are useful when some event was alredy happended and we know how to diagnose the issue. we can read the log files and can fix the problem.<br>

But What if we want to notified before the event happens. Also we want more data just than logs. We want to know the performance of the application. We want to know the CPU, Memory, Disk, Network, I/O etc. Or Let's say  we have to identify why our application is slow?

**Some of the Example Scenarios:**

- How many users are using our application from particular region?
- How many errors and exceptions are happening in our application per day?
- How many requests are coming to our application per day?
- What is the average response time of our application?
- How many servers our application is using, if we are using cloud?

There are three parmeters associated with the information for the above scenarios:

1. **Metrics**:
    - How many requests are coming to our application per day?
    - What is the average response time of our application?

2. **Values**:
    - The value of the metric. For example, the number of requests per day is equal to 1000. Or, the average response time of the application is 100ms. Or, the maximum response time of the application is 200ms.

3. **Time**:
    - The time at which the metric was recorded. Example: 10:00 AM, 11:00 AM etc.

And now to store this information we need a database. This database is called as **Time Series Database**. Some of the time series databases are Prometheus, InfluxDB, Graphite, OpenTSDB etc.<br>

In `Prometheus` we can store, Query and Visualize the metrics. We can also create the alerts based on the metrics. We can also create the dashboards to visualize the metrics.

### What is Telemetry?

`Telemetry` is the process of collecting the business and diagnosis data from the application. Storing and Visualizing the data for the purpose of fixing the issues and improving the performance of the application.

Date of notes: 01/07/2024
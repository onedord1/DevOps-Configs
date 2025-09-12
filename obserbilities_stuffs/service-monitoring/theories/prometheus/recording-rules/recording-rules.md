## Recording rules in Prometheus

- If we are constantly calculating the `avg`, `sum`, `max`, `min` like functions for a large number of time series data, then it will be slow and inefficient. To avoid this, we can use recording rules in Prometheus.
- **We can use recording rules to precompute frequently needed or computationally expensive expressions and save their result as a new set of time series data. The recording rules are evaluated by Prometheus server at regular intervals. If the expression is true then the recording rule will be fired**.
- We can define Recording rules in `.yml` file.

### How recording rules work?

Let's consider our Prometheus Server monitoring a Linux server. **We can use `recording rules` to say Prometheus to calculate the `avg` of the `CPU` usage of the server every 5 minutes and save the result as a new time series data. So that we can use this `avg` value in our `PromQL` expressions**. It just work like calculating the `avg` of the `CPU` usage of the server as metrics comes in.


### Defining Recording Rules

- Before defining recording rules, we need to understand one function called `rate`. The `rate` function calculates the per-second average rate of increase of the time series data.  we can use the `rate` to convert the metric with range vector to an instant vector. There is also one similar function called `irate` which calculates the per-second rate of increase of the time series data at the current time. We can say `irate` is for fast moving data and `rate` is for slow moving data. Prometheus recommends to use `rate` function for alerting and recording rules.

```yml
groups:
- name: example
  rules: 
  - record: job:request_latency_seconds:avg # Naming Convention: <level>:<metric_name>:<function>
    expr: avg(rate(request_latency_seconds_sum[5m])) # Calculating the avg of the request latency seconds every 5 minutes.

# In the above example, we are calculating the avg of the request latency seconds every 5 minutes and saving the result as a new time series data. If we need to find sum of the avg of the request latency seconds every 5 minutes, then we can use the new time series data. Example: sum(job:request_latency_seconds:avg)
```

- We need to keep this `.yaml` file in the appropriate directory. For `Linux` it will be in `/etc/prometheus/rules/` directory. For `Windows` and `MacOS` we can create one recording-rules directory next to the `prometheus.yml` file and keep all the recording rule `.yml` files in that directory.

- Now we need to mention the `.yml` file in the `prometheus.yml` file.

```yaml
# Under the `scrape_configs` section
rule_files:
  - "rules/recording-rules.yml" # Relative path to the recording rule .yml file
```

- Once updated the `prometheus.yml` file, we need to restart the Prometheus server to apply the changes.

Date of notes: 02/07/2024
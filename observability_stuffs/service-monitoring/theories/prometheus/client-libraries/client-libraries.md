## Client libraries in Prometheus

***We can load Prometheus client libraries in our application and expose the metrics to Prometheus***. Prometheus provides fiveofficial client libraries for Python, Java or Scala, Ruby, Rust and Go. We can use these client libraries to expose our application metrics to Prometheus.

### Python Client Library Example

We can use Python client library to expose the metrics from our Python application to Prometheus.<br>

- We can install the Python client library using the below command:

```bash
pip install prometheus_client
```

- We can import the `prometheus_client` module in our Python application and use the functions to expose the metrics to Prometheus.

```python
from prometheus_client import start_http_server, Summary, Counter, Gauge
import random
import time

# Create a metric to track time spent and requests made.

REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request') # The First parameter we passing here is the name of the metric and second parameter is help text for the metric.
MY_COUNTER = Counter('my_counter', 'sample counter metric', ['label1', 'label2']) # For Counter class, the first parameter will be formed as "my_counter_total". We can add labels as a third parameter to our Class.
MY_GAUGE = Gauge('my_gauge', 'sample gauge metric') # We can add labels as a third parameter to our Class.

# Decorate function with metric.

@REQUEST_TIME.time()
@MY_COUNTER.count_exceptions()
def process_request(t):
    """A dummy function that takes some time."""
    MY_COUNTER.inc() # Every time this function is called, the counter will be incremented by 1.
    MY_GAUGE.set(10) # Set value of the gauge to 10.
    MY_GAUGE.inc() # Increment the value of the gauge by 1.
    MY_GAUGE.dec() # Decrement the value of the gauge by 1.
    MY_COUNTER.labels(label1='value1', label2='value2').inc(5) # Increment the counter with the labels.
    time.sleep(t)

if __name__ == '__main__':
    # Start the server to expose the metrics
    start_http_server(8000)
    # Generate some requests
    process_request(random.random())

    while True:
        a = 5

    print("A demo of Prometheus client library")
```

- We can use the `start_http_server` function to start the HTTP server on application if it doesn't have any HTTP server already.

- If we want to create metric for Python application, we can use the `Summary`, `Counter`, and `Gauge` classes provided by the `prometheus_client` module to create the metrics.

- If we don't specify `start_http_server` function, Prometheus can scrape metrics from any endpoints by using `/metrics` endpoint.

- Once we done with our application code updation, we have to mention our application as a target in the `prometheus.yml` file.

```yaml
  - job_name: 'python-app'
    static_configs:
    - targets: ['localhost:8000']
```

Date of notes: 03/07/2024
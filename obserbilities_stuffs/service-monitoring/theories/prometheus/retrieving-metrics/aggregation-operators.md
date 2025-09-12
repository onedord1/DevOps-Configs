## Aggregation Operators in Prometheus

Prometheus provides some of the aggregation operators that can be used to aggregate the metrics.<br>

**Prometheus supports the following aggregation operators:**

- `sum()`: Calculates the sum of the values of the Output Metrics.
- `avg()`: Calculates the average of the values of the Output Metrics.
- `min()`: Calculates the minimum value of the Output Metrics.
- `max()`: Calculates the maximum value of the Output Metrics.
- `count()`: It calculates the count of the elements in the Output Metrics. Example: If my Output Metrics has 5 elements, then the count will be 5.
- `count_values()`: It calculates the count of number of elements that has a value similar to given value.
- `group()`: It will group all the elements. Will return only one element with the value as `1`.
- `topk()`: It will Pick the top `k` elements based on the value of the Output Metrics.
- `bottomk()`: It will Pick the bottom `k` elements based on the value of the Output Metrics.
- `stddev()`: Calculate the standard deviation of the Output Metrics.
- `stdvar()`: Calculate the standard variance of the Output Metrics.

### Syntax

The syntax for using aggregation operators in Prometheus is:


**<aggregation_operator>(<expression>)**

***Example:***

sum(http_requests_total{method="GET", handler="/api/v1/users", status="200"})<br>

If we want to do aggregation operations based on the labels, we can use the `by` clause. The `by` clause is used to group the metrics based on the labels.

### Syntax for using `by` keyword

The syntax for using the `by` in Prometheus is:

**<aggregation_operator>(<expression>) by (<label_name>)**

***Example:***

sum(http_requests_total{method="GET", handler="/api/v1/users", status="200}) by (method)<br>

The above expression will return the sum of the `http_requests_total` metric based on the `method` label.<br>

Similarly, we can use the `without` clause to exclude the labels from the aggregation operation.


### Aggregation Over Time

We can use aggregation vectors normally with instant vectors. But if we want to apply aggregation operators with range vectors, we have to use the `sum_over_time`, `avg_over_time`, `min_over_time`, `max_over_time`, `count_over_time`, `stddev_over_time`, `stdvar_over_time` etc. Over time will be applied for any aggregation operator.

Date of notes: 01/07/2024
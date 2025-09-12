## Arithmetic Operators in Prometheus

We can use arithmetic operators in Prometheus to perform some basic arithmetic operations on the metrics. Prometheus supports the following arithmetic operators:

- `+` (Addition)
- `-` (Subtraction)
- `*` (Multiplication)
- `/` (Division)
- `%` (Modulus)

### Syntax

The syntax for using arithmetic operators in Prometheus is:


**<expression> <arithmetic_operator> <expression>**

### Arithmetic Operators Working Example

- If we use arithmetic operators on two scalar values, it will perform the arithmetic operation on the two scalar values. The reult will be another scalar value.<br>

**Example:** 10 + 5 will return `15`.

- If we use arithmetic operators on one Scalar and one Instant Vector, it will take the scalar value and perform the arithmetic operation on the Instant Vector. The result will be an Instant Vector.

**Example:**
```
10 + http_requests_total{method="GET", handler="/api/v1/users", status="200"}
```

Let's say the above expression return 5 time series with the value of `http_requests_total` as `5`, `10`, `15`, `20`, `25`. The result will be `15`, `20`, `25`, `30`, `35`.

- If we use arithmetic operators on two Instant Vectors, it will perform the arithmetic operation based on the left side Instant Vector that matches with right side Instant Vector. Matching means both the instant vectors should have the same metric name and label values to perform he arithmetic operation.

```
http_requests_total{method="GET", handler="/api/v1/users", status="200"} + http_requests_total{method="GET", handler="/api/v1/users", status="400"}
```

Let's say we have two instant vectors A and B. A has elements as m[a] = 5, m[b] = 10, m[c] = 15 and B has elements as m[a] = 10, m[b] = 20, m[d] = 30. The result will be `m[a] = 15`, `m[b] = 30`. Since m[d] is not present in A, it will not be considered for the arithmetic operation.<br>

We can consider `m` as the metric name and [a], [b], [c], [d] as the label values.

Date of notes: 01/07/2024
## Binary Operators in Prometheus

When we want to perform some meaningful operations on the metrics, we can use binary operators in Prometheus.

Prometheus supports the following binary operators:

- `==` (Equal)
- `!=` (Not Equal)
- `>` (Greater Than)
- `<` (Less Than)
- `>=` (Greater Than or Equal)
- `<=` (Less Than or Equal)

### Syntax

The syntax for using binary operators in Prometheus is:

**<expression> <binary_operator> <expression>**


### Binary Operators Working Example

- If we use binary operators on two scalar values, Let's say `10 == 5`, it will return `false`.

- If we use binary operators on one Scalar and two Instant Vectors, Let's say we have a scalar value `10` and we have two instant vectors `http_requests_total{method="GET", handler="/api/v1/users", status="200"}` and `http_requests_total{method="GET", handler="/api/v1/users", status="400"}`. If we compare the scalar value with the instant vectors, based on the binary operator it will return the instant vector that matches the condition. For example, `10 == http_requests_total{method="GET", handler="/api/v1/users", status="200"}` will return the instant vector that has the value `10`.

- If we use binary operators on two instant vectors, based on the arithmetic operator it will return the instant vector that matches the condition. For example, `m[a] = 10, m[b] = 20` as instant vector `A` and `m[a] = 10, m[b] = 30` as instant vector `B`. If we compare `A == B`, it will return matching instant vectors that is `m[a] = 10`

Date of notes: 01/07/2024
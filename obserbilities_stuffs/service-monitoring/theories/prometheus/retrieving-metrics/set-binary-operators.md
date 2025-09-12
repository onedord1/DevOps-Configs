## Set Binary Operators

There are three set binary operators in Prometheus:

1. `and`
2. `or`
3. `unless`

### Working

Let's we have two instant vectors `A` and `B`:

```
A = {m[a] = 10, m[b] = 20}
B = {m[a] = 10, m[b] = 30}
```

- If we use `and` operator on two instant vectors A and B, it will return the instant vector that matches the condition which means both have the same metric name and label values. **Output**: `m[a] = 10`

- For `or` operator on A and B. We will get output of union of A and B. **Output**: `m[a] = 10, m[b] = 20, m[b] = 30`

- For `unless` operator on A and B. It will return the instant vector that is in A but not in B. **Output**: `m[b] = 20`

Date of notes: 01/07/2024
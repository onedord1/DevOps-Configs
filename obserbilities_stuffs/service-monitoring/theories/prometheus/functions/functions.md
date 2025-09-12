## Functions in Prometheus

In Prometheus, **functions are used to perform operations on the metrics**. We can use to create Dashboards to visualize the data in a meaningful way. Prometheus provides a wide range of functions to perform operations on the metrics.

1. **absent(instant_vector):** Will returns empty vector if the result have some elements. Otherwise it returns a vector with a single element with the value 1.

2. **absent_over_time(range_vector):** It works same like `absent` function but it works on the range vector.

3. **abs(instant_vector):** Will returns the absolute values of each element in the input vector.

4. **ceil(instant_vector):** Will returns the smallest integer value that is greater than or equal to the input vector. Eg: 1.8 will return 2.

5. **floor(instant_vector):** It returns the largest integer value that is less than or equal to the input vector. Eg: 1.8 will return 1.

6. **clamp_max(instant_vector, max):** Returns all the elements having value greater than the max value.

7. **clamp_min(instant_vector, min):** Returns all the elements having value less than the min value.

8. **clamp(instant_vector, min, max):** Returns all the elements having value between min and max.

9. **day_of_month(instant_vector):** It will return the elements whose value is expressed as time stamps in UTC. It will return the day of the month. Eg: 2024-07-01 will return 1.

10. **day_of_week(instant_vector):** Will returns the elements whose value is expressed as time stamps in UTC. It will return the day of the week. Eg: If it returns 1, it means Monday.

11. **delta(instant_vector):** Will returns the difference between the first and last value of the input vector.

12. **idelta(range_vector):** Same like `delta` function but it works on the range vector.

13. **log2(instant_vector):** It returns the base 2 logarithm of the value of the elements in the input vector. Eg: If the value is 8, it will return 3.

14. **log10(instant_vector):** Returns the base 10 logarithm of the value of the elements. Eg: If the value is 100, it will return 2.

15. **ln(instant_vector):** Will returns the natural logarithm of the value of the elements. Eg: If the value is 2.718, it will return 1.

16. **time():** Will return the nearest valid Unix timestamp in seconds.

17. **timestamp(instant_vector):** Will return the timestamp of the elements. The time the metric was scraped.

Date of notes: 01/07/2024
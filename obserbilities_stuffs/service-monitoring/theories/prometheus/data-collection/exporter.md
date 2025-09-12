## Data Collection

Consider we have a application running on a server and we want prometheus to monitor the server. If we want our Application to send metrics to prometheus, we need to have to access the application code and modify it to send metrics to prometheus. Because the code is running on the server and we have to modify the code to send metrics to prometheus. But what if we don't have access to the application code? or we can't change the application code?<br>

**Example:** If we have some external mediums and we want to monitor them, like MySQL Database we can't change the code of MySQL to send metrics to prometheus. In such cases, we can use `Exporters`.<br>


### Exporters

Exporters are something we can use with prometheus to collect the metrics from the server or application and expose them to prometheus. Exporters are component of Prometheus.

#### How Exporters work?

We need to install the Exporter on the medium we want to monitor or next to that medium.<br>

**For example,** If we want to monitor Linux server, we have to install Node Exporter on the server. If we want to monitor MySQL, we have to install MySQL Exporter next to the MySQL.<br>

Once we install the `Exporter`, it will collect the metrics from the medium and expose them to prometheus. Prometheus will connect to Exporter and scrape the metrics from the Exporter. This process is called `Scraping`. **By default, Prometheus scrapes the metrics from the Exporter every 15 seconds.** We can define our own scraping configurations in the prometheus.yml file.

### Push Gateway

**If we want our application to send metrics to prometheus, we can use Push Gateway**. Push gateway is a component of prometheus that acts as temporary storage. It will have built-in exporter from that prometheus can scrape the metrics. We can push the metrics to Push Gateway from our application and prometheus will scrape the metrics from Push Gateway using the built-in exporter.

Date of notes: 01/07/2024
FROM registry.cloudaes.com/base-images/maven:3.6.3-openjdk-17-slim AS builder
WORKDIR /app
ENV MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true \
-Dmaven.wagon.http.ssl.allowall=true \
-Dmaven.wagon.http.ssl.ignore.validity.dates=true \
-Dmaven.resolver.transport=wagon"
COPY ./nexus-artifacthub/settings-docker.xml /root/.m2/settings.xml
COPY . .
COPY ./src/main/resources/application-prod.properties ./src/main/resources/application.properties
ARG NEXUS_USER \
    NEXUS_PASS
# Ensure maven-wrapper.properties exists
RUN sh -c '\
  if [ ! -f ./.mvn/wrapper/maven-wrapper.properties ]; then \
    echo "Configuring Maven Wrapper..."; \
    mkdir -p ./.mvn/wrapper; \
    curl -sSL -o ./.mvn/wrapper/maven-wrapper.properties https://raw.githubusercontent.com/takari/maven-wrapper/master/.mvn/wrapper/maven-wrapper.properties; \
  else \
    echo "Maven Wrapper already configured"; \
  fi && \
  chmod +x mvnw && \
  ./mvnw dependency:go-offline -s /root/.m2/settings.xml && \
  ./mvnw clean package -DskipTests -s /root/.m2/settings.xml'
FROM registry.cloudaes.com/base-images/openjdk:17-oracle
WORKDIR /app
# Add basic auth credentials as build args
ARG SIGNOZ_USERNAME
ARG SIGNOZ_PASSWORD
# Set basic auth credentials as environment variables
ENV SIGNOZ_USERNAME=${SIGNOZ_USERNAME}
ENV SIGNOZ_PASSWORD=${SIGNOZ_PASSWORD}
RUN rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/Asia/Dhaka /etc/localtime && \
    curl -sSL \
    https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar \ 
    -o /opt/opentelemetry-javaagent.jar
COPY --from=builder /app/target/*.jar app.jar
COPY ./certs/apm_quickops_io.crt /tmp/apm_quickops_io.crt
RUN keytool -importcert -alias apm-quickops-io -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -file /tmp/apm_quickops_io.crt -noprompt
EXPOSE 9009
# ENTRYPOINT ["java", "-jar", "./app.jar"]
CMD ["sh", "-c", "\
  java \
    -javaagent:/opt/opentelemetry-javaagent.jar \
    -Dotel.traces.exporter=otlp \
    -Dotel.metrics.exporter=otlp \
    -Dotel.logs.exporter=otlp \
    -Dotel.exporter.otlp.endpoint=https://apm.quickops.io:9317 \
    -Dotel.exporter.otlp.protocol=grpc \
    -Dotel.exporter.otlp.headers=Authorization=Basic%20$(echo -n ${SIGNOZ_USERNAME}:${SIGNOZ_PASSWORD} | base64 -w 0) \
    -Dotel.sampler.probability=1.0 \
    -Dotel.resource.attributes=service.name=${SERVICE_NAME:-prod-bmdsalesbe} \
    -Dotel.instrumentation.jdbc-datasource.enabled=true \
    -Dotel.instrumentation.hikaricp.enabled=true \
    -Dotel.instrumentation.spring-data.enabled=true \
    -Dotel.instrumentation.jdbc.statement-sanitizer.enabled=true \
    -Dotel.instrumentation.logback-appender.enabled=true \
    -Dotel.instrumentation.jdbc.experimental-span-attributes=true \
    -Dotel.instrumentation.spring-jdbc.enabled=true \
    -jar app.jar"]
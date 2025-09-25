FROM registry.cloudaes.com/base-images/maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app
ENV MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true \
-Dmaven.wagon.http.ssl.allowall=true \
-Dmaven.wagon.http.ssl.ignore.validity.dates=true \
-Dmaven.resolver.transport=wagon"
COPY ./nexus-artifacthub/settings-docker.xml /root/.m2/settings.xml
COPY . .
ARG NEXUS_USER \
    NEXUS_PASS  \
    BRANCH
COPY ./src/main/resources/application-${BRANCH}.properties ./src/main/resources/application.properties
RUN sh -c '\
  chmod +x mvnw && \
  ./mvnw dependency:go-offline -s /root/.m2/settings.xml && \
  ./mvnw clean package -DskipTests -s /root/.m2/settings.xml'
FROM registry.cloudaes.com/base-images/eclipse-temurin:21-jre
WORKDIR /app
ARG SIGNOZ_USERNAME \
    SIGNOZ_PASSWORD

ENV SIGNOZ_USERNAME=${SIGNOZ_USERNAME} \
    SIGNOZ_PASSWORD=${SIGNOZ_PASSWORD}  \
    JAVA_TOOL_OPTIONS="-Duser.timezone=Asia/Dhaka"

RUN rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
COPY --from=builder /app/target/*.jar app.jar
COPY ./certs/apm_quickops_io.crt /tmp/apm_quickops_io.crt
COPY ./dockerfiles/opentelemetry-javaagent.jar /opt/opentelemetry-javaagent.jar
RUN keytool -importcert -alias apm-quickops-io -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -file /tmp/apm_quickops_io.crt -noprompt && \
    groupadd -g 1001 appgroup && \                #to use this for cloud storageClass need to add securityContext in Deployments
    useradd -u 1001 -g appgroup -m appuser && \   #to use this for cloud storageClass need to add securityContext in Deployments
    mkdir -p /uploads && \                        #to use this for cloud storageClass need to add securityContext in Deployments
    chown -R appuser:appgroup /app /uploads && \  #to use this for cloud storageClass need to add securityContext in Deployments
    chmod 700 /uploads                            #to use this for cloud storageClass need to add securityContext in Deployments
# RUN rm -f /bin/sh
USER appuser
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
    -Dotel.resource.attributes=service.name=${SERVICE_NAME:-qa-bmdsalesbe} \
    -Dotel.instrumentation.jdbc-datasource.enabled=true \
    -Dotel.instrumentation.hikaricp.enabled=true \
    -Dotel.instrumentation.spring-data.enabled=true \
    -Dotel.instrumentation.jdbc.statement-sanitizer.enabled=true \
    -Dotel.instrumentation.logback-appender.enabled=true \
    -Dotel.instrumentation.jdbc.experimental-span-attributes=true \
    -Dotel.instrumentation.spring-jdbc.enabled=true \
    -jar app.jar"]
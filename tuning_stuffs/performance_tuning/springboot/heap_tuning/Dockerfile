FROM registry.cloudaes.com/base-images/maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app
ENV MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true \
-Dmaven.wagon.http.ssl.allowall=true \
-Dmaven.wagon.http.ssl.ignore.validity.dates=true \
-Dmaven.resolver.transport=wagon"
ARG NEXUS_USER
ARG NEXUS_PASS
ENV NEXUS_USER=${NEXUS_USER} \
    NEXUS_PASS=${NEXUS_PASS}
COPY ./nexus-artifacthub/settings-docker.xml /root/.m2/settings.xml
COPY . .
ARG BRANCH
COPY ./src/main/resources/application-${BRANCH}.properties ./src/main/resources/application.properties
RUN sh -c '\
  chmod +x mvnw && \
  ./mvnw dependency:go-offline -s /root/.m2/settings.xml && \
  ./mvnw clean package -DskipTests -s /root/.m2/settings.xml'

  FROM registry.cloudaes.com/base-images/eclipse-temurin:21-jre
WORKDIR /app
ARG SIGNOZ_USERNAME
ARG SIGNOZ_PASSWORD
ENV SIGNOZ_USERNAME=${SIGNOZ_USERNAME} \
    SIGNOZ_PASSWORD=${SIGNOZ_PASSWORD} \
    JAVA_TOOL_OPTIONS="-Duser.timezone=Asia/Dhaka"
RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
COPY --from=builder /app/target/*.jar app.jar
COPY ./certs/apm_quickops_io.crt /tmp/apm_quickops_io.crt
COPY ./dockerfiles/opentelemetry-javaagent.jar /opt/opentelemetry-javaagent.jar
COPY ./dockerfiles/entrypoint.sh /app/entrypoint.sh
RUN keytool -importcert -alias apm-quickops-io -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -file /tmp/apm_quickops_io.crt -noprompt && \
    groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m appuser && \
    chown -R appuser:appgroup /app && \
    chmod +x /app/entrypoint.sh
USER appuser
EXPOSE 9009
ENTRYPOINT ["/app/entrypoint.sh"]